#!/usr/bin/env python3
"""Upload App Store screenshots (6.9"/6.7" — APP_IPHONE_67, 1290×2796) to the
editable version's en-US localization. Other locales inherit from the primary.

Order = file name order (1..5). Idempotent: skips if the set already has shots.
"""
import hashlib, sys, glob, os
import urllib.request
from asc_client import client_from_env, APIError

DISPLAY_TYPE = "APP_IPHONE_67"
SHOTS_DIR = "/tmp/snuglo-shots-67"
PRIMARY_LOCALE = "en-US"


def raw_put(url, headers, chunk):
    req = urllib.request.Request(url, data=chunk, method="PUT")
    for h in headers:
        req.add_header(h["name"], h["value"])
    with urllib.request.urlopen(req) as r:
        r.read()


def upload_one(c, set_id, path):
    data = open(path, "rb").read()
    md5 = hashlib.md5(data).hexdigest()
    res = c.request("POST", "/v1/appScreenshots", body={"data": {
        "type": "appScreenshots",
        "attributes": {"fileName": os.path.basename(path), "fileSize": len(data)},
        "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}},
    }})
    sid = res["data"]["id"]
    for op in res["data"]["attributes"]["uploadOperations"]:
        off, length = op.get("offset", 0), op.get("length", len(data))
        raw_put(op["url"], op.get("requestHeaders", []), data[off:off + length])
    c.request("PATCH", f"/v1/appScreenshots/{sid}", body={"data": {
        "type": "appScreenshots", "id": sid,
        "attributes": {"uploaded": True, "sourceFileChecksum": md5},
    }})


def main():
    c, app = client_from_env()
    vers = c.request("GET", f"/v1/apps/{app}/appStoreVersions", params={"limit": "10"})
    ver = next((v for v in vers["data"]
                if v["attributes"]["appStoreState"] in
                ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED")), None)
    if not ver:
        sys.exit("✗ Düzenlenebilir sürüm yok.")
    vid = ver["id"]

    locs = c.request("GET", f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations")["data"]
    loc = next((l for l in locs if l["attributes"]["locale"] == PRIMARY_LOCALE), None)
    if not loc:
        sys.exit(f"✗ {PRIMARY_LOCALE} lokalizasyonu yok.")
    lid = loc["id"]
    print(f"Version {vid} | localization {PRIMARY_LOCALE} {lid}")

    # Find or create the 6.9"/6.7" screenshot set.
    sets = c.request("GET", f"/v1/appStoreVersionLocalizations/{lid}/appScreenshotSets")["data"]
    sset = next((s for s in sets if s["attributes"]["screenshotDisplayType"] == DISPLAY_TYPE), None)
    if sset:
        set_id = sset["id"]
        existing = c.request("GET", f"/v1/appScreenshotSets/{set_id}/appScreenshots")["data"]
        if existing:
            print(f"  set zaten {len(existing)} görsele sahip — atlanıyor.")
            return
    else:
        sset = c.request("POST", "/v1/appScreenshotSets", body={"data": {
            "type": "appScreenshotSets",
            "attributes": {"screenshotDisplayType": DISPLAY_TYPE},
            "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": lid}}},
        }})["data"]
        set_id = sset["id"]
        print(f"  + {DISPLAY_TYPE} set oluşturuldu")

    for path in sorted(glob.glob(f"{SHOTS_DIR}/*.png")):
        upload_one(c, set_id, path)
        print(f"  + {os.path.basename(path)} yüklendi")


if __name__ == "__main__":
    try:
        main()
    except APIError as e:
        sys.exit(f"\n✗ API hatası: {e}")
