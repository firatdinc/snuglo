# 02 · Win-Streak Chain Bonus

**Rank:** 2 / 20  **Status:** DONE ✅  **Slug:** `winstreak-chain`

## Market / competitor basis (research)
'Don't break the chain' loss-aversion loops drive long sessions (Duolingo streaks, Block Blast combos). Streak bonuses 'maximize retention'.

## Why it makes the game more addictive / juicy
Addiction lever: consecutive solves build a visible chain; breaking it (fail/quit) hurts → players keep going 'one more'.

## Design
Track consecutive level solves; show a rising 'Chain xN' with escalating currency bonus + intensifying juice. Resets on fail/quit.

## Implementation steps
- ProgressStore (or session): winChain counter; +1 each solve, reset on fail.
- GameView/LevelComplete: 'Chain xN' badge + bonus scaling with chain.
- Escalating celebration intensity at higher chains.

## Acceptance criteria
- Solving back-to-back grows the chain & bonus.
- Failing/quitting resets it.
- Build green.

## Constraints (always)
- Driven by competitor/market user demand; goal: juicier, more fun, more addictive (longer sessions).
- Single-palette: colors only from `AppColors` tokens (no hardcoded hex).
- Respect `accessibilityReduceMotion`.
- Must `xcodebuild` green before marking DONE.
- Self-contained: no new entitlements / accounts / API keys / network.
- **Do NOT commit or push** — leave changes in the working tree for the user to review.
