extends Node2D

const Vfx = preload("res://scripts/pixel_effects.gd")
const MAX_PARTICLES := 1800
var particles: Array[Dictionary] = []
var labels: Array[Dictionary] = []
var shake := 0.0
var game: Node2D

func sparks(at: Vector2, color: Color, count: int = 10, power: float = 140.0, kind: int = 0) -> void:
	var mobile: bool = is_instance_valid(game) and game.mobile_optimized()
	var budget := 300 if mobile else MAX_PARTICLES
	var amount := maxi(1,ceili(count*.25)) if mobile else count
	for i in mini(amount, budget - particles.size()):
		var angle: float = game.rng.randf() * TAU
		var life: float = game.rng.randf_range(0.2, 0.65)
		particles.append({"pos": at, "vel": Vector2.RIGHT.rotated(angle) * game.rng.randf_range(power * 0.3, power), "color": color, "life": life, "max": life, "size": game.rng.randi_range(2, 5), "kind": kind})

func explosion(at: Vector2, color: Color, count: int = 30) -> void:
	sparks(at, color, count, 240, 3 if color.r >= color.b else 2)
	shake = maxf(shake, 3.5 if count < 80 else 7.0)

func floating(at: Vector2, text: String, color: Color) -> void:
	if labels.size() < (20 if is_instance_valid(game) and game.mobile_optimized() else 100):
		labels.append({"pos": at, "text": text, "color": color, "life": 0.65})

func _process(delta: float) -> void:
	if not is_instance_valid(game) or game.state not in ["playing", "cleared", "exit"]:
		if is_instance_valid(game):
			game.get_node("Camera2D").offset = Vector2.ZERO
		return
	for index in range(particles.size() - 1, -1, -1):
		var particle: Dictionary = particles[index]
		particle.life -= delta
		particle.pos += particle.vel * delta
		particle.vel *= maxf(0, 1.0 - delta * 3)
		if particle.life <= 0:
			particles.remove_at(index)
	for index in range(labels.size() - 1, -1, -1):
		labels[index].life -= delta
		labels[index].pos.y -= delta * 35
		if labels[index].life <= 0:
			labels.remove_at(index)
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
