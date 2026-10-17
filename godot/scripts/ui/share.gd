class_name Share
extends RefCounted
## Paylaşım + mağaza değerlendirmesi (SnugloBridge). iOS: UIActivityViewController; masaüstünde
## metin panoya kopyalanır. Görsel: o anki ekranın görüntüsü (sonuç kartı / istatistikler).

const STORE_URL := "https://apps.apple.com/app/id6772764229"

static func _bridge() -> Object:
	if OS.get_name() == "iOS" and Engine.has_singleton("SnugloBridge"):
		var b := Engine.get_singleton("SnugloBridge")
		if b.has_method("share"):
			return b
	return null

## text + (with_shot ise) ekran görüntüsü paylaş. Ekranın bir sonraki karesi çizildikten sonra çekilir.
static func share(node: Node, text: String, with_shot := true) -> void:
	var full := "%s\n%s" % [text, STORE_URL]
	var img_path := ""
	if with_shot and node.is_inside_tree():
		await RenderingServer.frame_post_draw
		var img := node.get_viewport().get_texture().get_image()
		if img:
			# Paylaşım için yarı çözünürlük yeter (1080 genişlik), dosya küçük kalsın.
			if img.get_width() > 1080:
				img.resize(1080, int(img.get_height() * 1080.0 / img.get_width()), Image.INTERPOLATE_LANCZOS)
			var p := "user://share.png"
			if img.save_png(p) == OK:
				img_path = ProjectSettings.globalize_path(p)
	var b := _bridge()
	if b:
		b.share(full, img_path)
	else:
		DisplayServer.clipboard_set(full)
		Main.toast(tr_static("transfer.share") + " ✓", "ic_share", Palette.SAGE)

static func tr_static(key: String) -> String:
	return TranslationServer.translate(key)

## Swift MainMenuView.maybeRequestReview: paket tamamlama ödülü toplandıktan sonra, bir kez,
## en az 8 bölüm bitmişse; ödül yerleşsin diye 1.4 sn gecikmeli. Apple ayrıca kısıtlar.
static func maybe_request_review(node: Node) -> void:
	if bool(Settings.get_value("review_requested")) or Progress.total_completed() < 8:
		return
	Settings.set_value("review_requested", true)
	if not node.is_inside_tree():
		return
	await node.get_tree().create_timer(1.4).timeout
	if OS.get_name() == "iOS" and Engine.has_singleton("SnugloBridge"):
		var b := Engine.get_singleton("SnugloBridge")
		if b.has_method("request_review"):
			b.request_review()
