# Snuglo — App Store Connect automation

Idempotent scripts that create Snuglo's Game Center config (leaderboards +
achievements) in App Store Connect via the ASC API. IDs match the app code
(`LeaderboardID.swift`, `Achievement.swift`), so submitted scores/achievements
land in the right buckets.

## Setup (once)
1. App Store Connect → Users and Access → Integrations → **App Store Connect API** → generate a key (role: **App Manager** or Admin). Download the `.p8` (one-time).
2. `cp secrets/.env.local.example secrets/.env.local` and fill in `APP_STORE_KEY_ID`, `APP_STORE_ISSUER_ID`, `APP_STORE_APP_ID`; put the `.p8` under `secrets/` and point `APP_STORE_KEY_PATH` at it.
3. `pip3 install --user "pyjwt[crypto]"`

## Run
```bash
# Dry-run (lists what WOULD be created — no writes):
python3 scripts/setup_leaderboards.py
python3 scripts/setup_achievements.py

# Apply (creates missing boards/achievements + localizations):
python3 scripts/setup_leaderboards.py --apply
python3 scripts/setup_achievements.py --apply
```

Both are **idempotent**: existing items (matched by vendorIdentifier) are skipped;
only missing items/localizations are created. Safe to re-run.

## IAP + RevenueCat
```bash
python3 scripts/setup_iap.py            # dry-run: ASC IAPs (premium + 5 gem packs)
python3 scripts/setup_iap.py --apply    # create records + en/tr/es loc + USD price
python3 scripts/setup_revenuecat.py     # RC products + 'premium' entitlement + offering
```
- `setup_iap.py` reuses `asc_client.py` (same ASC creds).
- `setup_revenuecat.py` needs `REVENUECAT_SECRET_KEY` (sk_…) + `REVENUECAT_PROJECT_ID` in `secrets/.env.local`. The PUBLIC SDK key (appl_…) goes in `SnugloApp/Core/Config/Secrets.swift`.
- Product IDs match the app: `com.snuglo.premium`, `com.snuglo.gems.tier1..5`. Bundle ID: `com.snuglo.app`.

## Notes
- Leaderboards/achievements stay **"Not Live"** until you submit them with an app version. Once live they **cannot be deleted** (Apple rule).
- **First consumables** (gem packs) must be submitted WITH an app version via the ASC UI (version → In-App Purchases → Add for Review) — the bundle can't be done from the API.
- `secrets/` is git-ignored — never commit the `.p8` or `.env.local`.
