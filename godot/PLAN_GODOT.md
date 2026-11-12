# Snuglo → Godot 4.6 yeniden yazım planı

Hedef: SwiftUI uygulamasını oyun mekanikleri dahil Godot'ya taşımak; çok daha "juicy",
tüm görseller ChatGPT'den, hiçbir şey AI-slop/şablon görünmeyecek. Swift uygulaması
referans olarak `SnugloApp/` altında kalır, yeni oyun `godot/` altında.

## Değişmezler
- **Aynı bulmacalar:** `engine/` Swift SnugloEngine'in birebir portu. `tests/parity_test.gd`
  Swift çıktısıyla (tools/parity/swift_levels.json) 255/255 eşleşmeli. Motora dokunursan testi koş.
- **Tek palet:** renkler yalnız `scripts/palette.gd`.
- 4 paket × 60 bölüm (5×5…8×8), günlük bulmaca UTC tarih seed'i, yıldız: süre eşikleri (30/60/90/120 sn).

## Fazlar
| # | Faz | Durum |
|---|-----|-------|
| 0 | Proje iskeleti, motor portu + parite testi | ✅ |
| 1 | Çekirdek oyun: tahta, tepsi, sürükle (lift/tilt/ghost/mıknatıs), thunk (squash+toz+dalga+nota), geri al, ipucu, çözüm sekansı, kazanma paneli | ✅ ilk sürüm (placeholder çizim) |
| 2 | Sanat yönü: konsept + stil kılavuzu + ChatGPT prompt seti (kullanıcı onayı) | ⏳ |
| 3 | ChatGPT asset hattı (matte yakalama → art/), kumaş dokuları parçalara, tahta kasnağı, arka planlar, UI kit, maskot | |
| 4 | Meta: ana menü, paket haritası, bölüm seçimi, ilerleme kaydı (ProgressStore portu), yıldız/rekor | |
| 5 | Ekonomi + meta oyun: coin/gem, günlük ödül, görevler, sandık, çark, başarımlar, streak, XP | |
| 6 | Modlar: günlük (çoklu), endless, zen | |
| 7 | Ses: SFX seti genişletme, müzik, adaptif katman | |
| 8 | iOS: export, StoreKit/Game Center/AdMob eklentileri, bildirimler, EN/TR/ES | |
| 9 | Cila + performans + cihaz testi, yayın | |

## Geliştirme kısayolları
`tools/shot.sh <png> <sn> [ENV=..]` — pencereli çalıştırıp ekran görüntüsü.
- `SNUG_LEVEL=spice-route:30` bölüm seç · `SNUG_DAILY=1` günlük
- `SNUG_AUTO=<n>` n parçayı çözüm yerine koy (99 → kazanma)
- `SNUG_DRAG=1|drop` gerçek dokunma olaylarıyla sürükleme testi
- `SNUG_MUTE=1` sessiz
- Parite: `Godot --headless --path godot -s tests/parity_test.gd`

## Sanat yönü (kullanıcı onayı 2026-10-16): YORGAN / PATCHWORK
Parçalar dikişli kumaş yamalar (kareli, çiçekli, kadife, örgü, keten…), tahta ahşap nakış
kasnağı, arka plan sıcak oda/battaniye. Bölüm bitince yorgan tamamlanır, tembel hayvan maskot
(Snuglo'nun mevcut sloth maskotu) içine kıvrılır. Ayrıntı: `ART_DIRECTION.md`.

## Store'a çıkış kontrol listesi (eksiksiz)
Oyun
- [x] Çekirdek bulmaca + juice · [ ] kumaş dokulu parçalar · [ ] tepsi kaydırma (8×8'de büyük parçalar)
- [ ] Duraklat menüsü (devam/yeniden/ayarlar/ev) · [ ] ipucu ekonomisi (sayı → gem → ödüllü reklam)
- [ ] Bölüm sonu: yıldız, coin ödülü, rekor süre, sonraki · [ ] etkileşimli öğretici (el animasyonu, Lv1)
- [ ] Zen modu (süre yukarı, sınırsız geri al) · [ ] Endless · [ ] Günlük (3 bölüm/gün) + takvim + seri
Meta
- [ ] Splash · [ ] Ana menü (günlük kart, devam, seri alevi, bakiye, maskot)
- [ ] Paket haritası + bölüm seçimi (yıldızlar, kilitler, paket ilerlemesi)
- [ ] Kayıt sistemi (versiyonlu JSON), eski SwiftUI kaydından GEÇİŞ (UserDefaults okunamaz → Faz 8'de not)
- [ ] Coin/gem cüzdanı, günlük giriş ödülü (7 gün), 3 günlük görev, sandık metresi, günlük çark
- [ ] XP/seviye, 16 başarım + toast, paket tamamlama ödülü, istatistikler
- [ ] Mağaza: paket kilitleri (IAP), reklam kaldır, ipucu paketi, kumaş/tahta kozmetikleri (coin/gem)
- [ ] Ayarlar: müzik/efekt ses, titreşim, zen, hareketi azalt, dil (EN/TR/ES), bildirim, satın alma geri yükle, gizlilik, ilerleme sıfırla
Platform
- [ ] iOS export (com.felabs.snuglo), ikon, launch screen
- [ ] StoreKit (GodotApplePlugins) — ürünler: com.snuglo.pack.{spice_route,mambo_nights,woodland_retreat}, com.snuglo.removeads, com.snuglo.hints.small
- [ ] Game Center: snuglo.total.levels, snuglo.fastest.solve, snuglo.best.streak
- [ ] Reklam (ödüllü + geçiş) — eklenti uygunluğu kontrol; yoksa reklamsız yayın, removeads kalkar
- [ ] Yerel bildirim (günlük hatırlatma)
- [ ] EN/TR/ES tam parite
- [ ] Mağaza görselleri, metadata, cihazda test, TestFlight
