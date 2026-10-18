extends Node2D

const Vfx = preload("res://scripts/pixel_effects.gd")
const MAX_STRIKES := 48
const AMBIENT_PARTICLES := 180
var game: Node2D
var rng := RandomNumberGenerator.new()
var event := ""
var active := false
var age := 0.0
var wait := 0.0
var warning := 2.0
var duration := 13.0
var pulse := 0.0
var sound_cd := 0.0
var vortices: Array[Dictionary] = []
var strikes: Array[Dictionary] = []
var motes: Array[Vector2] = []

func reset_room() -> void:
	rng.seed = game.rng.randi()
	clear_active(rng.randf_range(8, 13))
	motes.clear()
	for i in AMBIENT_PARTICLES:
		motes.append(Vector2(rng.randf_range(0, game.arena.size.x), rng.randf_range(0, game.arena.size.y)))

func clear_active(delay: float = 8.0) -> void:
	active = false
	event = ""
	age = 0
	wait = delay
	vortices.clear()
	strikes.clear()
	queue_redraw()

func random_point() -> Vector2:
	return Vector2(rng.randf_range(game.arena.position.x + 75, game.arena.end.x - 75), rng.randf_range(game.arena.position.y + 75, game.arena.end.y - 75))

func start_event() -> void:
	clear_active()
	event = ["sand", "ice", "jupiter", "chaos"][game.planet_index]
	active = true
	warning = 2.0
	duration = 19.0 if event == "chaos" else rng.randf_range(12, 16)
	pulse = warning
	sound_cd = 0
	var names := {"sand": "TEMPESTADE DE AREIA / evite o núcleo e use o dash!", "ice": "CHUVA DE GELO / saia das marcas azuis!", "jupiter": "TEMPESTADE DE JÚPITER / vórtice vermelho e raios!", "chaos": "CAOS TOTAL / areia, gelo, raios e meteoros!"}
	game.message = names[event]
	game.message_time = 3
	game.play_sfx("frost_warning" if event == "ice" else "boss_alert")
	if event in ["sand", "jupiter", "chaos"]:
		for i in (2 if event == "chaos" else 1):
			var point := random_point()
			for attempt in 12:
				if point.distance_to(game.player.position) >= 300 and not game.blocked(point, 70): break
				point = random_point()
			vortices.append({"pos": point, "velocity": Vector2.RIGHT.rotated(rng.randf_range(0, TAU)) * (75 if event == "jupiter" else 62), "radius": 270.0 if event == "jupiter" else 235.0, "core": 72.0 if event == "jupiter" else 62.0})
	queue_redraw()

func add_strike(kind: String, at: Vector2) -> void:
	if strikes.size() >= MAX_STRIKES: return
	strikes.append({"kind": kind, "pos": at.clamp(game.arena.position + Vector2.ONE * 50, game.arena.end - Vector2.ONE * 50), "age": 0.0, "warning": 1.35 if kind == "meteor" else 1.1, "duration": 0.32, "radius": 68.0 if kind == "meteor" else (48.0 if kind == "lightning" else 35.0), "hit": false})

func player_force(at: Vector2) -> Vector2:
	if not active or age < warning: return Vector2.ZERO
	var result := Vector2.ZERO
	for vortex in vortices:
		var offset: Vector2 = vortex.pos - at
		var distance := offset.length()
		if distance > 1 and distance < vortex.radius:
			var toward := offset.normalized()
			result += toward * 115 * (1 - distance / vortex.radius * 0.4)
			if event == "jupiter": result += toward.rotated(PI / 2) * 75
	return result.limit_length(150)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(game) or game.state != "playing": return
	if not active:
		wait -= delta
		if wait <= 0: start_event()
		return
	age += delta
	sound_cd -= delta
	if age >= warning + duration:
		clear_active(rng.randf_range(9, 15) if game.planet_index == 3 else rng.randf_range(13, 21))
		return
	if age >= warning:
		var bounds: Rect2 = game.arena.grow(-80)
		for vortex in vortices:
			var next: Vector2 = vortex.pos + vortex.velocity * delta
			if next.x < bounds.position.x or next.x > bounds.end.x: vortex.velocity.x *= -1
			if next.y < bounds.position.y or next.y > bounds.end.y: vortex.velocity.y *= -1
			vortex.pos = (vortex.pos + vortex.velocity * delta).clamp(bounds.position, bounds.end)
			if game.player.position.distance_to(vortex.pos) < vortex.core:
				game.player.hurt(game.enemy_damage())
				if game.state != "playing": return
		pulse -= delta
		if pulse <= 0:
			pulse = (1.15 if event == "jupiter" else 0.85) / float(game.difficulty().waves)
			if event in ["ice", "jupiter", "chaos"]:
				var kind := "lightning" if event == "jupiter" else "ice"
				var count := (9 if event == "chaos" else 6)
				count = maxi(3, ceili(count * float(game.difficulty().waves)))
				for i in count:
					if event == "chaos": kind = ["ice", "lightning", "meteor"][i % 3]
					add_strike(kind, game.player.position if i == 0 else random_point())
	for index in range(strikes.size() - 1, -1, -1):
		if index >= strikes.size(): continue
		var strike: Dictionary = strikes[index]
		strike.age += delta
		if strike.age >= strike.warning + strike.duration:
			strikes.remove_at(index)
			continue
		if strike.age < strike.warning: continue
		if not strike.hit:
			strike.hit = true
			game.fx.sparks(strike.pos, strike_color(strike.kind), 12, 110)
			if sound_cd <= 0:
				game.play_sfx("bomb" if strike.kind == "meteor" else "shield", strike.pos)
				sound_cd = 0.18
		if game.player.position.distance_to(strike.pos) < strike.radius:
			game.player.hurt(game.enemy_damage())
			if game.state != "playing": return
	queue_redraw()

func strike_color(kind: String) -> Color:
	return Color("ffab70") if kind == "meteor" else (Color("f3c4ff") if kind == "lightning" else Color("91eaff"))

func _draw() -> void:
	if not active or not is_instance_valid(game) or game.state not in ["playing", "paused", "death"]: return
	var armed := age >= warning
	var sand := event in ["sand", "chaos"]
	for i in motes.size():
		var drift := Vector2(age * (135 if sand else 45), age * (30 if sand else 260))
		var at: Vector2 = game.arena.position + Vector2(fposmod(motes[i].x + drift.x, game.arena.size.x), fposmod(motes[i].y + drift.y, game.arena.size.y))
		var color := Color(0.95, 0.63, 0.32, 0.5) if sand else Color(0.65, 0.86, 1, 0.35)
		Vfx.draw_particle(self, at, Vector2.ONE*12, 1 if sand else 2, (i+int(age*5))%4, Color(1,1,1,0.55))
	for vortex in vortices:
		var color := Color("e9aa63") if event != "jupiter" else Color("ef997e")
		draw_arc(vortex.pos, vortex.radius, 0, TAU, 48, Color(color, 0.25), 2)
		draw_circle(vortex.pos, vortex.core, Color(color, 0.23 if armed else 0.06))
		draw_arc(vortex.pos, vortex.core, 0, TAU, 28, Color(color, 0.95 if armed else 0.55), 3)
		for i in 72:
			var angle: float = i * 2.39996 + age * (1.6 + (i % 3) * 0.3)
			var radius: float = vortex.core * (0.2 + float(i % 11) / 11 * 1.25)
			var at: Vector2 = vortex.pos + Vector2.RIGHT.rotated(angle) * radius
			Vfx.draw_particle(self, at, Vector2.ONE*13, 1, (i+int(age*8))%4, Color(1,1,1,0.8 if armed else 0.3))
		draw_string(game.font, vortex.pos + Vector2(-32, -vortex.core - 12), "PERIGO" if armed else "ALERTA", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, color)
	for strike in strikes:
		var color := strike_color(strike.kind)
		var impact: bool = strike.age >= strike.warning
		var at: Vector2 = strike.pos
		draw_circle(at, strike.radius, Color(color, 0.22 if impact else 0.06))
		draw_arc(at, strike.radius, 0, TAU, 24, color, 3 if impact else 2)
		if not impact:
			draw_arc(at, strike.radius * clampf(strike.age / strike.warning, 0.05, 1), 0, TAU, 24, Color(color, 0.6), 2)
			draw_line(at - Vector2(7, 0), at + Vector2(7, 0), color, 2)
			draw_line(at - Vector2(0, 7), at + Vector2(0, 7), color, 2)
			var falling: Vector2 = at + Vector2(30, -150) * (1 - strike.age / strike.warning)
			Vfx.draw_particle(self, falling, Vector2(26,30), 3 if strike.kind == "meteor" else 2, 0)
		elif strike.kind == "lightning":
			var points := PackedVector2Array([at + Vector2(0, -100), at + Vector2(-14, -65), at + Vector2(10, -58), at + Vector2(-10, -24), at])
			draw_polyline(points, color, 5)
		else:
			for i in 8:
				var direction := Vector2.RIGHT.rotated(i * TAU / 8)
				draw_line(at + direction * 8, at + direction * strike.radius, color, 3)
