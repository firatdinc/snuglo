# 04 · Reward Chests (variable reward)

**Rank:** 4 / 20  **Status:** DONE ✅  **Slug:** `reward-chests`

## Market / competitor basis (research)
Variable-ratio reward (loot chests) is the strongest dopamine/retention mechanic in casual games (gacha-lite).

## Why it makes the game more addictive / juicy
Unpredictable rewards create compulsion to keep playing to earn & open chests.

## Design
Earn a chest every N solves; chest opens with a juicy reveal granting random currency/skin shards.

## Implementation steps
- ProgressStore: chestProgress; award a chest each N solves.
- Chest open view: shake → burst → reward reveal (single-palette, particles).
- Random reward table (currency tiers / skin shard).

## Acceptance criteria
- Playing fills a chest meter; opening reveals a random reward.
- Build green.

## Constraints (always)
- Driven by competitor/market user demand; goal: juicier, more fun, more addictive (longer sessions).
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
- **Do NOT commit or push** — leave changes in the working tree for the user to review.
