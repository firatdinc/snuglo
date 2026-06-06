# Snuglo — Monetizasyon & Ekonomi Tasarımı

> Kaynak karar oturumu: 2026-06-05. Felsefe: **Nazik** (cozy markayla uyumlu).
> Bu doküman entegrasyonların (GameCenter / AdMob / RevenueCat) üzerine kurulacağı
> ekonomi modelinin tek doğruluk kaynağıdır.

## Stratejik kararlar (onaylı)
- **Monetizasyon felsefesi:** Nazik — kozmetik + convenience + reklamsız abonelik. İlerleme ASLA bloklanmaz (enerji/can yok, sert paywall yok).
- **Gem'in asıl harcama yeri:** (1) Premium kozmetik, (2) Convenience.
- **Zen kazanımı:** Küçük günlük cap (az XP/coin, **gem yok**); farm imkânsız.
- **Zen/Endless çeşitlilik:** Layout'lar tekrara düşmemeli.

## Teşhis — mevcut sızıntılar (kod kanıtı)
- **Zen/Endless ödül gate'siz:** `GameView.swift:561-587` (currency), `GameView.registerCombo` (combo coin+gem), `GameViewModel.swift:435` (XP) zen/endless'te tam çalışıyor. Zen'de sınırsız ücretsiz undo → her çözüm garantili 3★/perfect → sonsuz coin+gem+XP farmı.
- **`stars: 3` hardcoded** (`GameView.swift:571`) → her çözüm gerçek performanstan bağımsız maksimum coin veriyor.
- **Gem musluğu çok açık:** her ilk-çözüm + her personal-best + her 3★ + combolar gem veriyor (`CurrencyReward.swift`). Tek sink: power-up (hint30/undo20/shuffle15) + exchange. Undo zaten ücretsiz → gem talebi yok.
- **Endless tekrar:** her run `endless-1`'den başlıyor + üretici deterministik (`makeFromPackProvider:128`).

## Para modeli: coin = yumuşak/bol · gem = sert/kıt
| | Coin | Gem |
|---|---|---|
| Kaynak | Bol (kampanya çözümü, daily, combo, chain, level-up) | Kıt (nadir başarım, rewarded-ad günlük cap, IAP) |
| Harcama | Ucuz/kozmetik, retry, küçük şeyler | Premium kozmetik + convenience |

---

## Faz 1 — Ekonomi rebalance (saf logic, SDK yok) ✅ YAPILDI (2026-06-05)
Uygulanan: `RelaxedRewardStore` (zen+endless günlük cap 50XP/25coin, 0 gem); solve ödülü `GameViewModel.persistProgress`'e taşındı (gerçek yıldız, gem yalnız kampanya ilk-3★); combo→coin (gem kaldırıldı) + relaxed'te combo/chain/coin yok; relaxed'te quest/chest/weekly/leaderboard ilerlemesi YOK. Build + unit testler yeşil.

### Orijinal plan
1. **`stars:3` → gerçek yıldız** (coin gerçek performansa göre).
2. **Zen + Endless = RELAXED mod:** günlük cap'li ödül.
   - Yeni `RelaxedRewardStore` (gün bazlı reset): **maks 50 XP/gün + 25 coin/gün**, **0 gem**.
   - Cap dolunca relaxed çözümler 0 ödül.
3. **Gem musluğunu kıs:** gem yalnız bir level'in **ilk kez 3★** yapılışında (level başına bir kez, ömür boyu). Personal-best gem faucet'i kaldır. Combo'lar **sadece coin** (combo gem kaldır). Milestone combo → ekstra coin.
4. **Gem kaynakları (korunur):** haftalık challenge, başarımlar, pack tamamlama, daily quest, rewarded-ad (Faz 4 cap'li).

## Faz 2 — Çeşitlilik (zen tekrar fix)
- Endless/Zen üretiminde **seed her yüklemede değişsin** (deterministik değil) → layout'lar tekrar etmez. `makeFromPackProvider` endless dalında rastgele `seedBase`.
- (Opsiyonel) endless grid tabanını 5'e çek → çeşitlilik zemini artar.

## Faz 3 — Gem sink'leri (talep yarat) ✅ KISMEN YAPILDI (2026-06-05)
Yapılan — **premium kozmetik tier (gem-only)**: 2 premium skin (midnight 💎300, blossom 💎400, `Colors.swift` `BlockSkin.premiumCost`, `unlockLevel:.max`) + 2 premium board (twilight/ember 💎250, `BoardBackground.gemCost`). `CosmeticsStore` board satın almayı da tutuyor (`unlockedBoards`/`buyBoard`). Settings skin & board selector'ları premium'u kilitli+💎fiyat+sparkle gösterir, dokununca gem ile satın alır. Bedava (level-unlock) kozmetikler PAYWALL'lanmadı. en/tr/es lokalize. Build + testler yeşil.
Kalan — **convenience** sink'leri: streak-freeze + power-up'lar (hint/undo/shuffle) zaten gem ile var; eklenebilir: timed-level "devam et", daily ekstra deneme, ipucu paketi.

### Orijinal plan
- **Premium kozmetik tier:** mevcut level-unlock skin/board'lar bedava kalır; üstüne **gem/IAP-özel** premium skin & board temaları (animasyonlu, mevsimlik). Cozy oyunda en sağlıklı sink.
- **Convenience:** zorlu timed-level'da "devam et", günlük challenge ekstra deneme, ipucu paketi, streak-freeze (mevcut).

## Faz 4 — GameCenter ✅ KOD YAPILDI (2026-06-05)
Yapılan: launch'ta auth (`RootView.task`); achievement → GC (`Achievement.gcID`, `GameCenterServicing.report`, `GameCenterManager` GKAchievement, persist'te yeni unlock'lar raporlanır); **endless leaderboard** (`LeaderboardID.endlessBest`, endless solve'da submit, Leaderboard ekranında 4. sekme + localScore + en/tr/es). Entitlement zaten var. Build + testler yeşil.

### ASC kurulumu OTOMATİK (script'ler hazır)
`scripts/setup_leaderboards.py` + `setup_achievements.py` (paylaşılan `scripts/asc_client.py`, ASC API + JWT) ASC'de 4 leaderboard + 16 achievement'ı **idempotent** oluşturur. ID'ler app koduyla eşleşir; isim/açıklama Localizable.strings'ten (en/tr/es) okunur. `secrets/.env.local` (key id/issuer/.p8/app id) doldurulup `--apply` ile çalıştırılır. Dry-run default. Detay: `scripts/README.md`. Worplix pattern'i — bkz [[reference_percio_scripts]].

### ⚠️ Yine de imzalı build + cihazda GC oturumu gerekir
İmzasız simülatörde GC auth hata döner → "Couldn't Load" (fallback simulated entries gösterilir) — **bu beklenen**, bug değil. Cihazda/imzalı build'de çalışması için App Store Connect'te:
- **Leaderboard ID'leri:** `snuglo.total.levels`, `snuglo.fastest.solve`, `snuglo.best.streak`, `snuglo.endless.best`
- **Achievement ID'leri:** her biri `snuglo.achievement.<rawValue>` (16 adet: firstSteps, levelHunter10, levelMaster50, levelLegend100, packFinisher, perfectionist1, perfectionistPro10, perfectionistMaster25, streak3, streak7, streak30, dedicated7, comboChampion, noHints10, speedSolver, speedDemon)
- Game Center capability'li provisioning profile + cihazda GC oturumu.

### Orijinal plan
- Leaderboard (totalLevels / fastestSolve / bestStreak — zaten mapli) + **Endless leaderboard** (endless'ın yeni ödülü = şeref).
- Achievements (16 mevcut) GC'ye bağlanır. Doğrudan gelir değil; retention besler.

## Faz 5 — AdMob ✅ YAPILDI (2026-06-05)
GoogleMobileAds 11.13.0 SPM (`project.yml`). `AdsManager` gerçek SDK ile: launch'ta `start()` (RootView), interstitial + rewarded load/preload + present (present sonrası anında reload), frequency-cap mantığı & unit testleri korundu. Info.plist: `GADApplicationIdentifier` (DEV = Google TEST app id), `NSUserTrackingUsageDescription` (vardı), tam SKAdNetwork listesi. DEBUG'da Google TEST ad unit'leri. Runtime doğrulandı: SDK crash'siz başladı, test rewarded reklamı ağdan yüklendi. Build + testler yeşil.
**Release öncesi:** Info.plist `GADApplicationIdentifier`'ı + `AdsManager.AdUnitID` release birimlerini gerçek AdMob hesabıyla değiştir (DEV'de hepsi test ID).

### Orijinal plan
- **Rewarded ad = ücretsiz gem musluğu** (günlük cap; ödemeyi cazip tutacak kadar az). Interstitial = level arası (Plus aboneliğiyle kalkar).

## Faz 6 — RevenueCat ✅ YAPILDI (2026-06-06)
Kod: RevenueCat 5.74.0 SPM, `RevenueCatManager` (premium entitlement "premium" + gem paketleri), `StoreManager.isPremium` köprüsü, `PremiumPaywallSheet` (enerji gate + Profile'dan), `Secrets.revenueCatPublicKey` (appl_… placeholder), launch configure. Otomasyon: `scripts/setup_iap.py` (ASC: premium + 5 gem IAP + loc + USD fiyat) + `scripts/setup_revenuecat.py` (RC ürün/entitlement/offering). **Bundle ID: com.snuglo.app.** Kullanıcı yapacak: appl_ key → Secrets.swift; sk_+project id → .env.local; setup_iap --apply → setup_revenuecat.

### Orijinal plan
- **Tüketilebilir gem paketleri:** $0.99 / $4.99 / $9.99 / $19.99 / $49.99 ladder + "BEST VALUE" ribbon.
- **Snuglo Plus aboneliği:** reklamsız + aylık gem + özel kozmetik (Profile'da "Go Premium" zaten duruyor).
- **Starter pack:** tek seferlik, yüksek değer, limited countdown.

## Faz 7 — Enerji sistemi (model değişimi) ✅ YAPILDI (2026-06-05)
**Karar değişikliği:** "nazik" yerine **enerji-gate** ile premium'a itme (kullanıcı talebi 2026-06-05).
- `EnergyStore`: max **50**, oyun başına **−5**, **3 dk'da +1**, timestamp-anchor ile **offline regen** (app'e dönünce geçen süre ölçülür). Premium = **sınırsız** (`StoreManager.isPremium`); UITest bypass; `@ObservationIgnored` (TimelineView tick ile UI).
- **Zen/Endless ÜCRETSIZ** (enerji harcamaz) — gate route-bazlı (`endless-*` muaf).
- Gate `AppRouter.push(.game/.gamePlay)`'de: yetmezse `EnergyGateSheet` (canlı countdown + rewarded-ad +10 refill + "Go Premium"). Next-level best-effort charge (bloklamaz).
- **MainMenu reorg:** enerji çubuğu (HUD + regen countdown / ∞), **Zen Mode kartı** prominent (rewards rail yerine), spin/daily/chest **floating FAB + dropdown**'a taşındı.
- `StoreManager.isPremium` (premium SKU `com.snuglo.premium`; DEBUG override `snuglo.debug.premium`); premium reklamsız da yapar.
- **1000+ bölüm:** MockData 4→**17 pack × 60 = 1020**; tüm pack'ler ücretsiz/progresyon (pack-IAP kaldırıldı, `isPackUnlocked`→true); "240" → `MockData.totalLevels`. en/tr/es pack isimleri.
Build + testler yeşil. **Kalan:** RevenueCat (premium satın alma) + IAP/RC otomasyon → Faz 6.

## ⚠️ Cozy gerilimi (güncel not)
Enerji-gate "nazik" ilkesinden saptı (bilinçli, premium dönüşümü için). Zen/Endless ücretsiz kalarak "cozy kaçış" korunur — ilerlemeli/ödüllü oyun enerji ile gate'lenir.
Marka "cozy/relax" — sert monetizasyon (enerji/can, ilerleme paywall'u) markayla çelişir ve retention'ı düşürür. Tüm fazlar "nazik" çerçevede kalır.

## Sayılar ayarlanabilir
Yukarıdaki tüm rakamlar (cap'ler, gem fiyatları, IAP ladder) ilk öneridir; playtest/analytics ile tune edilecek.
