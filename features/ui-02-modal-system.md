# ui-02 · Unified Reward Modal System

**Rank:** 02 / 10 (Phase 2 — UI polish)  **Status:** DONE ✅  **Slug:** `modal-system`

## UX / market basis
Consistency is a top driver of perceived quality (HIG). The new overlays (chest/spin/level-up/streak/calendar) were each hand-built.

## Why it makes the app look more premium / appealing
Reward overlays share intent but differ subtly in scrim, card, spring, and button styles → inconsistent, less premium.

## Design
A shared `RewardModal` container (scrim 55-60%, glass card, spring-in, consistent Collect button + close affordance). Refactor the 5 overlays to use it.

## Implementation steps
- Create `RewardModal` wrapper view (scrim + centered card + entrance animation + standard primary button).
- Refactor ChestRevealOverlay / SpinWheelOverlay / LevelUpOverlay / StreakMilestoneOverlay / DailyCalendarView to compose it.
- Single dismissal + Reduce-Motion behavior.

## Acceptance criteria
- All reward popups share one polished look/feel.
- Build green.

## Constraints (always)
- Goal: make the WHOLE project look beautiful, premium & appealing ("alıcı").
- Single-palette AppColors (no hardcoded hex); respect Reduce Motion.
- Must xcodebuild green before marking DONE.
- Self-contained; no behavior regressions to the 20 features.
- Do NOT commit or push — user reviews at the very end.
