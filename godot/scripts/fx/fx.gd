class_name Fx
extends Node2D
## Hafif parçacık katmanı (tek _draw): toz pufu, konfeti, kıvılcım, yıldız.
## CPUParticles yerine elle: tür başına özel hareket ve tek çizim çağrısı.

enum K { PUFF, CONFETTI, SPARK, RING, THREAD }

var _p: Array = []   # her biri Dictionary

func puff(at: Vector2, n := 6, col := Palette.CREAM, size := 22.0) -> void:
	for i in n:
		var a := randf_range(-PI, 0.0) if randf() < 0.7 else randf_range(0, PI)
		var sp := randf_range(120, 260)
		_p.append({k = K.PUFF, pos = at + Vector2(randf_range(-10, 10), 0), vel = Vector2(cos(a), sin(a) * 0.4) * sp,
			life = 0.0, ttl = randf_range(0.35, 0.55), size = size * randf_range(0.7, 1.3), col = col})

func confetti(at: Vector2, n := 60, spread := PI * 0.6, dir := -PI / 2, speed := 1400.0) -> void:
	for i in n:
		var a := dir + randf_range(-spread, spread)
		var sp := randf_range(0.45, 1.0) * speed
		_p.append({k = K.CONFETTI, pos = at, vel = Vector2(cos(a), sin(a)) * sp, life = 0.0, ttl = randf_range(1.6, 2.6),
			size = randf_range(14, 26), col = Palette.piece(randi()), rot = randf() * TAU, spin = randf_range(-12, 12),
			phase = randf() * TAU})

func sparks(at: Vector2, n := 10, col := Palette.GOLD, speed := 520.0) -> void:
	for i in n:
		var a := randf() * TAU
		_p.append({k = K.SPARK, pos = at, vel = Vector2(cos(a), sin(a)) * randf_range(0.4, 1.0) * speed, life = 0.0,
			ttl = randf_range(0.3, 0.6), size = randf_range(6, 12), col = col})

func ring(at: Vector2, radius := 120.0, col := Palette.CREAM, width := 10.0) -> void:
	_p.append({k = K.RING, pos = at, vel = Vector2.ZERO, life = 0.0, ttl = 0.4, size = radius, col = col, w = width})

func _process(dt: float) -> void:
	if _p.is_empty():
		return
	for i in range(_p.size() - 1, -1, -1):
		var q: Dictionary = _p[i]
		q.life += dt
		if q.life >= q.ttl:
			_p.remove_at(i)
			continue
		match q.k:
			K.PUFF:
				q.vel *= pow(0.02, dt)
			K.CONFETTI:
				q.vel.y += 1500.0 * dt
				q.vel *= pow(0.25, dt)
				q.vel.x += sin(q.life * 9.0 + q.phase) * 260.0 * dt
				q.rot += q.spin * dt
			K.SPARK:
				q.vel *= pow(0.05, dt)
		q.pos += q.vel * dt
	queue_redraw()

func _draw() -> void:
	for q: Dictionary in _p:
		var t: float = q.life / q.ttl
		match q.k:
			K.PUFF:
				draw_circle(q.pos, q.size * (0.6 + t * 0.9), Color(q.col, (1.0 - t) * 0.85))
			K.CONFETTI:
				var flip := absf(sin(q.life * 11.0 + q.phase))
				var s: float = q.size
				draw_set_transform(q.pos, q.rot, Vector2(1.0, 0.25 + flip * 0.75))
				draw_rect(Rect2(-s / 2, -s / 3, s, s * 0.66), Color(q.col, minf(1.0, (1.0 - t) * 3.0)))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			K.SPARK:
				var s: float = q.size * (1.0 - t)
				draw_set_transform(q.pos, PI / 4, Vector2.ONE)
				draw_rect(Rect2(-s / 2, -s / 2, s, s), q.col)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			K.RING:
				var e := 1.0 - pow(1.0 - t, 3.0)
				draw_arc(q.pos, q.size * (0.4 + e * 0.8), 0, TAU, 48, Color(q.col, 1.0 - t), q.w * (1.0 - t) + 1.0, true)
