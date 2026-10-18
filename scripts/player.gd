extends Node2D

const Skins = preload("res://scripts/skin_catalog.gd")
var skin_id := "astronaut"
var facing_left := false
var echo_flip_h := false
var game: Node2D
var health := 5
@export_group("Balanceamento")
@export var max_health := 5
@export var speed := 210.0
@export var damage := 1.0
@export var interval := 0.48
@export_group("Visual")
@export var use_placeholder_graphics := false
@onready var visual: AnimatedSprite2D = $Visual
@onready var echo_visual: Sprite2D = $EchoVisual
@onready var weapon: Node2D = $Weapon
@onready var weapon_sprite: Sprite2D = $Weapon/Sprite
@onready var echo_weapon: Node2D = $EchoWeapon
@onready var echo_weapon_sprite: Sprite2D = $EchoWeapon/Sprite
const SHOTGUN_FRAMES = [
	preload("res://assets/gun2/pixil-frame-0.png"),
	preload("res://assets/gun2/pixil-frame-1.png"),
	preload("res://assets/gun2/pixil-frame-2.png"),
	preload("res://assets/gun2/pixil-frame-3.png"),
	preload("res://assets/gun2/pixil-frame-4.png"),
	preload("res://assets/gun2/pixil-frame-5.png"),
	preload("res://assets/gun2/pixil-frame-6.png"),
	preload("res://assets/gun2/pixil-frame-7.png"),
	preload("res://assets/gun2/pixil-frame-8.png"),
	preload("res://assets/gun2/pixil-frame-9.png")
]
var weapon_animation := 0.0
var echo_weapon_frame := 0
var echo_aim := Vector2.RIGHT
var echo_frame := 0
var spread := 0
var cooldown := 0.0
var immunity := 0.0
var dash_cd := 0.0
var dash_time := 0.0
@export var dash_recharge := 1.6
var dash_dir := Vector2.RIGHT
var aim := Vector2.RIGHT
var velocity := Vector2.ZERO
@export var dash_duration := .24
@export var dash_speed := 850.0
var history: Array[Dictionary] = []
var echo_frames: Array[Dictionary] = []
var echo_pos := Vector2.ZERO
var echo_clock := 0.0
var clock := 0.0
var rewind_ready := true
var overdrive_time := 0.0
var trail_cd := 0.0
var pickup_bonus := 0.0
var berserk_time := 0.0

func _ready() -> void:
	health = max_health
	update_animation()

func set_skin(key: String) -> void:
	skin_id = key if Skins.DATA.has(key) else "astronaut"
	visual.sprite_frames = Skins.DATA[skin_id].frames
	visual.play(&"idle")
	visual.flip_h = false
	update_animation()

func _process(_delta: float) -> void:
	if is_instance_valid(game) and game.state == "playing":
		weapon_animation = maxf(0, weapon_animation - _delta)
	update_animation()

func update_animation() -> void:
	if not is_instance_valid(visual) or not is_instance_valid(game):
		return
	var horizontal: float = game.controls.movement().x
	if absf(horizontal) < 0.1: horizontal = aim.x
	if absf(horizontal) >= 0.1: facing_left = horizontal < 0
	visual.flip_h = skin_id == "guanapo" and facing_left
	var active: bool = game.state in ["playing", "cleared", "exit"]
	var blink: bool = game.state == "playing" and immunity > 0 and immunity <= 1.2 and int(clock * 16) % 2 == 0
	visual.visible = not use_placeholder_graphics and not blink
	weapon.visible = not use_placeholder_graphics and not blink
	weapon.rotation = aim.angle()
	weapon.z_index = -1 if aim.y < -0.25 else 1
	weapon_sprite.flip_v = aim.x < 0
	weapon_sprite.texture = SHOTGUN_FRAMES[weapon_frame()]
	if active:
		var moving: bool = game.controls.movement().length_squared() > 0.01 or dash_time > 0
		var animation: StringName = &"walk" if moving else &"idle"
		visual.speed_scale = 1.8 if dash_time > 0 else 1.0
		if visual.animation != animation:
			visual.play(animation)
		elif animation == &"walk" and not visual.is_playing():
			visual.play()
	else:
		visual.pause()
	echo_visual.visible = not use_placeholder_graphics and not echo_frames.is_empty()
	echo_visual.position = echo_pos - position + Vector2(0, -8)
	echo_visual.texture = visual.sprite_frames.get_frame_texture(&"walk", clampi(echo_frame, 0, visual.sprite_frames.get_frame_count(&"walk")-1))
	echo_visual.flip_h = echo_flip_h
	echo_weapon.visible = echo_visual.visible
	echo_weapon.position = echo_pos - position + Vector2(0, 4)
	echo_weapon.rotation = echo_aim.angle()
	echo_weapon.z_index = -1 if echo_aim.y < -0.25 else 1
	echo_weapon_sprite.flip_v = echo_aim.x < 0
	echo_weapon_sprite.texture = SHOTGUN_FRAMES[echo_weapon_frame]

func _physics_process(delta: float) -> void:
	if not is_instance_valid(game) or game.state != "playing":
		return
	clock += delta
	cooldown -= delta
	immunity -= delta
	var dash_was_cooling := dash_cd > 0
	dash_cd -= delta
	if dash_was_cooling and dash_cd <= 0:
		game.play_sfx("dash_ready")
	dash_time -= delta
	overdrive_time = maxf(0, overdrive_time - delta)
	berserk_time = maxf(0, berserk_time - delta)
	if Input.is_action_just_pressed("berserk"):
		game.activate_berserk()
	trail_cd -= delta
	var move: Vector2 = game.controls.movement()
	var keyboard_aim: Vector2 = game.controls.aiming()
	if keyboard_aim != Vector2.ZERO:
		aim = keyboard_aim.normalized()
	elif game.controls.last_device == "keyboard" and not game.controls.touch_enabled() and get_global_mouse_position().distance_to(position) > 4:
		aim = position.direction_to(get_global_mouse_position())
	if Input.is_action_just_pressed("dash") and dash_cd <= 0:
		game.play_sfx("dash", position)
		game.contracts.record("dash")
		dash_dir = move if move != Vector2.ZERO else aim
		dash_time = dash_duration
		dash_cd = dash_recharge
		immunity = maxf(immunity, dash_duration + .08)
	var motion: Vector2 = move * speed * game.frost_slowdown(position) * game.encounters.movement_multiplier(position)
	if dash_time > 0:
		motion = dash_dir * dash_speed
		if trail_cd <= 0:
			game.fx.sparks(position - dash_dir * 12, Color("78d6ff"), 4, 65)
			trail_cd = 0.035
	elif game.planet_index == 1:
		motion += game.neptune_wind()
	elif game.planet_index == 2:
		motion += Vector2(sin(clock * 0.7), cos(clock * 0.5)) * 36
	if dash_time <= 0:
		motion += (game.encounters.player_force(position) + game.weather.player_force(position)).limit_length(170)
	velocity = motion
	game.move_actor(self, motion * delta, 13)
	var shots: Array[Vector2] = []
	if berserk_time > 0 and cooldown <= 0:
		cooldown = .1
		shots = fire_berserk()
	elif (game.controls.wants_fire() or keyboard_aim != Vector2.ZERO) and cooldown <= 0:
		cooldown = interval * (0.45 if overdrive_time > 0 else 1.0)
		shots = fire(position, aim, false)
	# Store every physics frame: exact fire events must survive into the echo.
	history.append({"t": clock, "pos": position, "health": health, "shots": shots, "damage": shot_damage(), "visual_frame": visual.frame, "weapon_frame": weapon_frame(), "flip_h": visual.flip_h, "aim": aim})
	while not history.is_empty() and clock - float(history[0].t) > 5.0:
		history.pop_front()
	if Input.is_action_just_pressed("rewind"):
		rewind()
	if not echo_frames.is_empty():
		echo_clock += delta
		while not echo_frames.is_empty() and float(echo_frames[0].t) <= echo_clock:
			var frame: Dictionary = echo_frames.pop_front()
			echo_pos = frame.pos
			echo_frame = int(frame.get("visual_frame", 0))
			echo_weapon_frame = int(frame.get("weapon_frame", 0))
			echo_flip_h = bool(frame.get("flip_h",false))
			echo_aim = frame.get("aim", aim)
			for direction in frame.shots:
				game.shoot(echo_pos, direction, float(frame.damage), false, true)
	queue_redraw()

func weapon_frame() -> int:
	return clampi(int((0.5 - weapon_animation) * 20), 0, 9) if weapon_animation > 0 else 0

func fire(origin: Vector2, direction: Vector2, is_echo: bool) -> Array[Vector2]:
	if not is_echo:
		game.play_sfx("shot", origin)
		weapon_animation = 0.5
	var directions: Array[Vector2] = [direction, direction.rotated(0.16), direction.rotated(-0.16)]
	for i in range(2, spread + 2):
		directions.append(direction.rotated(i * 0.16))
		directions.append(direction.rotated(-i * 0.16))
	for vector in directions:
		game.shoot(origin, vector, shot_damage(), false, is_echo)
	return directions

func shot_damage() -> float:
	return damage * (1.5 if overdrive_time > 0 else 1.0) * (1.25 if berserk_time > 0 else 1.0)

func fire_berserk() -> Array[Vector2]:
	var directions: Array[Vector2] = []
	for index in 18:
		var direction := Vector2.RIGHT.rotated(index * TAU / 18 + clock * .8)
		directions.append(direction)
		game.shoot(position, direction, shot_damage(), false)
	game.play_sfx("shot", position)
	game.fx.sparks(position, Color("ffad70"), 5, 100)
	return directions

func rewind() -> void:
	if game.state != "playing" or not rewind_ready or history.size() < 60 or (game.run_mode == "endless" and game.echo_cd > 0):
		return
	game.play_sfx("echo", position)
	var first: Dictionary = history[0]
	position = first.pos
	health = maxi(health, int(first.health))
	echo_frames = history.duplicate(true)
	echo_clock = float(first.t)
	echo_pos = first.pos
	echo_frame = int(first.get("visual_frame", 0))
	echo_weapon_frame = int(first.get("weapon_frame", 0))
	echo_flip_h = bool(first.get("flip_h",false))
	echo_aim = first.get("aim", aim)
	game.time_left += clock - float(first.t)
	history.clear()
	rewind_ready = false
	if game.run_mode == "endless": game.echo_cd = game.ENDLESS_ECHO_COOLDOWN
	immunity = 1.2
	game.flash = 0.65
	game.message = "ECO ATIVO • seu passado luta com você"
	game.message_time = 3.0

func hurt(amount: int) -> void:
	if immunity > 0 or game.state != "playing" or (game.practice_mode and game.practice_invincible):
		return
	game.contracts.record("hurt")
	health -= amount
	game.play_sfx("player_hurt")
	immunity = 0.65
	game.flash = 0.18
	game.fx.explosion(position, Color("ff707d"), 28)
	if health <= 0:
		game.handle_player_death()

func _draw() -> void:
	if not is_instance_valid(game):
		return
	if use_placeholder_graphics and not echo_frames.is_empty():
		draw_astro(echo_pos - position, Color("63dbd3"), true)
	if immunity > 1.5:
		draw_arc(Vector2.ZERO, 26, 0, TAU, 24, Color("78d6ff"), 3)
	if overdrive_time > 0:
		draw_arc(Vector2.ZERO, 22, clock * 5, clock * 5 + PI * 1.5, 16, Color("dda2ff"), 3)
	if berserk_time > 0:
		draw_arc(Vector2.ZERO, 32, -clock * 6, -clock * 6 + TAU * .85, 28, Color("ffad70"), 4)
	if game.state == "playing" and immunity > 0 and immunity <= 1.2 and int(clock * 16) % 2 == 0:
		return
	if use_placeholder_graphics:
		draw_astro(Vector2.ZERO, Color("edf5f7"), false)
	if use_placeholder_graphics:
		draw_line(aim * 12, aim * 27, Color("ffe5a0"), 6)
	if dash_time > 0:
		draw_line(-dash_dir * 18, -dash_dir * 40, Color("69e5ff"), 7)

func draw_astro(at: Vector2, color: Color, ghost: bool) -> void:
	if ghost:
		color.a = 0.5
	draw_circle(at + Vector2(0, 10), 15, Color(0, 0, 0, 0.24))
	draw_rect(Rect2(at + Vector2(-14, -4), Vector2(7, 18)), Color("7c8ca6"))
	draw_rect(Rect2(at + Vector2(-9, 0), Vector2(18, 18)), color)
	draw_circle(at + Vector2(0, -6), 13, color)
	draw_style_box(game.visor_style, Rect2(at + Vector2(-9, -12), Vector2(19, 11)))
	draw_line(at + Vector2(-5, 16), at + Vector2(-5, 22), color, 6)
	draw_line(at + Vector2(5, 16), at + Vector2(5, 22), color, 6)
