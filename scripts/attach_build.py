#!/usr/bin/env python3
"""Attach the processed build to the editable App Store version, and report
IAP / Game Center readiness. Run after the binary finishes processing.

Usage: python3 attach_build.py [VERSION]   (default 1.2.0)
"""
import sys
from asc_client import client_from_env, APIError

VERSION = sys.argv[1] if len(sys.argv) > 1 else "1.2.0"


def main():
    c, app = client_from_env()
    vers = c.request("GET", f"/v1/apps/{app}/appStoreVersions", params={"limit": "10"})
    ver = next((v for v in vers["data"] if v["attributes"]["versionString"] == VERSION), None)
    if not ver:
        sys.exit(f"✗ {VERSION} sürümü yok.")
    vid = ver["id"]
    print(f"Version {VERSION} | {ver['attributes']['appStoreState']}")

    # Newest build for this version string that has finished processing.
    builds = c.request("GET", "/v1/builds", params={
        "filter[app]": app, "filter[preReleaseVersion.version]": VERSION,
        "sort": "-version", "limit": "20",
    })["data"]
    ready = [b for b in builds if b["attributes"].get("processingState") == "VALID"]
    if not builds:
        print("• Henüz yüklenen build yok / görünmüyor.")
    elif not ready:
        states = {b['attributes']['version']: b['attributes'].get('processingState') for b in builds}
        print(f"• Build hâlâ işleniyor: {states} — birkaç dk sonra tekrar çalıştır.")
    else:
        b = ready[0]
        bid, bnum = b["id"], b["attributes"]["version"]
        c.request("PATCH", f"/v1/appStoreVersions/{vid}/relationships/build",
                  body={"data": {"type": "builds", "id": bid}})
        print(f"✓ Build {bnum} → {VERSION} sürümüne bağlandı.")

    # IAP readiness
    iaps = c.request("GET", f"/v1/apps/{app}/inAppPurchasesV2", params={"limit": "50"})["data"]
    print(f"• IAP: {len(iaps)} ürün —", ", ".join(
        f"{i['attributes']['productId']}({i['attributes']['state']})" for i in iaps) or "YOK")

    # Game Center
    try:
        gc = c.request("GET", f"/v1/apps/{app}/gameCenterDetail")["data"]
        print(f"• Game Center detail: {'var' if gc else 'YOK'}")
    except APIError as e:
        print(f"• Game Center: {e}")


if __name__ == "__main__":
    main()
