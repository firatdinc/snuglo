extends Node
## Oyuncu tercihleri. Setter'lar kaydeder + Events.settings_changed(key) yayar ve
## Sfx/Juice/TranslationServer'a anında uygular. Kozmetik seçimleri Cosmetics'te.

const LANGS := ["en", "tr", "es"]
const TRACKS := ["auto", "calm", "zen"]
const DEFAULTS := {
	"music_enabled": true,
	"music_volume": 0.6,
	"sfx_enabled": true,
	"sfx_volume": 1.0,
	"haptics": true,
	"haptic_level": "full",      # full | light
	"sound_pack": "classic",     # classic | soft | crisp
	"colorblind": false,
	"theme": 0,                  # 0 sistem, 1 açık, 2 koyu (Swift appTheme)
	"zen_mode": false,
	"reduce_motion": false,
	"language": "",            # "" = sistem dili
	"daily_reminder": false,
	"reminder_hour": 19,
	"reminder_minute": 0,
	"comeback_reminders": false,
	"music_track": "auto",
	"coach_shown": false,
	"onboarded": false,
	"review_requested": false,
}
const HAPTIC_LEVELS := ["full", "light"]
const SOUND_PACKS := ["classic", "soft", "crisp"]

var _s: Dictionary

func _ready() -> void:
	_load()
	Save.reloaded.connect(func() -> void:
		_load()
		for k in DEFAULTS:
			Events.settings_changed.emit(k))

func _load() -> void:
	_s = Save.get_section("settings")
	for k in DEFAULTS:
		if not _s.has(k):
			_s[k] = DEFAULTS[k]
	apply_all()

## Genel okuma (UI bağlamaları için).
func get_value(key: String) -> Variant:
	return _s.get(key, DEFAULTS.get(key))

## Genel yazma: doğrular, kaydeder, uygular, yayar.
func set_value(key: String, value: Variant) -> void:
	if not DEFAULTS.has(key):
		push_warning("Settings: bilinmeyen anahtar %s" % key)
		return
	match key:
		"music_volume", "sfx_volume": value = clampf(float(value), 0.0, 1.0)
		"reminder_hour": value = clampi(int(value), 0, 23)
		"reminder_minute": value = clampi(int(value), 0, 59)
		"language": value = value if value in LANGS else ""
		"music_track": value = value if value in TRACKS else "auto"
		"haptic_level": value = value if value in HAPTIC_LEVELS else "full"
		"sound_pack": value = value if value in SOUND_PACKS else "classic"
		"theme": value = clampi(int(value), 0, 2)
		_: if DEFAULTS[key] is bool: value = bool(value)
	if _s.get(key) == value:
		return
	_s[key] = value
	Save.mark_dirty()
	_apply(key)
	Events.settings_changed.emit(key)

# --- Kısa erişimciler ---
var music_volume: float:
	get: return float(get_value("music_volume"))
	set(v): set_value("music_volume", v)
var music_enabled: bool:
	get: return bool(get_value("music_enabled"))
	set(v): set_value("music_enabled", v)
var sfx_enabled: bool:
	get: return bool(get_value("sfx_enabled"))
	set(v): set_value("sfx_enabled", v)
var sfx_volume: float:
	get: return float(get_value("sfx_volume"))
	set(v): set_value("sfx_volume", v)
var haptics: bool:
	get: return bool(get_value("haptics"))
	set(v): set_value("haptics", v)
var zen_mode: bool:
	get: return bool(get_value("zen_mode"))
	set(v): set_value("zen_mode", v)
var reduce_motion: bool:
	get: return bool(get_value("reduce_motion"))
	set(v): set_value("reduce_motion", v)
var language: String:
	get: return String(get_value("language"))
	set(v): set_value("language", v)
var daily_reminder: bool:
	get: return bool(get_value("daily_reminder"))
	set(v): set_value("daily_reminder", v)
var reminder_hour: int:
	get: return int(get_value("reminder_hour"))
	set(v): set_value("reminder_hour", v)
var reminder_minute: int:
	get: return int(get_value("reminder_minute"))
	set(v): set_value("reminder_minute", v)
var comeback_reminders: bool:
	get: return bool(get_value("comeback_reminders"))
	set(v): set_value("comeback_reminders", v)
var music_track: String:
	get: return String(get_value("music_track"))
	set(v): set_value("music_track", v)

## Çalınması gereken parça: auto → zen modunda "zen", değilse "calm".
func desired_track() -> String:
	var t := music_track
	if t == "auto":
		return "zen" if zen_mode else "calm"
	return t

## Etkin dil kodu (sistem dili desteklenmiyorsa en).
func effective_language() -> String:
	if language != "":
		return language
	var sys := OS.get_locale_language()
	return sys if sys in LANGS else "en"

func apply_all() -> void:
	for k in ["music_volume", "sfx_volume", "haptics", "reduce_motion", "language"]:
		_apply(k)

func _apply(key: String) -> void:
	match key:
		"sfx_volume", "sfx_enabled":
			Sfx.sfx_volume = sfx_volume if sfx_enabled else 0.0
		"music_volume", "music_enabled":
			# Sfx.gd'ye dokunmuyoruz: kanca varsa kullan.
			if Sfx.has_method("set_music_volume"):
				Sfx.call("set_music_volume", music_volume if music_enabled else 0.0)
		"haptics":
			Juice.haptics = haptics
		"reduce_motion":
			Juice.reduce_motion = reduce_motion
		"language":
			TranslationServer.set_locale(effective_language())
