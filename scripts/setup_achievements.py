#!/usr/bin/env python3
"""
setup_achievements.py — Mirror Snuglo's 16 achievements to Game Center via the
App Store Connect API (idempotent).

vendorIdentifier == Achievement.swift rawValue. Names/descriptions are read
live from SnugloApp/Resources/<locale>.lproj/Localizable.strings
(keys: achievement.<id>.title / achievement.<id>.description) in en / tr / es.
Points are kept within Apple's 1000-point total cap.

Usage:
    python3 scripts/setup_achievements.py            # dry-run
    python3 scripts/setup_achievements.py --apply    # create in ASC
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from asc_client import APIError, client_from_env, game_center_detail_id, load_strings  # noqa: E402

LOCALES = [("en-US", "en"), ("tr", "tr"), ("es-ES", "es")]

# id → Game Center points (sum must stay ≤ 1000). Harder achievement → more pts.
POINTS = {
    # Original 16 (already created in ASC — keep their points unchanged).
    "firstSteps": 5, "levelHunter10": 10, "levelMaster50": 25, "levelLegend100": 50,
    "packFinisher": 20, "perfectionist1": 5, "perfectionistPro10": 15,
    "perfectionistMaster25": 35, "streak3": 10, "streak7": 20, "streak30": 50,
    "dedicated7": 20, "comboChampion": 25, "noHints10": 20, "speedSolver": 15,
    "speedDemon": 30,
    # Expansion (19 new) — total stays ≤ 1000 (900).
    "levelHunter25": 15, "levelVoyager250": 35, "levelSage500": 45, "completionist1000": 60,
    "packCollector3": 20, "packMaster10": 35,
    "perfectionistGrand50": 30, "perfectionistLegend100": 40,
    "chainMaster10": 20, "chainLegend20": 30,
    "noHints25": 15, "noHints50": 25,
    "speedLightning": 20, "speedBlitz": 30,
    "streak14": 15, "streak60": 30, "streak100": 40,
    "dedicated14": 15, "dedicated30": 25,
}


def build_specs() -> list[dict]:
    strings = {lang: load_strings(lang) for _, lang in LOCALES}
    specs = []
    for aid, pts in POINTS.items():
        name, desc = {}, {}
        for _, lang in LOCALES:
            s = strings[lang]
            name[lang] = s.get(f"achievement.{aid}.title", aid)
            desc[lang] = s.get(f"achievement.{aid}.description", name[lang])
        specs.append({"id": aid, "points": pts, "name": name, "desc": desc})
    return specs


def list_existing(client, detail_id: str) -> dict:
    out, path, params = {}, f"/v1/gameCenterDetails/{detail_id}/gameCenterAchievements", {"limit": 200}
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


def create_achievement(client, detail_id: str, spec: dict) -> str:
    body = {"data": {
        "type": "gameCenterAchievements",
        "attributes": {
            "referenceName": (spec["name"]["en"] or spec["id"])[:64],
            "vendorIdentifier": spec["id"],
            "points": spec["points"],
            "showBeforeEarned": True,
            "repeatable": False,
        },
        "relationships": {
            "gameCenterDetail": {"data": {"type": "gameCenterDetails", "id": detail_id}}
        },
    }}
    return client.request("POST", "/v1/gameCenterAchievements", body=body)["data"]["id"]


def existing_locales(client, ach_id: str) -> set:
    try:
        res = client.request("GET", f"/v1/gameCenterAchievements/{ach_id}/localizations",
                             params={"limit": 50})
        return {i.get("attributes", {}).get("locale") for i in res.get("data", []) if i.get("attributes")}
    except APIError:
        return set()


def create_localization(client, ach_id: str, locale: str, name: str, desc: str) -> None:
    body = {"data": {
        "type": "gameCenterAchievementLocalizations",
        "attributes": {
            "locale": locale,
            "name": name[:30],
            "beforeEarnedDescription": desc[:200],
            "afterEarnedDescription": desc[:200],
        },
        "relationships": {
            "gameCenterAchievement": {"data": {"type": "gameCenterAchievements", "id": ach_id}}
        },
    }}
    client.request("POST", "/v1/gameCenterAchievementLocalizations", body=body)


def main() -> None:
    apply = "--apply" in sys.argv
    specs = build_specs()
    total = sum(s["points"] for s in specs)
    print(f"• {len(specs)} başarım | toplam puan {total} (≤1000) | mod: {'APPLY' if apply else 'DRY-RUN'}")
    if total > 1000:
        print("✗ Toplam puan 1000'i aşıyor."); sys.exit(1)

    client, app_id = client_from_env()
    detail_id = game_center_detail_id(client, app_id)
    existing = list_existing(client, detail_id)
    print(f"• gameCenterDetail {detail_id} | mevcut başarım: {len(existing)}")

    created = loc_added = 0
    for spec in specs:
        vid = spec["id"]
        if vid in existing:
            ach_id, tag = existing[vid], "var"
        elif not apply:
            print(f"  + {vid} ({spec['points']}p) OLUŞTURULACAK [dry-run]  «{spec['name']['en']}»")
            continue
        else:
            ach_id, tag = create_achievement(client, detail_id, spec), "YENİ"
            created += 1
        if not apply:
            continue
        have = existing_locales(client, ach_id)
        for locale, lang in LOCALES:
            if locale in have:
                continue
            try:
                create_localization(client, ach_id, locale, spec["name"][lang], spec["desc"][lang])
                loc_added += 1
            except APIError as e:
                if e.status == 409 or "exist" in str(e.body).lower():
                    pass
                else:
                    print(f"      ! {vid} {locale}: {e.status} {e.body}")
        print(f"  ✓ {vid} ({tag}) [{spec['points']}p]")

    print(f"\nBitti. oluşturulan={created} localization={loc_added}"
          + ("" if apply else "  (--apply ile yaz)"))
    if apply:
        print("Not: Başarımlar bir uygulama sürümüyle gönderilene kadar 'Not Live'. Canlıya çıkınca SİLİNEMEZ.")


if __name__ == "__main__":
    try:
        main()
    except APIError as e:
        print(f"\n✗ API hatası: {e}")
        sys.exit(2)
