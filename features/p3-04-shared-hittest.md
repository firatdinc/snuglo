# p3-04 · Shared Cell Hit-Test Helper + occupancy test

**Phase 3 (follow-up suggestions)**  **Status:** DONE ✅  **Slug:** `shared-hittest`

## What & why
Unify tray/board/carousel cell-accurate hit-testing behind one helper so it can never be forgotten again; add a pure-logic unit test for 'which piece occupies cell (x,y)' to guard the overlapping-piece regression.

## Constraints (always)
- Single-palette AppColors (no hardcoded hex); respect Reduce Motion.
- Must xcodebuild green before marking DONE.
- Self-contained; no regressions to the 20 features + 10 UI polish.
- Do NOT commit or push — user reviews at the very end.
- (p3-10 only) STOP after prep and request the audio files from the user.
