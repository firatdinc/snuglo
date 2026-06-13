#!/usr/bin/env python3
"""Add In-App Purchase localizations (display name ≤30, description ≤45) for all
9 IAPs in en-US / tr / es-ES. Missing localizations are why the IAPs sit in
MISSING_METADATA. Idempotent (create or patch)."""
import sys
from asc_client import client_from_env, APIError

LOCALES = ["en-US", "tr", "es-ES"]

# productId -> {locale: (name<=30, description<=45)}
IAP = {
 "com.snuglo.premium": {
   "en-US": ("Snuglo Premium", "Unlimited energy, no ads, all unlocked"),
   "tr":    ("Snuglo Premium", "Sınırsız enerji, reklamsız, hepsi açık"),
   "es-ES": ("Snuglo Premium", "Energía ilimitada, sin anuncios, todo"),
 },
 "com.snuglo.removeads": {
   "en-US": ("Remove Ads", "Play with no ads, forever"),
   "tr":    ("Reklamları Kaldır", "Sonsuza dek reklamsız oyna"),
   "es-ES": ("Quitar Anuncios", "Juega sin anuncios para siempre"),
 },
 "com.snuglo.hints.small": {
   "en-US": ("10 Hints", "A pack of 10 hints"),
   "tr":    ("10 İpucu", "10 ipuçluk paket"),
   "es-ES": ("10 Pistas", "Un paquete de 10 pistas"),
 },
 "com.snuglo.keys.small": {
   "en-US": ("3 Keys", "Three keys to open chests"),
   "tr":    ("3 Anahtar", "Sandık açmak için üç anahtar"),
   "es-ES": ("3 Llaves", "Tres llaves para abrir cofres"),
 },
 "com.snuglo.gems.tier1": {
   "en-US": ("100 Gems", "A handful of gems"),
   "tr":    ("100 Elmas", "Bir avuç elmas"),
   "es-ES": ("100 Gemas", "Un puñado de gemas"),
 },
 "com.snuglo.gems.tier2": {
   "en-US": ("550 Gems", "A pouch of gems"),
   "tr":    ("550 Elmas", "Bir kese elmas"),
   "es-ES": ("550 Gemas", "Una bolsa de gemas"),
 },
 "com.snuglo.gems.tier3": {
   "en-US": ("1200 Gems", "A chest of gems"),
   "tr":    ("1200 Elmas", "Bir sandık elmas"),
   "es-ES": ("1200 Gemas", "Un cofre de gemas"),
 },
 "com.snuglo.gems.tier4": {
   "en-US": ("2600 Gems", "Best value gem bundle"),
   "tr":    ("2600 Elmas", "En avantajlı elmas paketi"),
   "es-ES": ("2600 Gemas", "El mejor valor en gemas"),
 },
 "com.snuglo.gems.tier5": {
   "en-US": ("7000 Gems", "A vault of gems"),
   "tr":    ("7000 Elmas", "Bir hazine dolusu elmas"),
   "es-ES": ("7000 Gemas", "Una bóveda de gemas"),
 },
}


def main():
    c, app = client_from_env()
    ex = {it["attributes"]["productId"]: it["id"]
          for it in c.request("GET", f"/v1/apps/{app}/inAppPurchasesV2", params={"limit": "50"})["data"]}

    for pid, locs in IAP.items():
        iid = ex.get(pid)
        if not iid:
            print(f"⚠ {pid} yok"); continue
        existing = {l["attributes"]["locale"]: l["id"]
                    for l in c.request("GET", f"/v2/inAppPurchases/{iid}/inAppPurchaseLocalizations")["data"]}
        for loc in LOCALES:
            name, desc = locs[loc]
            attrs = {"name": name[:30], "description": desc[:45]}
            try:
                if loc in existing:
                    c.request("PATCH", f"/v1/inAppPurchaseLocalizations/{existing[loc]}",
                              body={"data": {"type": "inAppPurchaseLocalizations", "id": existing[loc], "attributes": attrs}})
                else:
                    attrs["locale"] = loc
                    c.request("POST", "/v1/inAppPurchaseLocalizations",
                              body={"data": {"type": "inAppPurchaseLocalizations", "attributes": attrs,
                                             "relationships": {"inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": iid}}}}})
                print(f"  ✓ {pid} [{loc}]")
            except APIError as e:
                print(f"  ⚠ {pid} [{loc}]: {str(e.body)[:90]}")

    print("\n=== yeni state'ler ===")
    for it in c.request("GET", f"/v1/apps/{app}/inAppPurchasesV2", params={"limit": "50"})["data"]:
        print(f"  {it['attributes']['productId']} | {it['attributes']['state']}")


if __name__ == "__main__":
    try:
        main()
    except APIError as e:
        sys.exit(f"\n✗ {e}")
