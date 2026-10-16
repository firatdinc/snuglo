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
