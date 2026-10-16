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

## Parça kumaşları — art/fabric/classic/fNN.png medyan renkleri (hayalet, yan yüz, vurgu için).
const PIECES: Array[Color] = [
	Color("bb7056"),  # 00 terracotta kareli
	Color("c37d27"),  # 01 hardal çiçekli
	Color("6e6c4f"),  # 02 adaçayı fitilli kadife
	Color("69778c"),  # 03 denim
	Color("7a3242"),  # 04 erik kadife puantiye
	Color("e6b49a"),  # 05 şeftali seersucker
	Color("3d5a55"),  # 06 deniz yeşili örgü
	Color("ca7266"),  # 07 gül çiçekli
	Color("6a5d3c"),  # 08 zeytin balıksırtı tüvit
	Color("a48aa7"),  # 09 lavanta waffle
	Color("b47547"),  # 10 karamel ekose
	Color("6c8ba7"),  # 11 gökyüzü yıldızlı
]

static func piece(i: int) -> Color:
	return PIECES[i % PIECES.size()]
