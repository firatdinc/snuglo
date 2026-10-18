extends Node
## Ses: havuzlu oynatıcılar (üst üste sesler birbirini kesmez) + perde varyasyonu.

const POOL := 12
## Pentatonik merdiven: her yerleşim bir sonraki notayı çalar → tahta dolarken melodi yükselir.
const SCALE := [1.0, 1.125, 1.25, 1.5, 1.667, 2.0, 2.25, 2.5, 3.0, 3.333, 4.0, 4.5]

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var sfx_volume := 1.0
## Müzik: 0..1 kullanıcı sesi (Settings), parça "calm" | "zen". Geçişte çapraz soluklaşma.
const TRACKS := {"calm": "res://audio/music/bgm_play.wav", "zen": "res://audio/music/bgm_zen.mp3"}
const MUSIC_DB := -14.0
var music_volume := 0.6
var track := ""
var _fade: Tween

func _ready() -> void:
	for n in ["click", "combo", "error", "levelUp", "place", "reward", "snap", "solve"]:
		_streams[n] = load("res://audio/sfx/%s.wav" % n)
	for i in POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music_b = AudioStreamPlayer.new()
	add_child(_music)
	add_child(_music_b)
	Events.settings_changed.connect(func(k: String) -> void:
		if k in ["music_track", "zen_mode"]:
			set_track(Settings.desired_track()))

func _music_db() -> float:
	if Dev.env("SNUG_NOMUSIC") != "":
		return -80.0   # tanıtım çekimi: yalnız efektler
	return MUSIC_DB + linear_to_db(maxf(music_volume, 0.001))

## Müzik sesi (0 → durur). Settings çağırır.
func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	if _fade and _fade.is_running():
		return
	_music.volume_db = _music_db()
	if music_volume <= 0.001:
		_music.stop()
	elif track != "" and not _music.playing and Dev.env("SNUG_MUTE") == "":
		_music.play()

## Parçayı değiştir (calm | zen); aynıysa bir şey yapmaz. 0.8 sn çapraz geçiş.
func set_track(name: String) -> void:
	if not TRACKS.has(name):
		name = "calm"
	if name == track:
		return
	track = name
	var st := load(TRACKS[name]) as AudioStream
	if st == null:
		return
	if st is AudioStreamMP3:
		(st as AudioStreamMP3).loop = true
	if Dev.env("SNUG_MUTE") != "" or music_volume <= 0.001:
		_music.stream = st
		return
	var old := _music
	_music = _music_b
	_music_b = old
	_music.stream = st
	_music.volume_db = -60.0
	_music.play()
	if _fade:
		_fade.kill()
	_fade = create_tween().set_parallel()
	_fade.tween_property(_music, "volume_db", _music_db(), 0.8)
	if old.playing:
		_fade.tween_property(old, "volume_db", -60.0, 0.8)
		_fade.chain().tween_callback(old.stop)

func play(name: String, pitch := 1.0, vol_db := 0.0, jitter := 0.04) -> void:
	if not _streams.has(name) or Dev.env("SNUG_MUTE") != "":
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL
	p.stream = _streams[name]
	p.pitch_scale = pitch * randf_range(1.0 - jitter, 1.0 + jitter)
	p.volume_db = vol_db + linear_to_db(maxf(sfx_volume, 0.001))
	p.play()

var _voice: AudioStreamPlayer
var _voice_cache := {}

## Kısa seslendirme (övgü kelimeleri): res://audio/voice/<dil>/<anahtar>.ogg|.wav varsa çalar.
## Yoksa sessizce false döner (çağıran normal efektle devam eder). Aynı anda tek ses (yenisi keser).
func voice(key: String) -> bool:
	if Dev.env("SNUG_MUTE") != "" or sfx_volume <= 0.001:
		return false
	var lang := TranslationServer.get_locale().substr(0, 2)
	var ck := lang + "/" + key
	if not _voice_cache.has(ck):
		var st: AudioStream = null
		for ext in ["ogg", "wav", "mp3"]:
			var path := "res://audio/voice/%s/%s.%s" % [lang, key, ext]
			if ResourceLoader.exists(path):
				st = load(path)
				break
		_voice_cache[ck] = st
	var stream: AudioStream = _voice_cache[ck]
	if stream == null:
		return false
	if _voice == null:
		_voice = AudioStreamPlayer.new()
		add_child(_voice)
	_voice.stream = stream
	_voice.volume_db = linear_to_db(maxf(sfx_volume, 0.001))
	_voice.play()
	return true

func note(step: int, name := "place", vol_db := 0.0) -> void:
	play(name, SCALE[clampi(step, 0, SCALE.size() - 1)] * 0.8, vol_db, 0.0)
