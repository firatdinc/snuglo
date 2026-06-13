#!/usr/bin/env python3
"""Upload App Review screenshots to ASC In-App Purchases (reserve → PUT → commit).

Idempotent: skips an IAP that already has a review screenshot. One screenshot can
be reused across multiple IAPs (it just shows where the product appears in-app).

Maps the screenshots provided by the user:
  • shop_hints_ads.png → com.snuglo.hints.small, com.snuglo.removeads
  • premium.png        → com.snuglo.premium
(Gem packs tier1–5 still need a "Coin Packs" screenshot.)
"""
import hashlib
import sys
import urllib.request
import urllib.error
from pathlib import Path

from asc_client import client_from_env, APIError
from setup_iap import list_existing

HERE = Path(__file__).resolve().parent

MAPPING = [
    ("iap_screenshots/shop_hints_ads.jpg", ["com.snuglo.hints.small", "com.snuglo.removeads"]),
    ("iap_screenshots/premium.jpg",        ["com.snuglo.premium"]),
    ("iap_screenshots/gem_packs.jpg",      ["com.snuglo.gems.tier1", "com.snuglo.gems.tier2",
                                            "com.snuglo.gems.tier3", "com.snuglo.gems.tier4",
                                            "com.snuglo.gems.tier5"]),
    ("iap_screenshots/shop_keys.jpg",      ["com.snuglo.keys.small"]),
]


def existing_screenshot(client, iap_id):
    """Returns (id, state) of the current review screenshot, or (None, None)."""
    try:
        res = client.request("GET", f"/v2/inAppPurchases/{iap_id}/appStoreReviewScreenshot")
        d = res.get("data")
        if not d:
            return None, None
        state = (d.get("attributes", {}).get("assetDeliveryState") or {}).get("state")
        return d["id"], state
    except APIError:
        return None, None


def delete_screenshot(client, sid):
    try:
        client.request("DELETE", f"/v1/inAppPurchaseAppStoreReviewScreenshots/{sid}")
    except APIError:
        pass


def raw_put(url: str, headers: list, chunk: bytes) -> None:
    req = urllib.request.Request(url, data=chunk, method="PUT")
    for h in headers:
        req.add_header(h["name"], h["value"])
    with urllib.request.urlopen(req) as resp:
        resp.read()


def upload(client, iap_id: str, path: Path) -> None:
    data = path.read_bytes()
    size = len(data)
    md5 = hashlib.md5(data).hexdigest()

    # 1. Reserve
    body = {"data": {
        "type": "inAppPurchaseAppStoreReviewScreenshots",
        "attributes": {"fileName": path.name, "fileSize": size},
        "relationships": {"inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": iap_id}}},
    }}
    res = client.request("POST", "/v1/inAppPurchaseAppStoreReviewScreenshots", body=body)
    sid = res["data"]["id"]
    ops = res["data"]["attributes"]["uploadOperations"]

    # 2. Upload chunks
    for op in ops:
        offset = op.get("offset", 0)
        length = op.get("length", size)
        raw_put(op["url"], op.get("requestHeaders", []), data[offset:offset + length])

    # 3. Commit
    commit = {"data": {
        "type": "inAppPurchaseAppStoreReviewScreenshots",
        "id": sid,
        "attributes": {"uploaded": True, "sourceFileChecksum": md5},
    }}
    client.request("PATCH", f"/v1/inAppPurchaseAppStoreReviewScreenshots/{sid}", body=commit)


def main():
    client, app_id = client_from_env()
    existing = list_existing(client, app_id)
    print(f"• App {app_id} | {len(existing)} IAP bulundu\n")

    for rel_path, pids in MAPPING:
        img = HERE / rel_path
        if not img.exists():
            print(f"✗ görsel yok: {img}")
            continue
        for pid in pids:
            iap_id = existing.get(pid)
            if not iap_id:
                print(f"  ⚠️  {pid} ASC'de yok, atlandı")
                continue
            sid, state = existing_screenshot(client, iap_id)
            if state == "COMPLETE":
                print(f"  ✓ {pid} zaten geçerli screenshot'a sahip")
                continue
            if sid:
                delete_screenshot(client, sid)   # replace FAILED/incomplete
            try:
                upload(client, iap_id, img)
                print(f"  + {pid} ← {img.name} yüklendi")
            except APIError as e:
                print(f"  ✗ {pid} yükleme hatası: {e}")


if __name__ == "__main__":
    try:
        main()
    except APIError as e:
        sys.exit(f"\n✗ API hatası: {e}")
