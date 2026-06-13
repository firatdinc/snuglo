#!/usr/bin/env python3
"""
setup_revenuecat.py — Bootstrap the RevenueCat dashboard for Snuglo (idempotent).

Creates / verifies:
  • 6 products (premium non-consumable + 5 consumable gem packs)
  • `premium` entitlement (attached to the premium product)
  • `default` offering with one package per product

Setup (one-time, manual in the dashboard):
  1. https://app.revenuecat.com → new Project "Snuglo"
  2. Add an iOS app, bundle ID com.snuglo.app
  3. Project Settings → API keys → copy the Secret API key (sk_...)
  4. Project ID is in the URL: /projects/<PROJECT_ID>
  5. Put both in secrets/.env.local:
       REVENUECAT_PROJECT_ID=...
       REVENUECAT_SECRET_KEY=sk_...

Product IDs must match the app (StoreManager / GemPack) AND the ASC IAPs created
by setup_iap.py.

Usage:
    python3 scripts/setup_revenuecat.py
"""

import json
import os
import sys
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

API_BASE = "https://api.revenuecat.com/v2"
PREMIUM_PRODUCT_ID = "com.snuglo.premium"
ENTITLEMENT_LOOKUP_KEY = "premium"
ENTITLEMENT_DISPLAY_NAME = "Premium"
REMOVE_ADS_PRODUCT_ID = "com.snuglo.removeads"
ADS_ENTITLEMENT_LOOKUP_KEY = "ads_removed"
ADS_ENTITLEMENT_DISPLAY_NAME = "Ads Removed"
OFFERING_LOOKUP_KEY = "default"
OFFERING_DISPLAY_NAME = "Snuglo Store"


@dataclass
class ProductSpec:
    identifier: str
    type: str            # "consumable" | "non_consumable"
    display_name: str


PRODUCTS = [
    ProductSpec(PREMIUM_PRODUCT_ID,       "non_consumable", "Snuglo Premium"),
    ProductSpec("com.snuglo.gems.tier1",  "consumable",     "100 Gems"),
    ProductSpec("com.snuglo.gems.tier2",  "consumable",     "550 Gems"),
    ProductSpec("com.snuglo.gems.tier3",  "consumable",     "1200 Gems"),
    ProductSpec("com.snuglo.gems.tier4",  "consumable",     "2600 Gems"),
    ProductSpec("com.snuglo.gems.tier5",  "consumable",     "7000 Gems"),
    ProductSpec(REMOVE_ADS_PRODUCT_ID,    "non_consumable", "Remove Ads"),
    ProductSpec("com.snuglo.hints.small", "consumable",     "10 Hints"),
    ProductSpec("com.snuglo.keys.small",  "consumable",     "3 Keys"),
]


# ── .env loader (stdlib only) ───────────────────────────────────────────

def _load_env() -> None:
    p = Path(__file__).resolve().parent.parent / "secrets" / ".env.local"
    if not p.exists():
        return
    for raw in p.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))


_load_env()


# ── Client ───────────────────────────────────────────────────────────────

class APIError(RuntimeError):
    def __init__(self, method, url, status, body):
        super().__init__(f"{method} {url} → HTTP {status}: {body}")
        self.status = status
        self.body = body

    def is_conflict(self) -> bool:
        if self.status in (409, 422):
            code = str(self.body.get("code", "")).lower()
            return any(w in code for w in ("exists", "duplicate", "conflict"))
        return False


class RCClient:
    def __init__(self, api_key: str):
        self.api_key = api_key

    def request(self, method, path, body=None):
        url = API_BASE + path
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(url, data=data, method=method)
        req.add_header("Authorization", f"Bearer {self.api_key}")
        req.add_header("Content-Type", "application/json")
        req.add_header("Accept", "application/json")
        try:
            with urllib.request.urlopen(req) as resp:
                raw = resp.read()
                return json.loads(raw) if raw else {}
        except urllib.error.HTTPError as e:
            body_txt = e.read().decode(errors="replace")
            try:
                err = json.loads(body_txt)
            except Exception:
                err = {"raw": body_txt}
            raise APIError(method, url, e.code, err) from None


# ── Steps ──────────────────────────────────────────────────────────────

def discover_app_id(client, project_id):
    page = client.request("GET", f"/projects/{project_id}/apps")
    items = page.get("items") or page.get("data") or []
    ios = [a for a in items if a.get("type") == "app_store"]
    if not ios:
        sys.exit("✗ Projede iOS (app_store) app yok. Dashboard'da önce ekle.")
    return ios[0]["id"]


def list_existing(client, project_id, resource):
    page = client.request("GET", f"/projects/{project_id}/{resource}")
    items = page.get("items") or page.get("data") or []
    out = {}
    for it in items:
        key = it.get("lookup_key") or it.get("store_identifier") or it.get("id")
        if key:
            out[key] = it
    return out


def ensure_product(client, project_id, app_id, spec, existing):
    if spec.identifier in existing:
        return existing[spec.identifier]
    body = {"store_identifier": spec.identifier, "app_id": app_id,
            "type": spec.type, "display_name": spec.display_name}
    try:
        return client.request("POST", f"/projects/{project_id}/products", body=body)
    except APIError as e:
        if e.is_conflict():
            return existing.get(spec.identifier, {})
        raise


def ensure_entitlement(client, project_id, existing, lookup_key, display_name):
    if lookup_key in existing:
        return existing[lookup_key]
    body = {"lookup_key": lookup_key, "display_name": display_name}
    try:
        return client.request("POST", f"/projects/{project_id}/entitlements", body=body)
    except APIError as e:
        if e.is_conflict():
            return existing.get(lookup_key, {})
        raise


def attach_product_to_entitlement(client, project_id, ent_id, product_id):
    try:
        client.request("POST",
                       f"/projects/{project_id}/entitlements/{ent_id}/actions/attach_products",
                       body={"product_ids": [product_id]})
    except APIError as e:
        if not e.is_conflict():
            raise


def ensure_offering(client, project_id, existing):
    if OFFERING_LOOKUP_KEY in existing:
        return existing[OFFERING_LOOKUP_KEY]
    body = {"lookup_key": OFFERING_LOOKUP_KEY, "display_name": OFFERING_DISPLAY_NAME}
    try:
        return client.request("POST", f"/projects/{project_id}/offerings", body=body)
    except APIError as e:
        if e.is_conflict():
            return existing.get(OFFERING_LOOKUP_KEY, {})
        raise


def ensure_package(client, project_id, offering_id, key, name, position, existing_keys):
    if key in existing_keys:
        return None
    body = {"lookup_key": key, "display_name": name, "position": position}
    try:
        return client.request("POST",
                              f"/projects/{project_id}/offerings/{offering_id}/packages",
                              body=body)
    except APIError as e:
        if e.is_conflict():
            return None
        raise


def attach_product_to_package(client, project_id, package_id, product_id):
    try:
        client.request("POST",
                       f"/projects/{project_id}/packages/{package_id}/actions/attach_products",
                       body={"products": [{"product_id": product_id, "eligibility_criteria": "all"}]})
    except APIError as e:
        if not e.is_conflict():
            raise


def main():
    project_id = os.environ.get("REVENUECAT_PROJECT_ID")
    api_key = os.environ.get("REVENUECAT_SECRET_KEY")
    if not project_id or not api_key:
        sys.exit("✗ REVENUECAT_PROJECT_ID ve REVENUECAT_SECRET_KEY gerekli (secrets/.env.local).")

    client = RCClient(api_key)
    print(f"→ Project: {project_id}")
    app_id = discover_app_id(client, project_id)
    print(f"  iOS app: {app_id}\n")

    print("── Products ──")
    existing_products = {k: v for k, v in list_existing(client, project_id, "products").items()
                         if v.get("app_id") == app_id}
    for spec in PRODUCTS:
        before = spec.identifier in existing_products
        res = ensure_product(client, project_id, app_id, spec, existing_products)
        if not before:
            existing_products[spec.identifier] = res
        print(f"  [{'✓' if before else '+'}] {spec.identifier} ({spec.type})")

    print("\n── Entitlements ──")
    existing_ents = list_existing(client, project_id, "entitlements")
    # Premium entitlement
    ent = ensure_entitlement(client, project_id, existing_ents, ENTITLEMENT_LOOKUP_KEY, ENTITLEMENT_DISPLAY_NAME)
    ent_id = ent.get("id")
    print(f"  [{'✓' if ENTITLEMENT_LOOKUP_KEY in existing_ents else '+'}] {ENTITLEMENT_LOOKUP_KEY} (id={ent_id})")
    premium_id = existing_products.get(PREMIUM_PRODUCT_ID, {}).get("id")
    if premium_id and ent_id:
        attach_product_to_entitlement(client, project_id, ent_id, premium_id)
        print(f"  ↳ attached {PREMIUM_PRODUCT_ID}")
    # Ads-removed entitlement (Remove Ads non-consumable)
    ads_ent = ensure_entitlement(client, project_id, existing_ents, ADS_ENTITLEMENT_LOOKUP_KEY, ADS_ENTITLEMENT_DISPLAY_NAME)
    ads_ent_id = ads_ent.get("id")
    print(f"  [{'✓' if ADS_ENTITLEMENT_LOOKUP_KEY in existing_ents else '+'}] {ADS_ENTITLEMENT_LOOKUP_KEY} (id={ads_ent_id})")
    remove_ads_id = existing_products.get(REMOVE_ADS_PRODUCT_ID, {}).get("id")
    if remove_ads_id and ads_ent_id:
        attach_product_to_entitlement(client, project_id, ads_ent_id, remove_ads_id)
        print(f"  ↳ attached {REMOVE_ADS_PRODUCT_ID}")

    print("\n── Offering ──")
    existing_offerings = list_existing(client, project_id, "offerings")
    offering = ensure_offering(client, project_id, existing_offerings)
    offering_id = offering.get("id")
    print(f"  [{'✓' if OFFERING_LOOKUP_KEY in existing_offerings else '+'}] {OFFERING_LOOKUP_KEY} (id={offering_id})")
    if offering_id:
        pkgs = client.request("GET", f"/projects/{project_id}/offerings/{offering_id}/packages")
        items = pkgs.get("items") or pkgs.get("data") or []
        existing_keys = {p.get("lookup_key") for p in items if p.get("lookup_key")}
        for pos, spec in enumerate(PRODUCTS):
            pkg = ensure_package(client, project_id, offering_id, spec.identifier,
                                 spec.display_name, pos, existing_keys)
            print(f"    [{'✓' if spec.identifier in existing_keys else '+'}] {spec.identifier}")
            if pkg:
                pid = existing_products.get(spec.identifier, {}).get("id")
                if pkg.get("id") and pid:
                    attach_product_to_package(client, project_id, pkg["id"], pid)

    print("\n✓ Bitti. Dashboard'da doğrula: https://app.revenuecat.com")


if __name__ == "__main__":
    try:
        main()
    except APIError as e:
        sys.exit(f"\n✗ API hatası: {e}")
