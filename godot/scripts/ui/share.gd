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

const REVIEW_MIN_LEVELS := 5
const REVIEW_GAP_SEC := 30 * 86400

## Mutlu anda puan isteği (3★ bitiş, paket ödülü, seri kilometre taşı). Sürüm başına en fazla 1,
## aralar ≥30 gün, ≥5 bölüm bitmiş olmalı. Apple ayrıca yılda 3 ile sınırlar.
## delay: kutlama animasyonu otursun diye bekleme.
static func can_request_review() -> bool:
	if Progress.total_completed() < REVIEW_MIN_LEVELS:
		return false
	if String(Settings.get_value("review_last_version")) == VersionGate.current_version():
		return false
	var last := int(Settings.get_value("review_last_ts"))
	return last == 0 or int(Time.get_unix_time_from_system()) - last >= REVIEW_GAP_SEC

static func maybe_request_review(node: Node, delay := 1.4) -> void:
	if not can_request_review():
		return
	Settings.set_value("review_last_ts", int(Time.get_unix_time_from_system()))
	Settings.set_value("review_last_version", VersionGate.current_version())
	Settings.set_value("review_requested", true)
	if not node.is_inside_tree():
		return
	await node.get_tree().create_timer(delay).timeout
	if OS.get_name() == "iOS" and Engine.has_singleton("SnugloBridge"):
		var b := Engine.get_singleton("SnugloBridge")
		if b.has_method("request_review"):
			b.request_review()
