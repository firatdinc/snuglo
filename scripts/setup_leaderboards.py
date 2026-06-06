#!/usr/bin/env python3
"""
setup_leaderboards.py — Create Snuglo's Game Center leaderboards via the App
Store Connect API (idempotent: skips boards that already exist).

vendorIdentifier MUST match `LeaderboardID` in
SnugloApp/Core/GameCenter/LeaderboardID.swift. Localized in en / tr / es.

Usage:
    python3 scripts/setup_leaderboards.py            # dry-run: list only
    python3 scripts/setup_leaderboards.py --apply    # create missing boards
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from asc_client import APIError, client_from_env, game_center_detail_id  # noqa: E402

# vendor == LeaderboardID.swift rawValue. formatter/sort per board:
#   fastest.solve = time in ms (lower is better → ASC, time formatter)
#   others        = integers (higher is better → DESC)
LEADERBOARDS = [
    {"vendor": "snuglo.total.levels", "ref": "Total Levels",
     "formatter": "INTEGER", "sort": "DESC",
     "loc": [("en-US", "Total Levels"), ("tr", "Toplam Seviye"), ("es-ES", "Niveles totales")]},
    {"vendor": "snuglo.fastest.solve", "ref": "Fastest Solve",
     "formatter": "ELAPSED_TIME_CENTISECOND", "sort": "ASC",
     "loc": [("en-US", "Fastest Solve"), ("tr", "En Hızlı Çözüm"), ("es-ES", "Resolución más rápida")]},
    {"vendor": "snuglo.best.streak", "ref": "Best Streak",
     "formatter": "INTEGER", "sort": "DESC",
     "loc": [("en-US", "Best Streak"), ("tr", "En İyi Seri"), ("es-ES", "Mejor racha")]},
    {"vendor": "snuglo.endless.best", "ref": "Endless",
     "formatter": "INTEGER", "sort": "DESC",
     "loc": [("en-US", "Endless"), ("tr", "Sonsuz"), ("es-ES", "Infinito")]},
]

SUBMISSION_TYPE = "BEST_SCORE"


def list_existing(client, detail_id: str) -> dict:
    out, path, params = {}, f"/v1/gameCenterDetails/{detail_id}/gameCenterLeaderboards", {"limit": 200}
    while True:
        res = client.request("GET", path, params=params)
        for item in res.get("data", []):
            vid = item.get("attributes", {}).get("vendorIdentifier")
            if vid:
                out[vid] = item["id"]
        nxt = res.get("links", {}).get("next")
        if not nxt:
            break
        path = nxt.replace("https://api.appstoreconnect.apple.com", "")
        params = None
    return out


def create_leaderboard(client, detail_id: str, spec: dict) -> str:
    body = {"data": {
        "type": "gameCenterLeaderboards",
        "attributes": {
            "defaultFormatter": spec["formatter"],
            "referenceName": spec["ref"],
            "vendorIdentifier": spec["vendor"],
            "submissionType": SUBMISSION_TYPE,
            "scoreSortType": spec["sort"],
        },
        "relationships": {
            "gameCenterDetail": {"data": {"type": "gameCenterDetails", "id": detail_id}}
        },
    }}
    return client.request("POST", "/v1/gameCenterLeaderboards", body=body)["data"]["id"]


def existing_locales(client, lb_id: str) -> set:
    try:
        res = client.request("GET", f"/v1/gameCenterLeaderboards/{lb_id}/localizations",
                             params={"limit": 50})
        return {i.get("attributes", {}).get("locale")
                for i in res.get("data", []) if i.get("attributes")}
    except APIError:
        return set()


def ensure_localization(client, lb_id: str, locale: str, name: str) -> str:
    body = {"data": {
        "type": "gameCenterLeaderboardLocalizations",
        "attributes": {"locale": locale, "name": name},
        "relationships": {
            "gameCenterLeaderboard": {"data": {"type": "gameCenterLeaderboards", "id": lb_id}}
        },
    }}
    try:
        client.request("POST", "/v1/gameCenterLeaderboardLocalizations", body=body)
        return "eklendi"
    except APIError as e:
        if e.status == 409 or "exist" in str(e.body).lower():
            return "zaten var"
        raise


def main() -> None:
    apply = "--apply" in sys.argv
    client, app_id = client_from_env()
    print(f"• App: {app_id} | mod: {'APPLY' if apply else 'DRY-RUN'}")

    detail_id = game_center_detail_id(client, app_id)
    existing = list_existing(client, detail_id)
    print(f"• gameCenterDetail {detail_id} | mevcut board: {list(existing.keys())}")

    for spec in LEADERBOARDS:
        vid = spec["vendor"]
        if vid in existing:
            lb_id = existing[vid]
            print(f"  ✓ {vid} zaten var.")
        elif not apply:
            print(f"  + {vid} OLUŞTURULACAK ({spec['formatter']}/{spec['sort']}) [dry-run]")
            continue
        else:
            try:
                lb_id = create_leaderboard(client, detail_id, spec)
                print(f"  + {vid} oluşturuldu.")
            except APIError as e:
                print(f"  ! {vid} OLUŞTURULAMADI: {e.status} {e.body}")
                continue
        if apply:
            have = existing_locales(client, lb_id)
            for locale, name in spec["loc"]:
                if locale in have:
                    continue
                try:
                    print(f"      · {locale} = {name} ({ensure_localization(client, lb_id, locale, name)})")
                except APIError as e:
                    print(f"      ! {locale} EKLENEMEDİ: {e.status} {e.body}")

    print("\nBitti." + ("" if apply else "  (--apply ile oluştur.)"))
    if apply:
        print("Not: Yeni board'lar bir uygulama sürümüyle gönderilene kadar 'Not Live' kalır.")


if __name__ == "__main__":
    try:
        main()
    except APIError as e:
        print(f"\n✗ API hatası: {e}")
        sys.exit(2)
