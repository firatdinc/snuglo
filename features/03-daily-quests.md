# 03 · Daily Quests

**Rank:** 3 / 20  **Status:** DONE ✅  **Slug:** `daily-quests`

## Market / competitor basis (research)
Daily quests/objectives are a retention staple in every top casual game; daily challenges raise retention ~40%.

## Why it makes the game more addictive / juicy
Gives players a fresh reason to open the app daily and a clear short-term goal loop.

## Design
3 rotating daily quests (e.g. 'solve 3 levels', 'win under 60s', 'use 0 hints') with progress + currency rewards; reset daily.

## Implementation steps
- `DailyQuest` model: deterministic-from-date set of 3; progress tracked in ProgressStore.
- Hook progress on solve events; persist; reset on day change.
- MainMenu quests card + claim flow + juicy claim.

## Acceptance criteria
- 3 quests shown daily with progress.
- Resets each day; rewards claimable once.
- Build green.

## Constraints (always)
- Driven by competitor/market user demand; goal: juicier, more fun, more addictive (longer sessions).
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
- **Do NOT commit or push** — leave changes in the working tree for the user to review.
