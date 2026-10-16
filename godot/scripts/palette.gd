class_name Palette
extends RefCounted
## Tek palet: tüm renkler buradan. Başka dosyada Color(...) hex YOK (SwiftUI AppColors kuralının devamı).

const BG_TOP := Color("f6e7d6")
const BG_BOTTOM := Color("efd3bd")
const INK := Color("4a3428")          # metin, koyu kahve
const INK_SOFT := Color("8a6a58")
const CREAM := Color("fff7ec")
const BOARD := Color("e9cfb4")        # tahta çerçevesi (ahşap kasnak)
const BOARD_EDGE := Color("c99e7c")
const SLOT := Color("f7e6d2")         # boş hücre yuvası
const SLOT_SHADE := Color("dcc0a3")
const TRAY := Color("f2dcc6")
const SHADOW := Color(0.29, 0.17, 0.1, 0.28)
const GOOD := Color("7fb87a")
const BAD := Color("e2675c")
const GOLD := Color("f2b544")

## Parça kumaşları — sıcak, toprak tonlu; neon yok.
const PIECES: Array[Color] = [
	Color("e98a6b"),  # terracotta
	Color("f0be5a"),  # hardal
	Color("8fbf8a"),  # adaçayı
	Color("79a7d3"),  # soluk mavi
	Color("b58ac9"),  # erik
	Color("f2a9a0"),  # şeftali
	Color("5fb3a9"),  # deniz yeşili
	Color("e57f9b"),  # gül
	Color("a9b86a"),  # zeytin
	Color("9d9be0"),  # lavanta
	Color("d9965b"),  # karamel
	Color("7cc4e0"),  # gökyüzü
]

static func piece(i: int) -> Color:
	return PIECES[i % PIECES.size()]
