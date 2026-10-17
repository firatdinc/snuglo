extends SceneTree
## AdMob'un SPM yamasını elle uygular.
##
## Poing AdMob eklentisi iOS'ta Google Mobile Ads SDK'sını bir yerel Swift
## paketi (build/ios/admob_spm) üzerinden bağlıyor ve bunu Xcode projesine
## `_end_generate_apple_embedded_project` kancasıyla işlemesi gerekiyor.
## Godot 4.6'da o kanca başlıksız (headless) dışa aktarımda çalışmıyor:
## Package.swift üretiliyor ama project.pbxproj'a paket referansı hiç
## girmiyor, arşiv de "Undefined symbols: _OBJC_CLASS_$_GADBannerView..."
## diye bağlayıcıda patlıyor. Eklentinin kendi yama kodunu dışarıdan
## çağırmak, o boşluğu kapatan en küçük müdahale.
##
## Godot 4.8'de eklenti bu yolu kendisi atlıyor (SPM desteği motora girdi),
## o sürüme geçilince bu betik de gereksizleşir.
##
##   godot --headless --path . --script tools/ios_spm_patch.gd

const PbxprojService := preload("res://addons/admob/internal/services/pbxproj_service.gd")

const PBXPROJ := "res://build/ios/Snuglo.xcodeproj/project.pbxproj"


func _init() -> void:
	var path := ProjectSettings.globalize_path(PBXPROJ)
	if not FileAccess.file_exists(path):
		printerr("project.pbxproj yok: ", path, " - önce dışa aktarım çalışmalı")
		quit(1)
		return

	var before := FileAccess.get_file_as_string(path)
	PbxprojService.patch(path)
	var after := FileAccess.get_file_as_string(path)

	if before == after:
		print("yama zaten uygulanmış (ya da uygulanamadı), dosya değişmedi")
	else:
		print("yama uygulandı: +%d karakter" % (after.length() - before.length()))
	print("admob_spm referansı: ", "var" if after.contains("admob_spm") else "YOK")
	quit(0)
