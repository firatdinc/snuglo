class_name Asmr
extends RefCounted
## Kumaş ASMR katmanı: ses + titreşim birlikte. Ayarlar → "Kumaş ASMR sesleri" kapalıyken
## yalnız yedek ses (kısık) çalar, titreşim yine Juice ayarına uyar.
##   Asmr.hit("felt_pop", "light")              tek vuruş: ses + titreşim
##   Asmr.stroke(self, "roll", dist, 26.0, "snow_roll")   sürekli hareket: her N px'te bir
##        hafif tık + ses tanesi (hıza göre perde) → yuvarlama/merdane/kurdele/krema "dokusu"
##   Asmr.stitch_run(node, n, 0.07)              dikiş dizisi: n kez iğne sesi + tık

static var _acc := {}      ## stroke anahtarı → biriken mesafe
static var _last := {}     ## stroke anahtarı → son tetik zamanı (ms)

static func on() -> bool:
	return Settings.get_value("asmr") != false

static func play(name: String, fallback := "", pitch := 1.0, vol_db := 0.0) -> void:
	if on() and Sfx.has_sound(name):
		Sfx.play(name, pitch, vol_db, 0.08)
	elif fallback != "":
		Sfx.play(fallback, pitch, vol_db - 6.0)

static func hit(name: String, haptic := "light", fallback := "", pitch := 1.0, vol_db := 0.0) -> void:
	play(name, fallback, pitch, vol_db)
	if haptic != "":
		Juice.haptic(haptic)

## Sürekli hareket dokusu. owner+key ayrı akışları ayırır; dist bu karede kat edilen px.
## step_px aralıkla tetiklenir; hız (px/sn) perdeyi ve sesi hafifçe artırır.
static func stroke(owner: Object, key: String, dist: float, step_px := 28.0, sound := "rustle",
		haptic := "tick", base_pitch := 1.0) -> void:
	var k := "%d/%s" % [owner.get_instance_id(), key]
	var a: float = float(_acc.get(k, 0.0)) + absf(dist)
	if a < step_px:
		_acc[k] = a
		return
	_acc[k] = fmod(a, step_px)
	var now := Time.get_ticks_msec()
	var dt := maxf(1.0, float(now - int(_last.get(k, now - 120))))
	_last[k] = now
	var speed := clampf(step_px / (dt / 1000.0), 0.0, 3000.0)
	var p := base_pitch * (0.9 + speed / 3000.0 * 0.35)
	if dt > 45.0:           # ses taneleri üst üste binmesin
		play(sound, "", p, -10.0 + speed / 3000.0 * 5.0)
	if haptic != "" and dt > 30.0:
		Juice.haptic(haptic)

static func reset_stroke(owner: Object, key: String) -> void:
	var k := "%d/%s" % [owner.get_instance_id(), key]
	_acc.erase(k)
	_last.erase(k)

## İğne-iplik dizisi (yama dikişi, kumaş birleşmesi).
static func stitch_run(node: Node, n := 6, gap := 0.07, haptic := "tick") -> void:
	for i in n:
		node.get_tree().create_timer(gap * i).timeout.connect(func() -> void:
			play("stitch", "click", 1.0 + 0.04 * i, -6.0)
			if haptic != "":
				Juice.haptic(haptic))
