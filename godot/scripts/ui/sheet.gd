class_name Sheet
extends Control
## Modal kart: karartma + kumaş panel. style "center" yaylanarak büyür, "bottom" aşağıdan kayar.
## Alt sınıf build() içinde `panel`e ekler (panel yerel koordinatı). close() animasyonla kapatır.

signal closed

var args := {}
var style := "center"
var dismissible := true
var panel_size := Vector2(-1, 900)   ## x<0 → sütun genişliği - 80
var panel_fabric := -1
## 9-dilim panel dokusu (art/ui/panel_cream|panel_sage); "" → dikişli kumaş kart.
var panel_skin := "panel_cream"
var dim_alpha := 0.55
var panel: QuiltCard
var _dim: ColorRect
var _closing := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_dim = ColorRect.new()
	_dim.color = Color(Palette.DIM, 0.0)
	_dim.size = size
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_dim_input)
	add_child(_dim)
	panel = QuiltCard.new()
	panel.inner = 22.0
	panel.fabric = panel_fabric
	panel.skin_name = panel_skin
	panel.radius = 56.0
	panel.depth = 16.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var w := panel_size.x if panel_size.x > 0 else Ui.col_w() - 80.0
	panel.size = Vector2(w, panel_size.y)
	add_child(panel)
	_place_panel()
	build()
	_open()

func _place_panel() -> void:
	var v := size
	if style == "bottom":
		panel.position = Vector2((v.x - panel.size.x) / 2.0, v.y - panel.size.y - Ui.safe_bottom() - 30.0)
	else:
		panel.position = (v - panel.size) / 2.0 + Vector2(0, 20)

func build() -> void:
	pass

func _open() -> void:
	create_tween().tween_property(_dim, "color:a", dim_alpha, 0.25)
	Sfx.play("click", 0.8, -8.0)
	if Ui.reduce_motion():
		panel.modulate.a = 0.0
		create_tween().tween_property(panel, "modulate:a", 1.0, 0.2)
		return
	if style == "bottom":
		var to := panel.position
		panel.position.y = size.y + 40
		create_tween().tween_property(panel, "position", to, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		Ui.pop_in(panel, 0.0, 0.55, 0.45)

func _on_dim_input(e: InputEvent) -> void:
	if dismissible and ((e is InputEventScreenTouch and not e.pressed) or (e is InputEventMouseButton and not e.pressed and e.button_index == MOUSE_BUTTON_LEFT)):
		close()

## Geri hareketi: kapatılabilirse kapat.
func on_back() -> bool:
	if dismissible:
		close()
	return true

func close() -> void:
	if _closing:
		return
	_closing = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween().set_parallel()
	tw.tween_property(_dim, "color:a", 0.0, 0.2)
	if style == "bottom" and not Ui.reduce_motion():
		tw.tween_property(panel, "position:y", size.y + 40, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	else:
		tw.tween_property(panel, "scale", Vector2(0.85, 0.85), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_property(panel, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(func() -> void:
		closed.emit()
		queue_free())

# ---- Yardımcılar (panel yerel koordinatları)

func pw() -> float:
	return panel.size.x

func add(c: Control, pos: Vector2, sz := Vector2(-1, -1)) -> Control:
	if sz.x >= 0:
		c.size = sz
	c.position = pos
	panel.add_child(c)
	return c

## Ortalanmış başlık; altının y'sini döndürür.
func heading(text: String, y := 60.0, fs := 64) -> float:
	var l := Ui.label(text, fs, Palette.INK, HORIZONTAL_ALIGNMENT_CENTER)
	add(l, Vector2(40, y), Vector2(pw() - 80, fs * 1.4))
	return y + fs * 1.4

func body(text: String, y: float, fs := 38, col := Palette.INK_SOFT) -> float:
	var l := Ui.wrap(Ui.label(text, fs, col, HORIZONTAL_ALIGNMENT_CENTER), pw() - 140)
	add(l, Vector2(70, y))
	var lines := maxi(1, l.get_line_count())
	l.size.y = lines * fs * 1.3
	return y + lines * fs * 1.3

## Panelin altına kapat ("×") butonu (sağ üst).
func close_x() -> JuicyButton:
	var b := Ui.icon_button("ic_close", 100)
	add(b, Vector2(pw() - 90, -30), Vector2(110, 110))
	b.tapped.connect(close)
	return b

## Panel üst kenarına taşan kurdele başlık (art/ui/banner.png). Altının y'sini döndürür.
func banner_title(text: String, w := 640.0) -> float:
	var b := Ui.banner(text, w)
	add(b, Vector2((pw() - b.size.x) / 2.0, -60))
	Ui.pop_in(b, 0.12, 0.4)
	return b.size.y - 40.0
