#!/usr/bin/env python3
"""
setup_iap.py — Create Snuglo's in-app purchases in App Store Connect via the ASC
API (idempotent): 1 premium non-consumable + 5 consumable gem packs. Adds en/tr/es
localizations and a USD price schedule (USA base territory).

Product IDs MUST match the app:
  StoreManager.ProductID.premium  → com.snuglo.premium
  GemPack.catalog                 → com.snuglo.gems.tier1..5

Usage:
    python3 scripts/setup_iap.py            # dry-run
    python3 scripts/setup_iap.py --apply    # create in ASC
"""

import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from asc_client import APIError, client_from_env  # noqa: E402

# type: CONSUMABLE | NON_CONSUMABLE ; usd: target customer price (USA)
PRODUCTS = [
    {"pid": "com.snuglo.premium", "type": "NON_CONSUMABLE", "usd": 4.99,
     "ref": "Snuglo Premium",
     "loc": {
         "en-US": ("Snuglo Premium", "Unlimited energy, no ads, exclusive cosmetics."),
         "tr":    ("Snuglo Premium", "Sınırsız enerji, reklamsız, özel kozmetikler."),
         "es-ES": ("Snuglo Premium", "Energía ilimitada, sin anuncios, cosméticos exclusivos."),
     }},
    {"pid": "com.snuglo.gems.tier1", "type": "CONSUMABLE", "usd": 0.99,  "ref": "100 Gems",
     "loc": {"en-US": ("100 Gems", "A handful of gems."), "tr": ("100 Elmas", "Bir avuç elmas."),
             "es-ES": ("100 Gemas", "Un puñado de gemas.")}},
    {"pid": "com.snuglo.gems.tier2", "type": "CONSUMABLE", "usd": 4.99,  "ref": "550 Gems",
     "loc": {"en-US": ("550 Gems", "A pouch of gems."), "tr": ("550 Elmas", "Bir kese elmas."),
             "es-ES": ("550 Gemas", "Una bolsa de gemas.")}},
    {"pid": "com.snuglo.gems.tier3", "type": "CONSUMABLE", "usd": 9.99,  "ref": "1200 Gems",
     "loc": {"en-US": ("1200 Gems", "A chest of gems."), "tr": ("1200 Elmas", "Bir sandık elmas."),
             "es-ES": ("1200 Gemas", "Un cofre de gemas.")}},
    {"pid": "com.snuglo.gems.tier4", "type": "CONSUMABLE", "usd": 19.99, "ref": "2600 Gems",
     "loc": {"en-US": ("2600 Gems", "Best value gem bundle."), "tr": ("2600 Elmas", "En avantajlı paket."),
             "es-ES": ("2600 Gemas", "El mejor valor.")}},
    {"pid": "com.snuglo.gems.tier5", "type": "CONSUMABLE", "usd": 49.99, "ref": "7000 Gems",
     "loc": {"en-US": ("7000 Gems", "A vault of gems."), "tr": ("7000 Elmas", "Bir hazine elmas."),
             "es-ES": ("7000 Gemas", "Una bóveda de gemas.")}},
    {"pid": "com.snuglo.removeads", "type": "NON_CONSUMABLE", "usd": 2.99, "ref": "Remove Ads",
     "loc": {"en-US": ("Remove Ads", "Play with no interstitial ads, forever."),
             "tr": ("Reklamları Kaldır", "Sonsuza dek tam ekran reklamsız oyna."),
             "es-ES": ("Quitar Anuncios", "Juega sin anuncios para siempre.")}},
    {"pid": "com.snuglo.hints.small", "type": "CONSUMABLE", "usd": 0.99, "ref": "10 Hints",
     "loc": {"en-US": ("10 Hints", "A pack of 10 hints to help you solve."),
             "tr": ("10 İpucu", "Çözmene yardımcı 10 ipucu paketi."),
             "es-ES": ("10 Pistas", "Un paquete de 10 pistas para ayudarte.")}},
    {"pid": "com.snuglo.keys.small", "type": "CONSUMABLE", "usd": 0.99, "ref": "3 Keys",
     "loc": {"en-US": ("3 Keys", "Three keys to open treasure chests."),
             "tr": ("3 Anahtar", "Sandıkları açmak için üç anahtar."),
             "es-ES": ("3 Llaves", "Tres llaves para abrir cofres.")}},
]

BASE_TERRITORY = "USA"


def list_existing(client, app_id):
    out, cursor = {}, None
    while True:
        params = {"limit": "200"}
        if cursor:
            params["cursor"] = cursor
        page = client.request("GET", f"/v1/apps/{app_id}/inAppPurchasesV2", params=params)
        for it in page.get("data", []):
            pid = it.get("attributes", {}).get("productId")
            if pid:
                out[pid] = it["id"]
        nxt = page.get("links", {}).get("next") or ""
        if "cursor=" in nxt:
            cursor = nxt.split("cursor=", 1)[1].split("&", 1)[0]
        else:
            break
    return out


def create_iap(client, app_id, spec):
    body = {"data": {
        "type": "inAppPurchases",
        "attributes": {
            "name": spec["ref"],
            "productId": spec["pid"],
            "inAppPurchaseType": spec["type"],
            "reviewNote": "Created by automation.",
        },
        "relationships": {"app": {"data": {"id": app_id, "type": "apps"}}},
    }}
    return client.request("POST", "/v2/inAppPurchases", body=body)["data"]["id"]


def existing_locales(client, iap_id):
    try:
        res = client.request("GET", f"/v2/inAppPurchases/{iap_id}/inAppPurchaseLocalizations",
                             params={"limit": "50"})
        return {i["attributes"]["locale"] for i in res.get("data", []) if i.get("attributes")}
    except APIError:
        return set()


def add_localization(client, iap_id, locale, name, desc):
    body = {"data": {
        "type": "inAppPurchaseLocalizations",
        "attributes": {"locale": locale, "name": name[:30], "description": desc[:45]},
        "relationships": {"inAppPurchaseV2": {"data": {"id": iap_id, "type": "inAppPurchases"}}},
    }}
    try:
        client.request("POST", "/v2/inAppPurchaseLocalizations", body=body)
        return "eklendi"
    except APIError as e:
        if e.status in (409,) or "exist" in str(e.body).lower():
            return "zaten var"
        raise


def has_price(client, iap_id):
    try:
        res = client.request("GET", f"/v2/inAppPurchases/{iap_id}/iapPriceSchedule")
        return bool(res.get("data"))
    except APIError:
        return False


def find_price_point(client, iap_id, usd):
    cursor = None
    for _ in range(8):
        params = {"filter[territory]": BASE_TERRITORY, "limit": "200"}
        if cursor:
            params["cursor"] = cursor
        s = client.request("GET", f"/v2/inAppPurchases/{iap_id}/pricePoints", params=params)
        for it in s.get("data", []):
            cp = it.get("attributes", {}).get("customerPrice")
            try:
                if cp is not None and abs(float(cp) - usd) < 0.005:
                    return it["id"]
            except ValueError:
                pass
        nxt = s.get("links", {}).get("next") or ""
        if "cursor=" in nxt:
            cursor = nxt.split("cursor=", 1)[1].split("&", 1)[0]
        else:
            break
    return None


def set_price(client, iap_id, usd):
    point_id = find_price_point(client, iap_id, usd)
    if not point_id:
        return f"price point ${usd} yok"
    body = {
        "data": {
            "type": "inAppPurchasePriceSchedules",
            "relationships": {
                "inAppPurchase": {"data": {"id": iap_id, "type": "inAppPurchases"}},
                "baseTerritory": {"data": {"id": BASE_TERRITORY, "type": "territories"}},
                "manualPrices": {"data": [{"id": "${p1}", "type": "inAppPurchasePrices"}]},
            },
        },
        "included": [{
            "id": "${p1}", "type": "inAppPurchasePrices",
            "attributes": {"startDate": None},
            "relationships": {
                "inAppPurchaseV2": {"data": {"id": iap_id, "type": "inAppPurchases"}},
                "inAppPurchasePricePoint": {"data": {"id": point_id, "type": "inAppPurchasePricePoints"}},
            },
        }],
    }
    try:
        client.request("POST", "/v1/inAppPurchasePriceSchedules", body=body)
        return f"${usd} ayarlandı"
    except APIError as e:
        if e.status == 409:
            return f"${usd} zaten var"
        return f"fiyat HATA {e.status}"


def main():
    apply = "--apply" in sys.argv
    client, app_id = client_from_env()
    print(f"• App {app_id} | {len(PRODUCTS)} IAP | mod: {'APPLY' if apply else 'DRY-RUN'}")
    existing = list_existing(client, app_id)
    print(f"• Mevcut IAP: {list(existing.keys())}")

    for spec in PRODUCTS:
        pid = spec["pid"]
        if pid in existing:
            iap_id = existing[pid]
            print(f"  ✓ {pid} ({spec['type']}) zaten var")
        elif not apply:
            print(f"  + {pid} ({spec['type']}, ${spec['usd']}) OLUŞTURULACAK [dry-run]")
            continue
        else:
            iap_id = create_iap(client, app_id, spec)
            print(f"  + {pid} oluşturuldu")
        if not apply:
            continue
        have = existing_locales(client, iap_id)
        for locale, (name, desc) in spec["loc"].items():
            if locale in have:
                continue
            try:
                st = add_localization(client, iap_id, locale, name, desc)
                print(f"      · {locale} ({st})")
            except APIError as e:
                print(f"      ! {locale} HATA {e.status}: {e.body}")
        if has_price(client, iap_id):
            print(f"      $ fiyat zaten var")
        else:
            print(f"      $ {set_price(client, iap_id, spec['usd'])}")
        time.sleep(0.2)

    print("\nBitti." + ("" if apply else "  (--apply ile oluştur.)"))
    if apply:
        print("Not: İLK consumable'lar bir app sürümüyle BİRLİKTE submit edilmeli "
              "(ASC arayüzü → versiyon → In-App Purchases → Add for Review). API'den bundle YAPILAMAZ.")


if __name__ == "__main__":
    try:
        main()
    except APIError as e:
        print(f"\n✗ API hatası: {e}")
        sys.exit(2)
