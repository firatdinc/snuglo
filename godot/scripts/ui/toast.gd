class_name Toast
extends Control
## Üstten kayan kısa bilgi balonu (başarım, görev, satın alma). Main.toast() kuyruklar.

var text := ""
var icon_name := ""
var col := Palette.SAGE

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var w := minf(Ui.col_w() - 80.0, Ui.FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 38).x + 200.0)
	size = Vector2(w, 110)
	var card := QuiltCard.new()
	card.fabric = -1
	card.fill = col
	card.radius = 55
	card.depth = 8
	card.size = size
	add_child(card)
	if icon_name != "":
		var ic := Ui.icon(icon_name, Vector2(96, 96))
		ic.position = Vector2(14, 7)
		add_child(ic)
		Ui.pop_in(ic, 0.15, 0.2)
	var l := Ui.label(text, 38, Palette.CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	l.add_theme_color_override("font_outline_color", Color(Palette.INK, 0.4))
	l.add_theme_constant_override("outline_size", 6)
	l.position = Vector2(110 if icon_name != "" else 30, 0)
	l.size = Vector2(w - (140 if icon_name != "" else 60), 110)
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(l)

func play(y: float) -> void:
	position = Vector2((Ui.vp().x - size.x) / 2.0, -160)
	var tw := create_tween()
	tw.tween_property(self, "position:y", y, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.2)
	tw.tween_property(self, "position:y", -160.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)
