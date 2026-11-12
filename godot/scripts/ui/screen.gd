class_name Screen
extends Control
## Yönlendiricinin tam ekran sayfası. Router her ekranı kendi CanvasLayer'ına koyar.
## Alt sınıf: build() içinde düğümleri kurar (boyut hazır), on_enter() geçiş bitince,
## on_resume() üstteki ekran kapanınca, on_back() geri hareketi (true = işlendi).

var args := {}
var route := ""

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build()

func build() -> void:
	pass

func on_enter() -> void:
	pass

func on_resume() -> void:
	pass

## Geri: varsayılan bir önceki ekrana dön (yığında varsa).
func on_back() -> bool:
	return false

## Ekrandan gizlenirken/gösterilirken (üstüne ekran açıldı/kapandı).
func on_cover(_covered: bool) -> void:
	pass

# Kısayollar
var W: float:
	get: return Ui.col_w()
var X0: float:
	get: return Ui.col_x()
var H: float:
	get: return size.y
var TOP: float:
	get: return Ui.safe_top()
var BOTTOM: float:
	get: return Ui.safe_bottom()

func put(c: Control, pos: Vector2, sz := Vector2(-1, -1), parent: Node = null) -> Control:
	if sz.x >= 0:
		c.size = sz
	c.position = pos
	(parent if parent else self).add_child(c)
	return c

## Standart başlık çubuğu: geri butonu + başlık (+ isteğe bağlı TopBar). Alt kenar y'sini döndürür.
func header(title_key: String, with_bar := false, back := true) -> float:
	var y := TOP + 30.0
	if back:
		var b := Ui.icon_button("ic_home", 120)
		b.icon = null
		b.text = "‹"
		b.font_size = 84
		b.text_col = Palette.INK
		put(b, Vector2(X0 + 30, y), Vector2(120, 120))
		b.tapped.connect(func() -> void: Main.back())
		Ui.pop_in(b, 0.05)
	if with_bar:
		var bar := TopBar.new()
		put(bar, Vector2(X0 + 170, y + 18), Vector2(W - 200, 90))
		bar.align_right = true
	var t := Ui.title(tr(title_key), 72)
	put(t, Vector2(X0, y + (140.0 if with_bar else 0.0)), Vector2(W, 120))
	Ui.pop_in(t, 0.08, 0.8)
	return y + (140.0 if with_bar else 0.0) + 130.0
