extends Node
## Ses: havuzlu oynatıcılar (üst üste sesler birbirini kesmez) + perde varyasyonu.

const POOL := 12
## Pentatonik merdiven: her yerleşim bir sonraki notayı çalar → tahta dolarken melodi yükselir.
const SCALE := [1.0, 1.125, 1.25, 1.5, 1.667, 2.0, 2.25, 2.5, 3.0, 3.333, 4.0, 4.5]

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer
var sfx_volume := 1.0

func _ready() -> void:
	for n in ["click", "combo", "error", "levelUp", "place", "reward", "snap", "solve"]:
		_streams[n] = load("res://audio/sfx/%s.wav" % n)
	for i in POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.stream = load("res://audio/music/bgm.mp3")
	_music.volume_db = -14.0
	add_child(_music)
	if OS.get_environment("SNUG_MUTE") == "":
		_music.play()
	(_music.stream as AudioStreamMP3).loop = true

func play(name: String, pitch := 1.0, vol_db := 0.0, jitter := 0.04) -> void:
	if not _streams.has(name) or OS.get_environment("SNUG_MUTE") != "":
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL
	p.stream = _streams[name]
	p.pitch_scale = pitch * randf_range(1.0 - jitter, 1.0 + jitter)
	p.volume_db = vol_db + linear_to_db(maxf(sfx_volume, 0.001))
	p.play()

func note(step: int, name := "place", vol_db := 0.0) -> void:
	play(name, SCALE[clampi(step, 0, SCALE.size() - 1)] * 0.8, vol_db, 0.0)
