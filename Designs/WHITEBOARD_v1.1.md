# WHITEBOARD v1.1 — Snuglo App Flow Diagram

> **Kaynak:** `felabs-whiteboard-1779640648643.png`  
> **Absorbe edildi:** 2026-05-26  
> **Durum:** v1.1 scope'u bu dosyadan çıkarıldı; v1.2 backlog BLOCKERS.md'ye işlendi.

---

## Whiteboard Özeti

Whiteboard, Snuglo'nun **hedef v2 tam uygulama akışını** diyagram olarak göstermektedir.

### Ekran Hiyerarşisi

```
Levels (Duolingo style) → Daily Puzzle → Ana Ekran (Oyun) → Leaderboard (Apple Game Center) → Profile
```

### Ana Ekran — 3 CTA
1. **Play Buttons** (Ana giriş)
2. **Tutorial** (Ayrı bir öğretici akış)
3. **Store** (Mağaza / IAP)

### Oyun Akışı (Ana Path)

```
Ana Ekran
  └─► Set Seçimi (Hangi pack/bölüm)
        └─► Oyun Ekranı görünümü
              ├─► Ready / Bag / Go? (Başlangıç onayı)
              └─► Tutorial mı? → Evet/Hayır kararı
                    ├─► Tutorial sayfaları (Çıkış butonu ile)
                    └─► Oyun başlar
```

### Tebrikler Akışı (Başarı)

```
Seviye bitti
  └─► Tebrikler popup gösterilir
        ├─► "Next Level" → Sonraki seviyeye geç
        ├─► "Try Again" → Aynı seviyeyi yeniden başlat
        └─► "Return Home" → Ana ekrana dön
```

### Fail Akışı (Başarısızlık)

```
Seviye bitti (Fail)
  └─► Fail popup gösterilir (LevelCompleteSheet'ten AYRI bir ekran)
        ├─► "Try Again" → Aynı seviyeyi yeniden başlat
        └─► "Return Home" → Ana ekrana dön
```

### Çıkış Butonları (Her ekranda)

- Her oyun ekranından "Exit" (Çıkış) butonu mevcuttur
- Çıkış → Return Home Screen basılabilir (ana ekrana dön)

---

## v1.1 Scope Kararları (Bu Sprint)

| Karar | Durum |
|-------|-------|
| AppRouter.selectTab() bug fix (stack unwind) | ✅ IOS-53'te yapıldı |
| GameView viewModel re-init flash fix | ✅ IOS-53'te yapıldı |
| MainMenuView hardcoded progress fix | ✅ IOS-53'te yapıldı |
| SplashView task leak fix | ✅ IOS-53'te yapıldı |
| PauseSheet swipe-dismiss timer leak fix | ✅ IOS-53'te yapıldı |
| SettingsView notif denial silent fix | ✅ IOS-53'te yapıldı |
| Custom fonts registration (BLOCKER-07) | ✅ IOS-53'te yapıldı |
| Custom Info.plist (BLOCKER-01) | ✅ IOS-53'te yapıldı |
| Stitch Nordic Hearth design refactor | ✅ IOS-53'te yapıldı |

---

## v1.2 Backlog (Whiteboard'dan çıkan, henüz yapılmamış)

| # | Özellik | Not |
|---|---------|-----|
| 1 | **Game Center Leaderboard** | Whiteboard'da ayrı ekran gösterilmekte |
| 2 | **Profile tab/ekranı** | Whiteboard'da ana nav'da gösterilmekte |
| 3 | **Tutorial akışı** | Onboarding'den ayrı, oyun öncesi opsiyonel |
| 4 | **Fail state popup** | LevelCompleteSheet'ten AYRI — Whiteboard'da açıkça ayrıldı |
| 5 | **Daily Puzzle ayrı nav girişi** | Whiteboard'da ana nav'da dedicated buton |
| 6 | **Set seçimi ekranı** | Whiteboard'da "Set seçimi" adımı var; şimdi LevelsList karşılıyor |

> Bu maddeler `BLOCKERS.md` → "v1.2 Backlog" bölümüne işlendi.
