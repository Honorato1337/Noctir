extends Node2D

const Vfx = preload("res://scripts/pixel_effects.gd")
const MAX_PARTICLES := 600
var particles: Array[Dictionary] = []
var labels: Array[Dictionary] = []
var shake := 0.0
var game: Node2D
var quality := 1.0
var frame_time := 1.0 / 60.0
var quality_clock := 0.0
var emission_frame := -1
var emitted := 0
var emission_remainder := 0.0

func visible_bounds() -> Rect2:
	return get_global_transform_with_canvas().affine_inverse() * get_viewport_rect().grow(96)

func sparks(at: Vector2, color: Color, count: int = 10, power: float = 140.0, kind: int = 0) -> void:
	var mobile: bool = is_instance_valid(game) and game.mobile_optimized()
	if not is_instance_valid(game) or not visible_bounds().has_point(at): return
	var frame := Engine.get_process_frames()
	if emission_frame != frame:
		emission_frame = frame
		emitted = 0
	var budget := 96 if mobile else int(MAX_PARTICLES * quality)
	var frame_budget := 16 if mobile else int(96 * quality)
	if particles.size() >= budget or emitted >= frame_budget: return
	emission_remainder += maxi(0, count) * (0.12 if mobile else 0.65) * quality
	var amount := mini(int(emission_remainder), mini(budget - particles.size(), frame_budget - emitted))
	emission_remainder -= floorf(emission_remainder)
	emitted += amount
	for i in amount:
		var angle: float = game.rng.randf() * TAU
		var life: float = game.rng.randf_range(0.2, 0.65)
		particles.append({"pos": at, "vel": Vector2.RIGHT.rotated(angle) * game.rng.randf_range(power * 0.3, power), "color": color, "life": life, "max": life, "size": game.rng.randi_range(2, 5), "kind": kind})

func explosion(at: Vector2, color: Color, count: int = 30) -> void:
	sparks(at, color, count, 240, 3 if color.r >= color.b else 2)
	shake = maxf(shake, 3.5 if count < 80 else 7.0)

func floating(at: Vector2, text: String, color: Color) -> void:
	if labels.size() < (8 if is_instance_valid(game) and game.mobile_optimized() else 32):
		labels.append({"pos": at, "text": text, "color": color, "life": 0.65})

func _process(delta: float) -> void:
	if not is_instance_valid(game) or game.state not in ["playing", "cleared", "exit"]:
		if is_instance_valid(game):
			game.get_node("Camera2D").offset = Vector2.ZERO
		return
	# Adjust decorative density slowly; attacks and their warnings are independent.
	frame_time = lerpf(frame_time, minf(delta, 0.1), 0.05)
	quality_clock += delta
	if quality_clock >= 1.5:
		quality_clock = 0
		if frame_time > 1.0 / 45.0:
			quality = maxf(0.3, quality - 0.2)
		elif frame_time < 1.0 / 57.0:
			quality = minf(1.0, quality + 0.1)
	var bounds := visible_bounds()
	for index in range(particles.size() - 1, -1, -1):
		var particle: Dictionary = particles[index]
		particle.life -= delta
		particle.pos += particle.vel * delta
		particle.vel *= maxf(0, 1.0 - delta * 3)
		if particle.life <= 0 or not bounds.has_point(particle.pos):
			particles[index] = particles.back()
			particles.pop_back()
	for index in range(labels.size() - 1, -1, -1):
		labels[index].life -= delta
		labels[index].pos.y -= delta * 35
		if labels[index].life <= 0:
			labels[index] = labels.back()
			labels.pop_back()
	shake = move_toward(shake, 0, delta * 14)
	game.get_node("Camera2D").offset = Vector2(sin(Time.get_ticks_msec() * 0.07), cos(Time.get_ticks_msec() * 0.09)) * shake
	queue_redraw()

func _draw() -> void:
	for particle in particles:
		var color: Color = particle.color
		color.a = minf(particle.life / particle.max * 1.7, 1)
		var frame := clampi(int((1-particle.life/particle.max)*4), 0, 3)
		Vfx.draw_particle(self, particle.pos, Vector2.ONE * (particle.size*3+10), int(particle.get("kind",0)), frame, color)
	if is_instance_valid(game):
		for label in labels:
			draw_string(game.font, label.pos, label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(label.color, minf(label.life * 3, 1)))
