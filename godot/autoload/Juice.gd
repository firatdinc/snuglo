extends Node
## Oyun hissi araçları: trauma tabanlı sarsıntı, hit-stop, titreşim.
## Sarsıntı yalnız görsel kökü (shake_root) kaydırır; oyun mantığına dokunmaz.

var shake_root: Node2D
var trauma := 0.0
var reduce_motion := false
var haptics := true
var _t := 0.0

func add_trauma(amount: float) -> void:
	if not reduce_motion:
		trauma = clampf(trauma + amount, 0.0, 1.0)

func _process(dt: float) -> void:
	if shake_root == null or not is_instance_valid(shake_root):
		return
	if trauma <= 0.0:
		shake_root.position = Vector2.ZERO
		shake_root.rotation = 0.0
		return
	trauma = maxf(trauma - 1.6 * dt, 0.0)
	var s := trauma * trauma
	_t += dt * 32.0
	shake_root.position = Vector2(22.0 * s * sin(_t * 1.7), 16.0 * s * sin(_t * 2.3 + 1.0))
	shake_root.rotation = 0.02 * s * sin(_t * 1.1)

func hit_stop(duration := 0.06, scale := 0.05) -> void:
	Engine.time_scale = scale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

## light / medium / heavy / tick
func haptic(kind: String) -> void:
	if not haptics:
		return
	if Engine.has_singleton("SnugloBridge"):
		Engine.get_singleton("SnugloBridge").haptic(kind)
		return
	match kind:
		"tick": Input.vibrate_handheld(8, 0.25)
		"light": Input.vibrate_handheld(12, 0.4)
		"medium": Input.vibrate_handheld(18, 0.65)
		"heavy": Input.vibrate_handheld(35, 1.0)
