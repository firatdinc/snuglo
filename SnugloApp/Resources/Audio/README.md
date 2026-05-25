# Snuglo — Audio Assets

## Status: PLACEHOLDER (Faz J delivery)

AudioManager.swift silently no-ops when files are absent.
Sound-designer delivers real assets in **Faz J**.

---

## Expected File List

### Sound Effects (SFX)
| Filename         | Format | Duration  | Description |
|-----------------|--------|-----------|-------------|
| `pickup.wav`    | wav    | ~50 ms    | Soft "lift" when piece is grabbed from tray |
| `drop.wav`      | wav    | ~80 ms    | Muted thud when piece returns without snap |
| `snap.wav`      | wav    | ~100 ms   | Satisfying click when piece locks into grid slot |
| `levelComplete.wav` | wav | ~600 ms  | Warm chime cascade — level solved |
| `error.wav`     | wav    | ~150 ms   | Gentle low tone — invalid placement |

### Background Music (BGM)
| Filename        | Format | Duration  | Description |
|----------------|--------|-----------|-------------|
| `bgm_cozy.mp3` | mp3    | 2–4 min   | Looping ambient — cozy/hygge feel, soft piano+pads |

---

## Faz G Hook (Premium Music)
AudioManager.startBGM(track:) accepts a track name parameter.
To unlock premium tracks via StoreKit:

```swift
// Faz G integration point
if StoreManager.shared.isPurchased(.premiumMusic) {
    AudioManager.shared.startBGM(track: "bgm_premium")
} else {
    AudioManager.shared.startBGM(track: "bgm_cozy")
}
```

Gate `StoreManager.isPurchased(.premiumMusic)` behind the Snuglo Plus subscription
(see `PLAN_v0.2.md` → Shop / StoreKit section).

---

## Sound Design Briefs

**Tone:** Nordic Hearth / cozy minimalism.
- SFX: dry, organic, wooden-toy feel. No harsh attacks.
- BGM: ambient, non-intrusive. Works at 0.4 volume under focus audio.
- Session category: `.ambient` (mixes with system music, silenced by mute switch).

**Tools:** Kontakt, Ableton Live, or similar. Target sample rate 44.1 kHz, 16-bit PCM.
