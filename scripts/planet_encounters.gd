extends Node2D

const MAX_FIELDS := 96
const MAX_MOB_FIELDS := 24
var game: Node2D
var fields: Array[Dictionary] = []
var clock := 0.0

func reset() -> void:
	fields.clear()
	queue_redraw()

func clear_owner(owner: Node) -> void:
	for index in range(fields.size() - 1, -1, -1):
		if fields[index].owner == owner:
			fields.remove_at(index)

func add_field(kind: String, at: Vector2, radius: float, warning: float, duration: float, owner: Node, power: float = 0) -> bool:
	if fields.size() >= (32 if game.mobile_optimized() else MAX_FIELDS):
		return false
	var mob_fields := 0
	for field in fields:
		if field.mob:
			mob_fields += 1
	if not owner.boss and mob_fields >= (8 if game.mobile_optimized() else MAX_MOB_FIELDS):
		return false
	if kind == "blast": radius *= 1.4
	elif kind == "storm": radius *= 1.2
	elif kind == "frost": radius *= 1.15
	var center: Vector2 = game.arena.get_center()
	var point: Vector2 = at.clamp(game.arena.position + Vector2.ONE * 50, game.arena.end - Vector2.ONE * 50)
	var gap_angle := point.direction_to(center).angle()
	if kind == "cage":
		var opening_found := false
		# Choose a real path through the opening, not an opening inside a pillar.
		for attempt in 16:
			var angle := gap_angle + attempt * TAU / 16
			var clear: bool = game.arena.grow(-20).has_point(point + Vector2.RIGHT.rotated(angle) * (radius + 40))
			for step in range(16, int(radius) + 48, 16):
				if game.blocked(point + Vector2.RIGHT.rotated(angle) * step, 15):
					clear = false
					break
			if clear:
				opening_found = true
				gap_angle = angle
				break
		if not opening_found:
			return false
	# Warnings are fixed to their final position; they never track the player.
	fields.append({"kind": kind, "pos": point, "radius": radius, "warning": warning, "age": 0.0, "duration": duration, "owner": owner, "mob": not owner.boss, "power": power, "gap": gap_angle, "triggered": false})
	queue_redraw()
	return true

func super_attack(boss: Node2D, pattern: int) -> void:
	var target: Vector2 = game.player.position
	if boss.god:
		if pattern == 0:
			for i in 9:
				var at: Vector2 = target + Vector2.RIGHT.rotated(i * TAU / 9 + boss.age) * (0 if i == 0 else 95 + i * 17)
				add_field("blast", at, 68, 1.15 + i * .08, .3, boss)
		elif pattern == 1:
			add_field("gravity", boss.position, 420, 1.0, 3.0, boss, 170)
			add_field("cage", target, 145, 1.4, 2.5, boss, 145)
		else:
			for i in 8:
				var at: Vector2 = target + Vector2.RIGHT.rotated(i * TAU / 8) * 160
				add_field("storm", at, 64, 1.15 + i * .1, .3, boss)
		game.play_sfx("boss_alert", boss.position)
		return
	if boss.super_attack_index == 0:
		game.message = ["BOMBARDEIO • saia das marcas e prepare-se para os enxames!", "PRISÃO DE GELO • abertura verde ou dash para escapar!", "GRAVIDADE • use o dash para sair do olho; evite as marcas!"][boss.kind]
		game.message_time = 2.5
	match boss.kind:
		0:
			# Rust bombardment and a finite reinforcement budget.
			if pattern == 1 and game.boss_summon_budget > 0:
				var count := mini(6 + boss.super_phase * 2, game.boss_summon_budget)
				game.pending += ceili(count*game.wave_factor())
				game.boss_summon_budget -= count
				game.fx.floating(boss.position, "ENXAME +%d" % count, Color("ffb676"))
			for i in 4 + boss.super_phase:
				var point: Vector2 = target + Vector2.RIGHT.rotated(i * TAU / (4 + boss.super_phase) + boss.age) * (0 if i == 0 else 90 + i * 14)
				add_field("blast", point, 50 + boss.super_phase * 6, 1.05 + i * .12, .28, boss)
		1:
			# Ice enclosure has an opening facing the arena center; dash crosses it.
			add_field("cage", target, 128, 1.25, 3.0 + boss.super_phase * .3, boss, 135)
			for i in 3 + boss.super_phase:
				var point: Vector2 = target + Vector2.RIGHT.rotated(i * TAU / (3 + boss.super_phase)) * 210
				add_field("frost", point, 58, 1.2 + i * .1, 2.0, boss)
		2:
			# Storm gravity pulls toward a fixed eye, with delayed explosions nearby.
			add_field("gravity", boss.position, 340, 1.1, 2.8, boss, 125 + boss.super_phase * 15)
			for i in 4 + boss.super_phase:
				var point: Vector2 = target + Vector2.RIGHT.rotated(i * TAU / (4 + boss.super_phase)) * (0 if i == 0 else 120 + i * 10)
				add_field("storm", point, 48, 1.35 + i * .12, .25, boss)
	game.play_sfx("frost_warning" if boss.kind == 1 else "boss_alert", boss.position)

func player_force(at: Vector2) -> Vector2:
	var force := Vector2.ZERO
	for field in fields:
		if field.age < field.warning:
			continue
		var distance: float = at.distance_to(field.pos)
		if field.kind == "gravity" and distance < field.radius and distance > 25:
			force += at.direction_to(field.pos) * field.power * (1 - distance / field.radius * .45)
		elif field.kind == "cage" and distance > field.radius - 22 and distance < field.radius + 26:
			if absf(angle_difference((at - field.pos).angle(), field.gap)) > .48:
				force += at.direction_to(field.pos) * field.power
	# Overlapping wells cannot exceed walking speed. Dash ignores these forces.
	return force.limit_length(170)

func movement_multiplier(at: Vector2) -> float:
	for field in fields:
		if field.age >= field.warning and field.kind == "frost" and at.distance_to(field.pos) < field.radius:
			return .62
	return 1.0

func _physics_process(delta: float) -> void:
	if not is_instance_valid(game) or game.state != "playing":
		return
	clock += delta
	for index in range(fields.size() - 1, -1, -1):
		if index >= fields.size():
			continue
		var field: Dictionary = fields[index]
		if not is_instance_valid(field.owner) or field.owner.is_queued_for_deletion():
			fields.remove_at(index)
			continue
		field.age += delta
		if field.age >= field.warning + field.duration:
			fields.remove_at(index)
			continue
		if field.age < field.warning:
			continue
		var color: Color = field_color(field.kind)
		if not field.triggered:
			field.triggered = true
			game.fx.explosion(field.pos, color, 42 if field.mob else 90)
			game.play_sfx("bomb" if field.kind in ["blast", "storm"] else "shield", field.pos)
		var distance: float = game.player.position.distance_to(field.pos)
		if field.kind == "cage":
			if absf(distance - field.radius) < 14 and absf(angle_difference((game.player.position - field.pos).angle(), field.gap)) > .48:
				game.player.hurt(game.enemy_damage())
		elif field.kind == "gravity":
			if distance < 29:
				game.player.hurt(game.enemy_damage())
		elif distance < field.radius:
			game.player.hurt(game.enemy_damage())
	queue_redraw()

func field_color(kind: String) -> Color:
	return Color("ffa362") if kind == "blast" else (Color("91eaff") if kind in ["frost", "cage"] else Color("d3a3ff"))

func _draw() -> void:
	for field in fields:
		var color := field_color(field.kind)
		var active: bool = field.age >= field.warning
		var at: Vector2 = field.pos
		var radius: float = field.radius
		if field.kind == "cage":
			draw_arc(at, radius, field.gap + .48, field.gap + TAU - .48, 48, Color(color, .9 if active else .45), 7 if active else 2)
			for side in [-1, 1]:
				var edge := at + Vector2.RIGHT.rotated(field.gap + side * .48) * radius
				draw_rect(Rect2(edge - Vector2(5, 5), Vector2(10, 10)), Color("71e4c5"))
			for i in 14:
				var angle: float = field.gap + .55 + i * (TAU - 1.1) / 14
				var point := at + Vector2.RIGHT.rotated(angle) * radius
				draw_line(point, point + Vector2(0, -18 if active else -8), color, 3)
		elif field.kind == "gravity":
			for ring in 4:
				var r := radius * fposmod(1 - clock * .35 + ring * .25, 1)
				draw_arc(at, r, clock + ring, clock + ring + TAU * .8, 36, Color(color, .22 if active else .1), 2)
			draw_circle(at, 26, Color(color, .7 if active else .3))
		else:
			draw_circle(at, radius, Color(color, .26 if active else .075))
			draw_arc(at, radius, 0, TAU, 32, color, 4 if active else 2)
			if not active:
				draw_arc(at, radius * clampf(field.age / field.warning, .05, 1), 0, TAU, 28, Color(color, .7), 2)
				draw_line(at - Vector2(9, 0), at + Vector2(9, 0), color, 2)
				draw_line(at - Vector2(0, 9), at + Vector2(0, 9), color, 2)
			else:
				for i in 12:
					var direction := Vector2.RIGHT.rotated(i * TAU / 12 + clock * 2)
					draw_line(at + direction * radius * .25, at + direction * radius, color, 3)
