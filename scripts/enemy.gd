extends Node2D

const Names = preload("res://scripts/enemy_names.gd")

var visual_tick := 0.0
var obstruction_tick := 0.0
var cached_obstructed := false
var separation_tick := 0.0
var cached_separation := Vector2.ZERO
var attack_visual_time := 0.0
var final_spin_time := 0.0
var final_rotation := 0.0
var final_dashing := false
@onready var jupiter_visual: AnimatedSprite2D = $JupiterVisual
@onready var jupiter_boss_visual: AnimatedSprite2D = $JupiterBossVisual
@onready var jupiter_super_visual: AnimatedSprite2D = $JupiterSuperVisual
@onready var final_visual: AnimatedSprite2D = $FinalVisual

var game: Node2D
var kind := 0
var jupiter_role := 0
var storm_windup := 0.0
var storm_aim := Vector2.RIGHT
var charge_trail_cd := 0.0
var boss := false
var superboss := false
var god := false
var shield := 0.0
var max_shield := 0.0
var boss_warning := false
var boss_dash_cycle := -1
var boss_locked_dir := Vector2.RIGHT
var super_phase := 1
var super_attack_timer := 1.8
var super_telegraph := 0.0
var super_attack_index := 0
var super_aim := Vector2.RIGHT
var super_followups: Array[Dictionary] = []
var super_gap_angle := 0.0
var super_aura_timer := 0.0
var health := 3.0
var max_health := 3.0
@export var speed := 75.0
@export var radius := 14.0
@export var use_placeholder_graphics := true
var age := 0.0
var shot_cd := 2.0
var hit_flash := 0.0
var charge_dir := Vector2.ZERO
var charge_phase := 0.0
var route_clock := 0.0
var route_points := PackedVector2Array()
@onready var neptune_super_visual: AnimatedSprite2D = $NeptuneSuperVisual
@onready var neptune_boss_visual: AnimatedSprite2D = $NeptuneBossVisual
@onready var neptune_visual: AnimatedSprite2D = $NeptuneVisual
@onready var mars_visual: AnimatedSprite2D = $MarsVisual
@onready var mars_boss_visual: AnimatedSprite2D = $MarsBossVisual
@onready var mars_super_visual: AnimatedSprite2D = $MarsSuperVisual

func _ready() -> void:
	update_visual()

func _process(_delta: float) -> void:
	if is_instance_valid(game) and game.mobile_optimized():
		visual_tick += _delta
		if visual_tick < 1.0/30: return
		visual_tick = 0
	update_visual()

func update_visual() -> void:
	# Transform only artwork; movement, warnings and collision keep world axes.
	var pulse := sin(age*7)
	mars_visual.scale = Vector2(2*(1+.07*pulse),2*(1-.07*pulse))
	mars_visual.position.y = -absf(pulse)*3
	mars_boss_visual.rotation = sin(age*3)*.04
	mars_boss_visual.scale = Vector2(3,3*(1+.035*sin(age*4)))
	mars_super_visual.scale = Vector2(2*(1+.05*sin(age*5)),2*(1-.07*sin(age*5)))
	neptune_visual.position.y = -4-sin(age*4)*5
	neptune_visual.rotation = sin(age*3)*.08
	neptune_boss_visual.position.y = -absf(sin(age*4))*7
	neptune_boss_visual.rotation = sin(age*3)*.05
	neptune_super_visual.position.y = -absf(sin(age*6))*9
	neptune_super_visual.rotation = sin(age*6)*.035
	jupiter_visual.rotation = age*9 if jupiter_role == 0 and charge_phase >= 1.95 else sin(age*3)*.06
	jupiter_visual.position.y = -absf(sin(age*4))*3
	jupiter_visual.visible = kind == 2 and not boss and not god
	if jupiter_visual.visible:
		jupiter_visual.modulate = Color(2,2,2) if hit_flash > 0 else Color.WHITE
		# Scripted frames line up with the windup and release, including on pause.
		var charging: bool = jupiter_role == 0 and charge_phase >= 1.35
		if storm_windup > 0 or charging or attack_visual_time > 0:
			jupiter_visual.animation = &"attack"
			jupiter_visual.frame = 0 if storm_windup > 0 or (charging and charge_phase < 1.95) else (1 if charging or attack_visual_time > .15 else 2)
		else:
			jupiter_visual.animation = &"idle"
			jupiter_visual.frame = 0
		jupiter_visual.pause()
	update_jupiter_boss_visual()
	final_visual.visible = god
	if final_visual.visible:
		final_visual.modulate = Color(2,2,2) if hit_flash > 0 else Color.WHITE
		final_visual.rotation = final_rotation
		if is_instance_valid(game) and game.state == "playing": final_visual.play(&"walk")
		else: final_visual.pause()
	else: final_visual.pause()
	neptune_super_visual.visible = kind == 1 and superboss and not god
	if neptune_super_visual.visible and is_instance_valid(game):
		neptune_super_visual.modulate = Color(2,2,2) if hit_flash > 0 else Color.WHITE
		neptune_super_visual.flip_h = game.player.position.x < position.x
		if game.state == "playing": neptune_super_visual.play(&"walk")
		else: neptune_super_visual.pause()
	else: neptune_super_visual.pause()
	neptune_boss_visual.visible = kind == 1 and boss and not superboss
	if neptune_boss_visual.visible and is_instance_valid(game):
		neptune_boss_visual.modulate = Color(2,2,2) if hit_flash > 0 else Color.WHITE
		neptune_boss_visual.flip_h = game.player.position.x < position.x
		if game.state == "playing": neptune_boss_visual.play(&"walk")
		else: neptune_boss_visual.pause()
	else: neptune_boss_visual.pause()
	neptune_visual.visible = kind == 1 and not boss
	if neptune_visual.visible and is_instance_valid(game):
		neptune_visual.modulate = Color(2,2,2) if hit_flash > 0 else Color.WHITE
		neptune_visual.flip_h = game.player.position.x < position.x
		if game.state == "playing": neptune_visual.play(&"walk")
		else: neptune_visual.pause()
	else: neptune_visual.pause()
	mars_super_visual.visible = kind == 0 and superboss and not god
	if mars_super_visual.visible and is_instance_valid(game):
		mars_super_visual.modulate = Color(2, 2, 2) if hit_flash > 0 else Color.WHITE
		mars_super_visual.flip_h = game.player.position.x < position.x
		if game.state == "playing":
			mars_super_visual.play(&"walk")
		else:
			mars_super_visual.pause()
	else:
		mars_super_visual.pause()
	mars_boss_visual.visible = kind == 0 and boss and not superboss
	if mars_boss_visual.visible and is_instance_valid(game):
		mars_boss_visual.modulate = Color(2, 2, 2) if hit_flash > 0 else Color.WHITE
		mars_boss_visual.flip_h = game.player.position.x < position.x
		if game.state == "playing":
			mars_boss_visual.play(&"walk")
		else:
			mars_boss_visual.pause()
	else:
		mars_boss_visual.pause()
	mars_visual.visible = kind == 0 and not boss
	if not mars_visual.visible or not is_instance_valid(game):
		mars_visual.pause()
		return
	mars_visual.modulate = Color(2, 2, 2) if hit_flash > 0 else Color.WHITE
	if is_instance_valid(game.player):
		mars_visual.flip_h = game.player.position.x < position.x
	if game.state == "playing":
		mars_visual.play(&"walk")
	else:
		mars_visual.pause()

func update_jupiter_boss_visual() -> void:
	jupiter_boss_visual.visible = kind == 2 and boss and not superboss and not god
	jupiter_super_visual.visible = kind == 2 and superboss and not god
	var dashing := boss and not boss_warning and fmod(age, 3.2) >= 2.55
	for sprite: AnimatedSprite2D in [jupiter_boss_visual, jupiter_super_visual]:
		if not sprite.visible:
			sprite.pause()
			continue
		# Use combat time for animation: pause freezes frames and transforms together.
		sprite.frame = int(age * 12) % sprite.sprite_frames.get_frame_count(&"walk")
		sprite.pause()
		sprite.modulate = Color(2, 2, 2) if hit_flash > 0 else Color.WHITE
		var size := 2.9 if superboss else 2.0
		var pulse := sin(age * 6) * (.06 if super_telegraph > 0 else .025)
		sprite.scale = Vector2(size * (1 + pulse), size * (1 - pulse))
		if superboss:
			# Orbiting fragments roll around the core; the windup trembles before release.
			sprite.rotation = age * .65 + (sin(age * 35) * .09 if super_telegraph > 0 else 0.0)
			sprite.position.y = -absf(sin(age * 4.5)) * 7
		else:
			# Segmented armor floats, then tumbles with the charge.
			sprite.rotation = age * 10 if dashing else sin(age * 2.5) * .12
			sprite.position.y = -absf(sin(age * 3.5)) * 5
		if boss_warning:
			sprite.position.y += sin(age * 40) * 2

func _physics_process(delta: float) -> void:
	if not is_instance_valid(game) or game.state != "playing" or is_queued_for_deletion():
		return
	age += delta
	attack_visual_time = maxf(0, attack_visual_time-delta)
	final_spin_time = maxf(0, final_spin_time-delta)
	hit_flash -= delta
	shot_cd -= delta*game.enemy_ability_rate()
	var direction: Vector2 = position.direction_to(game.player.position)
	var distance: float = position.distance_to(game.player.position)
	var chase := direction
	route_clock -= delta
	obstruction_tick -= delta
	if not game.mobile_optimized() or obstruction_tick <= 0:
		obstruction_tick = .2
		cached_obstructed = false
		for step in range(1, int(distance / 16) + 1):
			if game.blocked(position + direction * step * 16, radius + 4):
				cached_obstructed = true
				break
	var obstructed := cached_obstructed
	if obstructed:
		if route_clock <= 0:
			route_points = game.get_node("Arena").route(position, game.player.position, radius)
			route_clock = 0.35
		while not route_points.is_empty() and position.distance_to(route_points[0]) < 18:
			route_points.remove_at(0)
		if not route_points.is_empty():
			chase = position.direction_to(route_points[0])
	var motion := chase * speed
	if kind == 1:
		# Reposition around cover even when already within shooting range.
		motion *= 1.0 if obstructed or distance > 240 else (-0.7 if distance < 150 else 0.0)
	elif kind == 2 and (boss or jupiter_role == 0):
		charge_phase = fmod(age, 2.7)
		if charge_phase < 1.35:
			charge_dir = direction
			motion *= 0.6
		elif charge_phase < 1.95:
			motion = Vector2.ZERO
		else:
			motion = charge_dir * speed * 4.4
			if not boss:
				charge_trail_cd -= delta
				if charge_trail_cd <= 0:
					charge_trail_cd = .4
					game.encounters.add_field("storm", position, 32, .85, .25, self)
	elif kind == 2:
		motion *= 1.0 if obstructed or distance > 270 else (-.6 if distance < 160 else .2)
	if kind == 2 and not boss:
		tick_jupiter_mob(delta, direction)
		if storm_windup > 0:
			motion *= .25
	if boss:
		motion = boss_motion(chase, direction, distance, obstructed)
	if god:
		if final_dashing or final_spin_time > 0:
			final_rotation = wrapf(final_rotation + delta * (TAU * 3 if final_dashing else TAU * 1.5), -PI, PI)
		else:
			final_rotation = rotate_toward(final_rotation, 0, delta * TAU * 2)
	motion *= game.deployables.enemy_slowdown(position, boss)
	# Cache the local separation force on mobile instead of scanning every tick.
	separation_tick -= delta
	if not game.mobile_optimized() or separation_tick <= 0:
		separation_tick = .12
		cached_separation = Vector2.ZERO
		for other in game.enemies.get_children():
			if other == self or other.is_queued_for_deletion(): continue
			var gap: Vector2 = position-other.position
			if gap.length_squared() < pow(radius+other.radius+5,2):
				cached_separation += gap.normalized()*75
	motion += cached_separation
	game.move_actor(self, motion * delta, radius)
	if distance < radius + 13:
		game.player.hurt(game.enemy_damage())
	if superboss:
		tick_superboss(delta)
	if not superboss and (kind == 1 or boss) and shot_cd <= 0:
		shot_cd = maxf(0.75, 1.25 - game.room * 0.03) if boss else 2.4
		if boss:
			var count: int = (16 if health < max_health * 0.5 else 10) + game.planet_index * 2
			for i in count:
				game.shoot(position, Vector2.RIGHT.rotated(TAU * i / count + age * 0.3), 1, true)
			var predicted: Vector2 = game.player.position + game.player.velocity.limit_length(350) * .24
			for angle in [-.08, 0, .08]:
				game.shoot(position, position.direction_to(predicted).rotated(angle), 1, true)
		else:
			for angle in [-0.1, 0.1]:
				game.shoot(position, direction.rotated(angle), 1, true)
	queue_redraw()

func hurt(amount: float) -> void:
	if is_queued_for_deletion():
		return
	if shield > 0:
		var absorbed := minf(shield, amount)
		shield -= absorbed
		amount -= absorbed
		game.fx.sparks(position, Color("91eaff"), 8, 140)
		if shield <= 0:
			game.fx.explosion(position, Color("91eaff"), 70)
			game.fx.floating(position + Vector2(-65, -65), "ESCUDO QUEBRADO", Color("91eaff"))
			game.play_sfx("shield", position)
		if amount <= 0:
			hit_flash = .1
			game.play_sfx("hit", position)
			queue_redraw()
			return
	health -= amount
	game.play_sfx("hit", position)
	hit_flash = 0.10
	game.fx.sparks(position, Color("ffe5a0"), 5, 100)
	game.fx.floating(position + Vector2(-8, -20), str(snappedf(amount, 0.1)), Color("fff1b8"))
	if health <= 0:
		game.contracts.record("kill")
		if boss:
			game.contracts.record("boss")
		if superboss:
			game.contracts.record("superboss")
			game.reward_planet_superboss()
		game.encounters.clear_owner(self)
		game.kills += 1
		game.phase_kills += 1
		game.score += 1000 if superboss else (500 if boss else 50)
		game.play_sfx("bomb" if boss else "enemy_down", position)
		game.burst(position, game.planet().enemy)
		game.loot.enemy_died(position, boss)
		game.fx.explosion(position, game.planet().enemy, 100 if boss else 22)
		queue_free()

func tick_jupiter_mob(delta: float, direction: Vector2) -> void:
	if storm_windup > 0:
		storm_windup -= delta
		if storm_windup <= 0:
			attack_visual_time = .3
			if jupiter_role == 2:
				game.encounters.add_field("gravity", position, 210, .8, 2.4, self, 130)
			for i in (3 if jupiter_role == 2 else 5):
				if game.bullets.get_child_count() >= game.projectile_limit():
					break
				var count := 3 if jupiter_role == 2 else 5
				game.shoot(position, storm_aim.rotated((i - (count - 1) * .5) * .13), 1, true)
			game.fx.sparks(position, Color("d3a3ff"), 16, 130)
			shot_cd = 4.5 if jupiter_role == 2 else 2.2
	elif shot_cd <= 0 and jupiter_role != 0:
		storm_windup = .7
		storm_aim = direction
		game.fx.sparks(position, Color("fff0ac"), 8, 60)

func superboss_name() -> String:
	return Names.name_for(kind, true, true, god, jupiter_role)

func boss_motion(chase: Vector2, direction: Vector2, distance: float, obstructed: bool) -> Vector2:
	final_dashing = false
	var period: float = 2.7 if god else [3.5, 4.0, 3.2][kind]
	var phase := fmod(age, period)
	var cycle := floori(age / period)
	var warning_start := period - 1.3
	var dash_start := period - .65
	boss_warning = phase >= warning_start and phase < dash_start
	if boss_warning:
		if boss_dash_cycle != cycle:
			boss_dash_cycle = cycle
			var predicted: Vector2 = game.player.position + game.player.velocity.limit_length(350) * .28
			boss_locked_dir = position.direction_to(predicted)
			if kind == 1:
				boss_locked_dir = direction.rotated(PI / 2 * (-1 if cycle % 2 else 1))
		return Vector2.ZERO
	if phase >= dash_start:
		final_dashing = god
		return boss_locked_dir * (880 if god else (680 if kind == 1 else 760))
	if obstructed:
		return chase * speed
	if kind == 1 or god:
		var orbit := direction.rotated(PI / 2 * (-1 if cycle % 2 else 1)) * speed * .8
		return orbit + direction * (speed if distance > 330 else (-speed if distance < 210 else 0))
	if kind == 2:
		var predicted: Vector2 = game.player.position + game.player.velocity.limit_length(350) * .35
		return position.direction_to(predicted) * speed * 1.2
	return chase * speed

func tick_superboss(delta: float) -> void:
	var phase := 3 if health < max_health * 0.25 else (2 if health < max_health * 0.55 else 1)
	if phase != super_phase:
		super_phase = phase
		game.message = "%s • FASE %d" % [superboss_name(), phase]
		game.message_time = 2.5
		game.pending += ceili(8*game.wave_factor())
		game.encounters.clear_owner(self)
		super_followups.clear()
		super_telegraph = 0
		super_attack_timer = 1.2
		if god:
			shield = maxf(shield, max_shield * .35)
		# A short break in projectiles makes the new phase readable.
		for bullet in game.bullets.get_children():
			if bullet.hostile:
				bullet.queue_free()
		game.fx.explosion(position, game.planet().accent, 100)
		game.play_sfx("boss_alert")
	# Cosmetic corona and satellites are visually dense but never cause damage.
	super_aura_timer -= delta
	if super_aura_timer <= 0:
		super_aura_timer = 0.12
		var satellites := 3 if game.mobile_optimized() else 8
		for i in satellites:
			var at := position + Vector2.RIGHT.rotated(age + i * TAU / satellites) * (radius + 24)
			game.fx.sparks(at, game.planet().accent, 3, 85)
	for index in range(super_followups.size() - 1, -1, -1):
		super_followups[index].delay -= delta
		if super_followups[index].delay <= 0:
			var salvo: Dictionary = super_followups[index]
			super_followups.remove_at(index)
			fire_super_layer(salvo.pattern, salvo.layer)
	if super_telegraph > 0:
		super_telegraph -= delta
		if super_telegraph <= 0:
			fire_super_attack()
			super_attack_index += 1
			super_attack_timer = 2.2 - super_phase * 0.25
	else:
		super_attack_timer -= delta*game.enemy_ability_rate()
		if super_attack_timer <= 0:
			super_telegraph = 0.9
			super_aim = position.direction_to(game.player.position + game.player.velocity.limit_length(350) * .25)
			super_gap_angle = super_aim.angle() + 0.7
			game.fx.sparks(position, game.planet().accent, 24, 75)

func fire_super_attack() -> void:
	var pattern := super_attack_index % 3
	if god and pattern != 1: final_spin_time = .65
	game.encounters.super_attack(self, pattern)
	fire_super_layer(pattern, 0)
	for layer in range(1, super_phase + 1):
		super_followups.append({"delay": layer * 0.24, "pattern": pattern, "layer": layer})
	game.fx.sparks(position, game.planet().accent, 100, 220)

func fire_super_layer(pattern: int, layer: int) -> void:
	match pattern:
		0:
			var count := 32 + super_phase * 8
			for i in count:
				var angle := i * TAU / count + layer * 0.09
				# All layers share a generous safe corridor, shown during the warning.
				if absf(angle_difference(angle, super_gap_angle)) > 0.30:
					super_shard(Vector2.RIGHT.rotated(angle), 130 + super_phase * 12 + layer * 5)
		1:
			for side in [-1, 1]:
				for i in 7 + super_phase * 2:
					var direction := super_aim.rotated((i - (6 + super_phase * 2) / 2.0) * 0.11 + side * 0.48)
					super_shard(direction, 155 + layer * 8, Vector2(-super_aim.y, super_aim.x) * side * 65)
		2:
			for arm in 6:
				for i in super_phase + 2:
					super_shard(Vector2.RIGHT.rotated(arm * TAU / 6 + super_gap_angle + layer * 0.13 + (i - (super_phase + 1) / 2.0) * 0.10), 145 + layer * 10)
	game.fx.sparks(position, game.planet().accent, 40, 150)

func super_shard(direction: Vector2, velocity: float, offset: Vector2 = Vector2.ZERO) -> void:
	if game.bullets.get_child_count() >= game.projectile_limit():
		return
	var bullet = game.shoot(position + offset + direction * (radius - 20), direction, 1, true)
	if bullet == null: return
	bullet.velocity = direction * velocity*1.18
	bullet.radius = 5
	bullet.life = 3.5

func _draw() -> void:
	if not use_placeholder_graphics or not is_instance_valid(game):
		return
	var color: Color = Color.WHITE if hit_flash > 0 else (game.planet().enemy if god else game.Planets.DATA[mini(kind, 2)].enemy)
	draw_circle(Vector2(0, 8), radius + 2, Color(0, 0, 0, 0.25))
	var sprite_body := kind == 0 or (kind == 1 and not god) or kind == 2 or god
	if sprite_body:
		pass
	elif god:
		var points := PackedVector2Array()
		for i in 12:
			points.append(Vector2.RIGHT.rotated(i * TAU / 12 - PI / 2) * radius * (1.5 if i % 2 == 0 else .7))
		draw_colored_polygon(points, Color("d6b2ff"))
		for i in 8:
			var at := Vector2.RIGHT.rotated(age * .6 + i * TAU / 8) * (radius + 35)
			draw_circle(at, 7, Color("ffe5a0"))
	elif kind == 0:
		for i in 6:
			var point := Vector2.RIGHT.rotated(TAU * i / 6) * radius
			draw_line(point * 0.7, point * 1.5 + Vector2(0, sin(age * 10 + i) * 3), color, 3)
		draw_circle(Vector2.ZERO, radius, color)
	elif kind == 1:
		for i in 4:
			var point := Vector2.RIGHT.rotated(i * PI / 2) * radius * 1.2
			draw_rect(Rect2(point.snapped(Vector2(2, 2)) - Vector2(3, 3), Vector2(6, 6)), color)
		var points := PackedVector2Array([Vector2(0, -radius), Vector2(radius * 0.7, -radius * 0.7), Vector2(radius, 0), Vector2(radius * 0.7, radius * 0.7), Vector2(0, radius), Vector2(-radius * 0.7, radius * 0.7), Vector2(-radius, 0), Vector2(-radius * 0.7, -radius * 0.7)])
		draw_colored_polygon(points, color)
		draw_line(Vector2(-radius * 0.6, 0), Vector2(radius * 0.6, 0), Color("e3fcff"), 2)
	else:
		draw_rect(Rect2(Vector2(-radius, -radius), Vector2.ONE * radius * 2), color)
		if not boss and jupiter_role == 1:
			draw_line(Vector2(-radius, 0), Vector2(radius, 0), Color("fff0ac"), 4)
		elif not boss and jupiter_role == 2:
			draw_arc(Vector2.ZERO, radius + 7, age, age + TAU * .85, 20, Color("87e8ff"), 3)
		if storm_windup > 0:
			draw_line(Vector2.ZERO, storm_aim * 250, Color(1, .7, .9, .65), 2)
		if charge_phase >= 1.5 and charge_phase < 2.1:
			draw_line(Vector2.ZERO, charge_dir * 150, Color(1, 0.4, 0.5, 0.5), 2)
	if not sprite_body:
		draw_circle(Vector2(0, -2), radius * 0.43, Color("202338"))
		draw_circle(Vector2(3, -4), radius * 0.17, Color("fff1b8"))
	if kind == 2 and not boss:
		if jupiter_role == 1: draw_line(Vector2(-10, radius+4), Vector2(10, radius+4), Color("fff0ac"), 2)
		elif jupiter_role == 2: draw_arc(Vector2.ZERO, radius+7, age, age+TAU*.85, 20, Color("87e8ff"), 2)
		if storm_windup > 0: draw_line(Vector2.ZERO, storm_aim*250, Color(1,.7,.9,.65), 2)
		if jupiter_role == 0 and charge_phase >= 1.35 and charge_phase < 1.95: draw_line(Vector2.ZERO,charge_dir*150,Color(1,.4,.5,.5),2)
	if boss or health < max_health:
		draw_rect(Rect2(-radius, -radius - 13, radius * 2, 4), Color("181828"))
		draw_rect(Rect2(-radius, -radius - 13, radius * 2 * maxf(health / max_health, 0), 4), Color("ff7e8d"))
	if shield > 0:
		draw_arc(Vector2.ZERO, radius + 13, 0, TAU, 40, Color("78dfff"), 4)
		draw_rect(Rect2(-radius, -radius - 20, radius * 2 * shield / max_shield, 4), Color("78dfff"))
	if boss_warning:
		draw_line(Vector2.ZERO, boss_locked_dir * 360, Color(1, .78, .4, .8), 4)
	if superboss:
		for ring in 3:
			draw_arc(Vector2.ZERO, radius + 18 + ring * 14, -age * (ring + 1), -age * (ring + 1) + TAU * 0.72, 32, Color(game.planet().accent, 0.35), 2)
		draw_arc(Vector2.ZERO, radius + 8, age, age + TAU * 0.8, 24, Color(game.planet().accent, 0.8), 3)
		for i in 6:
			var at := Vector2.RIGHT.rotated(age * 0.5 + i * TAU / 6) * (radius + 12)
			draw_rect(Rect2(at.snapped(Vector2(2, 2)) - Vector2(3, 3), Vector2(6, 6)), game.planet().accent)
		if super_telegraph > 0:
			draw_arc(Vector2.ZERO, radius + 16, 0, TAU, 32, Color("fff0ac"), 3)
			if super_attack_index % 3 == 1:
				draw_line(Vector2.ZERO, super_aim * 300, Color(1, 0.9, 0.6, 0.7), 3)
			elif super_attack_index % 3 == 0:
				for side in [-1, 1]:
					draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(super_gap_angle + side * 0.30) * 320, Color(0.45, 1, 0.8, 0.65), 2)

func display_name() -> String:
	return Names.name_for(kind, boss, superboss, god, jupiter_role)
