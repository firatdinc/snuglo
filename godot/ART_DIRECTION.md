# Snuglo — Sanat yönü: "Patchwork / el yapımı tekstil"

Her şey gerçek, el yapımı bir tekstil objesi gibi görünür ve yumuşak stüdyo ışığında
fotoğraflanmış hissi verir (Yoshi's Woolly World / Kirby Epic Yarn akrabası, ama
yün ipliği değil **patchwork yorgan** dili). Tek bir dünya: yorgan diken bir tembel hayvanın
sıcak evi.

## Kurallar (AI-slop karşıtı)
- Yüzey = kumaş, ip, ahşap, düğme. Parlak plastik, neon, cam, glow, lens flare YOK.
- Işık: tek yönlü, sol-üstten yumuşak; gölgeler kısa ve sıcak (kahve, siyah değil).
- Renk: sıcak toprak paleti (palette.gd). Doygun ama tozlu. Mor-mavi "AI gradyanı" yok.
- Kenar: her parça görünür dikişli (kesikli iplik), kenarlar hafif kabarık/yastıklı.
- Metin görsellerde YOK (logo hariç); yazılar oyunda font ile.
- Karakter: Snuglo = peluş tembel hayvan oyuncağı (keçe yüz, düğme göz değil — işlemeli göz,
  krem yüz maskesi, kahverengi kadife gövde). Tek karakter, tutarlı.
- Kompozisyon: ortalanmış obje, düz zemin (şeffaf istenir), kırpılmamış.

## Eşlemeler
| Oyun öğesi | Tekstil karşılığı |
|---|---|
| Parça | Dikişli kumaş yama (12 kumaş: kareli, çiçekli, kadife, örgü, keten, puantiye…) |
| Tahta | Ahşap yorgan germe çerçevesi, içi krem patiska |
| Boş hücre | Patiska üzerine tebeşir izi kare |
| Coin | Ahşap/kemik dikiş düğmesi |
| Gem | Cam boncuk değil → **altın yüksük** |
| İpucu | İğne + ip |
| Geri al | Sökme makası/ip makarası geri ok |
| Sandık | Hasır dikiş sepeti |
| Çark | Ahşap çıkrık |
| Yıldız | İşlemeli yıldız arması |
| Bölüm haritası | Her paket bir yorgan; bölümler yamalar, bitince dolar |

## Üretim
ChatGPT (Plus, Chrome Browser 2). Sohbet: "Snuglo Patchwork" (URL CLAUDE notlarında).
Yakalama: tools/chatgpt_capture.js → 2x2 karo beyaz+siyah zoom → tools/single.py / capture_import.py.
Ham: art/raw/, işlenmiş: art/<tür>/.
