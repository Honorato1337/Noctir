extends Node2D

const Planets = preload("res://scripts/planets.gd")
const Player = preload("res://scenes/actors/player.tscn")
const Enemy = preload("res://scenes/actors/enemy.tscn")
const Projectile = preload("res://scenes/actors/projectile.tscn")
const SCREENS = {
	"menu": preload("res://scenes/ui/main_menu.tscn"),
	"controls": preload("res://scenes/ui/controls.tscn"),
	"pause": preload("res://scenes/ui/pause_menu.tscn"),
	"shop": preload("res://scenes/ui/shop_screen.tscn"),
	"upgrade": preload("res://scenes/ui/upgrade_screen.tscn"),
	"result": preload("res://scenes/ui/result_screen.tscn")
}
const ARENAS_PER_PLANET := 4
@export var arena_scenes: Array[PackedScene] = [
	preload("res://scenes/world/arena.tscn"),
	preload("res://scenes/world/mars_quarry.tscn"),
	preload("res://scenes/world/mars_hangars.tscn"),
	preload("res://scenes/world/mars_reactor.tscn"),
	preload("res://scenes/world/venus_refinery.tscn"),
	preload("res://scenes/world/venus_gardens.tscn"),
	preload("res://scenes/world/venus_channels.tscn"),
	preload("res://scenes/world/venus_core.tscn"),
	preload("res://scenes/world/jupiter_docks.tscn"),
	preload("res://scenes/world/jupiter_relays.tscn"),
	preload("res://scenes/world/jupiter_eye.tscn"),
	preload("res://scenes/world/jupiter_heart.tscn")
]

func total_rooms() -> int:
	return arena_scenes.size()

var arena := Rect2(64, 136, 1024, 500)
var state := "menu"
var planet_index := 0
var room := 0
var time_left := 45.0
var time_bonus := 0.0
var elapsed := 0.0
var pending := 0
var spawn_cd := 0.0
var clear_wait := 0.0
var score := 0
var kills := 0
var best := 0
var flash := 0.0
var message := ""
var message_time := 0.0
var player: Node2D
var enemies: Node2D
var bullets: Node2D
var effects: Array[Dictionary] = []
var obstacles: Array[Rect2] = []
var hazards: Array[Vector2] = []
var portal := Vector2(1038, 386)
var layer: CanvasLayer
var panel: Control
var font: Font = preload("res://fonts/w95fa/W95F.otf")
var visor_style := StyleBoxFlat.new()
var rng := RandomNumberGenerator.new()
var chosen_upgrades: Array[String] = []
var smoke_mode := false
var loot: Node2D
var fx: Node2D
var boss_spawned := false
var boss_ref: Node2D
var boss_summon_cd := 7.0
var boss_summon_budget := 0
var wave_total := 0
var phase_kills := 0
var shop_stock: Array[Dictionary] = []
var shop_purchased: Array[bool] = [false, false, false]
const MAX_ACTIVE_ENEMIES := 80

func _ready() -> void:
	rng.randomize()
	setup_inputs()
	visor_style.bg_color = Color("18354b")
	visor_style.set_corner_radius_all(0)
	enemies = $Enemies
	bullets = $Projectiles
	layer = $UI
	loot = $Loot
	loot.game = self
	fx = $CombatFX
	fx.game = self
	# This instance is visible when opening main.tscn in the editor.
	panel = $UI/ScreenHost/MainMenu
	var save := ConfigFile.new()
	if save.load("user://record.cfg") == OK:
		best = int(save.get_value("score", "best", 0))
	show_menu()
	if "--smoke" in OS.get_cmdline_user_args():
		smoke_mode = true
		start_run()

func setup_inputs() -> void:
	var keys := {"left": [KEY_A], "right": [KEY_D], "up": [KEY_W], "down": [KEY_S], "aim_left": [KEY_LEFT], "aim_right": [KEY_RIGHT], "aim_up": [KEY_UP], "aim_down": [KEY_DOWN], "dash": [KEY_SPACE], "rewind": [KEY_Q], "interact": [KEY_E], "pause": [KEY_ESCAPE], "restart": [KEY_R], "slot_one": [KEY_1], "slot_two": [KEY_2]}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in keys[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
	if not InputMap.has_action("fire"):
		InputMap.add_action("fire")
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("fire", mouse)

func planet() -> Dictionary:
	return Planets.DATA[planet_index]

func start_run() -> void:
	close_panel()
	if is_instance_valid(player):
		remove_child(player)
		player.queue_free()
	player = Player.instantiate()
	player.game = self
	add_child(player)
	room = 0
	planet_index = 0
	score = 0
	kills = 0
	time_bonus = 0
	elapsed = 0
	chosen_upgrades.clear()
	loot.reset_run()
	start_room()

func start_room() -> void:
	clear_container(enemies)
	clear_container(bullets)
	effects.clear()
	loot.drops.clear()
	fx.particles.clear()
	fx.labels.clear()
	fx.shake = 0
	planet_index = room / ARENAS_PER_PLANET
	var next_scene: PackedScene = arena_scenes[room]
	if $Arena.scene_file_path != next_scene.resource_path:
		var old_arena := $Arena
		remove_child(old_arena)
		old_arena.queue_free()
		var next_arena := next_scene.instantiate()
		next_arena.name = "Arena"
		next_arena.z_index = -1
		add_child(next_arena)
	$Arena.apply_to(self)
	player.history.clear()
	player.echo_frames.clear()
	player.rewind_ready = true
	player.immunity = 1.5
	player.dash_cd = 0
	wave_total = 36 + room * 6
	pending = wave_total
	phase_kills = 0
	boss_spawned = false
	boss_ref = null
	boss_summon_budget = 12 + room
	boss_summon_cd = 7.0
	spawn_cd = 0.15
	clear_wait = 0
	time_left = 105.0 + room * 6.0 + time_bonus
	message = $Arena.layout_name
	message_time = 3
	state = "playing"

func _physics_process(delta: float) -> void:
	flash = maxf(0, flash - delta)
	if Input.is_action_just_pressed("pause"):
		if state == "playing" or state == "exit":
			var previous := state
			state = "paused"
			show_screen("pause")
			bind_button("ResumeButton", func(): state = previous; close_panel())
			bind_button("RestartButton", start_run)
			bind_button("MenuButton", show_menu)
		elif state == "paused":
			state = "exit" if boss_spawned and pending == 0 and enemies.get_child_count() == 0 else "playing"
			close_panel()
	if state == "ended" and Input.is_action_just_pressed("restart"):
		start_run()
	if state == "playing":
		elapsed += delta
		time_left = maxf(0, time_left - delta)
		message_time -= delta
		spawn_cd -= delta
		if pending > 0 and spawn_cd <= 0:
			var batch := mini(pending, 6 + room / 3)
			batch = mini(batch, MAX_ACTIVE_ENEMIES - enemies.get_child_count())
			for i in maxi(0, batch):
				spawn_enemy()
				pending -= 1
			spawn_cd = maxf(0.28, 0.65 - room * 0.025)
		if not boss_spawned and pending == 0 and phase_kills >= int(wave_total * 0.65):
			begin_boss()
		if boss_spawned and is_instance_valid(boss_ref) and not boss_ref.is_queued_for_deletion():
			boss_summon_cd -= delta
			if boss_summon_cd <= 0 and boss_summon_budget > 0:
				var reinforcement := mini(4 + planet_index, boss_summon_budget)
				pending += reinforcement
				boss_summon_budget -= reinforcement
				boss_summon_cd = 7.0
				fx.floating(boss_ref.position, "REFORÇOS!", Color("ff7e8d"))
		if planet_index == 1 and fmod(elapsed, 7) > 4:
			for hazard in hazards:
				if player.position.distance_to(hazard) < 54:
					player.hurt(1)
		if state == "playing" and time_left <= 0:
			finish(false, "A janela de extração fechou. Priorize os alvos distantes.")
		if state == "playing" and boss_spawned and pending == 0 and enemies.get_child_count() == 0:
			clear_wait += delta
			if clear_wait > 0.3:
				score += int(time_left) * 10
				open_shop()
	elif state == "exit":
		# Movement remains active while the combat clock is frozen.
		var direction := Input.get_vector("left", "right", "up", "down")
		move_actor(player, direction * player.speed * delta, 13)
		player.queue_redraw()
		if player.position.distance_to(portal) < 48 and Input.is_action_just_pressed("interact"):
			room += 1
			start_room()
	for i in range(effects.size() - 1, -1, -1):
		effects[i].life -= delta
		if effects[i].life <= 0:
			effects.remove_at(i)
	queue_redraw()

func clear_container(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func spawn_enemy(is_boss: bool = false) -> void:
	var enemy := Enemy.instantiate()
	enemy.game = self
	enemy.kind = int(planet().kind)
	enemy.boss = is_boss
	enemy.speed = float(planet().speed) + 12 + (room % ARENAS_PER_PLANET) * 6
	enemy.health = 2.0 + planet_index * 0.65 + floorf(room / 6.0) * 0.5
	if is_boss:
		enemy.health = 40.0 + room * 12.0
		enemy.radius = 32
		enemy.speed = 48 + room * 2
	enemy.max_health = enemy.health
	# Spawn gates stay distant from the player; no enemy appears on top of them.
	var gates: Array[Vector2] = $Arena.spawn_gates()
	gates.shuffle()
	enemy.position = $Arena/BossSpawn.global_position if is_boss else gates[0]
	for gate in gates:
		if gate.distance_to(player.position) > 330 and not is_boss:
			enemy.position = gate
			break
	# Spread each gate into a small entry band, never on the player or cover.
	if not is_boss:
		for attempt in 12:
			var candidate: Vector2 = enemy.position + Vector2(rng.randf_range(-28, 28), rng.randf_range(-28, 28))
			if arena.grow(-enemy.radius).has_point(candidate) and not blocked(candidate, enemy.radius) and candidate.distance_to(player.position) > 180:
				enemy.position = candidate
				break
	else:
		if blocked(enemy.position, enemy.radius) or enemy.position.distance_to(player.position) < 220:
			for gate in gates:
				if not blocked(gate, enemy.radius) and arena.grow(-enemy.radius).has_point(gate) and gate.distance_to(player.position) >= 220:
					enemy.position = gate
					break
		boss_ref = enemy
	enemy.shot_cd = rng.randf_range(0.6, 2.0)
	enemies.add_child(enemy)
	burst(enemy.position, planet().accent)

func shoot(origin: Vector2, direction: Vector2, amount: float, hostile: bool, is_echo: bool = false) -> void:
	var bullet := Projectile.instantiate()
	bullet.game = self
	bullet.position = origin + direction * (35 if hostile else 25)
	bullet.velocity = direction * (225 if hostile else 660)
	bullet.damage = amount
	bullet.hostile = hostile
	bullet.echo = is_echo
	bullet.radius = 6 if hostile else clampf(3.5 + amount, 4, 8)
	bullets.add_child(bullet)
	fx.sparks(bullet.position, Color("ff7e8d") if hostile else Color("ffe5a0"), 2, 55)

func blocked(point: Vector2, radius: float) -> bool:
	for obstacle in obstacles:
		var nearest := point.clamp(obstacle.position, obstacle.end)
		if nearest.distance_squared_to(point) < radius * radius:
			return true
	return false

func move_actor(actor: Node2D, movement: Vector2, radius: float) -> void:
	var next := actor.position + Vector2(movement.x, 0)
	if not blocked(next, radius):
		actor.position.x = clampf(next.x, arena.position.x + radius, arena.end.x - radius)
	next = actor.position + Vector2(0, movement.y)
	if not blocked(next, radius):
		actor.position.y = clampf(next.y, arena.position.y + radius, arena.end.y - radius)

func burst(at: Vector2, color: Color) -> void:
	effects.append({"pos": at, "color": color, "life": 0.4})
	fx.sparks(at, color, 12, 120)

func begin_boss() -> void:
	boss_spawned = true
	spawn_enemy(true)
	pending += 14 + room * 2
	time_left += 20
	message = "GUARDIÃO DA ARENA • elimine o chefe e os reforços!"
	message_time = 4
	fx.explosion(boss_ref.position, planet().accent, 90)

func choose_upgrade() -> void:
	# Compatibility entry point for scene previews.
	open_shop()

func open_shop() -> void:
	state = "shop"
	clear_container(bullets)
	player.echo_frames.clear()
	loot.collect_remaining()
	show_screen("shop")
	var options := range(Planets.UPGRADES.size())
	if player.spread >= 3:
		options.erase(0)
	options.shuffle()
	shop_stock.clear()
	shop_purchased = [false, false, false]
	for i in 3:
		var upgrade: Dictionary = Planets.UPGRADES[options[i]]
		shop_stock.append({"key": upgrade.key, "name": upgrade.name, "desc": upgrade.desc, "cost": 22 + room * 3 + i * 5})
		var button: Button = panel.find_child("Choice%d" % (i + 1), true, false)
		button.pressed.connect(buy_upgrade.bind(i))
	bind_button("RepairButton", buy_supply.bind("repair"))
	bind_button("BombButton", buy_supply.bind("bomb"))
	bind_button("ShieldButton", buy_supply.bind("shield"))
	bind_button("OverdriveButton", buy_supply.bind("overdrive"))
	bind_button("LeaveButton", leave_shop)
	refresh_shop()

func shop_notice(text: String) -> void:
	panel.find_child("Notice", true, false).text = text

func refresh_shop() -> void:
	panel.find_child("Wallet", true, false).text = "MOEDAS: %d   |   ITENS: %s / %s" % [loot.coins, slot_name(0), slot_name(1)]
	for i in 3:
		var stock: Dictionary = shop_stock[i]
		var button: Button = panel.find_child("Choice%d" % (i + 1), true, false)
		button.text = ("COMPRADO • " if shop_purchased[i] else "%d moedas • " % stock.cost) + stock.name + "\n" + stock.desc.replace("\n", " / ")
		button.disabled = shop_purchased[i]
	panel.find_child("LeaveButton", true, false).text = "CONCLUIR EXPEDIÇÃO" if room == total_rooms() - 1 else "CONTINUAR PARA A EXTRAÇÃO"

func slot_name(index: int) -> String:
	return "vazio" if loot.slots[index].is_empty() else loot.ITEMS[loot.slots[index]].name

func buy_upgrade(index: int) -> bool:
	if state != "shop" or index < 0 or index >= shop_stock.size() or shop_purchased[index]:
		return false
	var stock: Dictionary = shop_stock[index]
	if loot.coins < int(stock.cost):
		shop_notice("Moedas insuficientes.")
		return false
	loot.coins -= int(stock.cost)
	shop_purchased[index] = true
	apply_upgrade(stock.key)
	shop_notice("Módulo instalado: " + stock.name)
	refresh_shop()
	return true

func buy_supply(kind: String) -> bool:
	if state != "shop":
		return false
	var cost := 14 if kind == "repair" else 18
	if loot.coins < cost:
		shop_notice("Moedas insuficientes.")
		return false
	if kind == "repair":
		if player.health >= player.max_health:
			shop_notice("Seu traje já está reparado.")
			return false
		player.health = mini(player.max_health, player.health + 2)
	elif not loot.add_item(kind):
		shop_notice("Os dois slots estão cheios. Use seus itens na próxima arena.")
		return false
	loot.coins -= cost
	shop_notice("Compra concluída.")
	refresh_shop()
	return true

func leave_shop() -> void:
	if state != "shop":
		return
	close_panel()
	if room == total_rooms() - 1:
		finish(true, "Doze guardiões derrotados. A rota está livre!")
	else:
		state = "exit"

func apply_upgrade(key: String) -> void:
	chosen_upgrades.append(key)
	match key:
		"spread":
			player.spread = mini(player.spread + 1, 3)
			player.damage *= 0.85
		"rate":
			player.interval = maxf(0.07, player.interval * 0.8)
			player.speed *= 0.95
		"health":
			player.max_health += 1
			player.health = mini(player.max_health, player.health + 2)
		"speed":
			player.speed *= 1.18
			player.dash_recharge = maxf(0.6, player.dash_recharge * 0.85)
		"damage": player.damage *= 1.35
		"time":
			time_bonus += 8
			player.health = mini(player.max_health, player.health + 1)

func finish(won: bool, reason: String) -> void:
	state = "ended"
	if won:
		score += player.health * 200
	best = maxi(score, best)
	if not smoke_mode:
		var save := ConfigFile.new()
		save.set_value("score", "best", best)
		save.save("user://record.cfg")
	show_screen("result")
	panel.find_child("Title", true, false).text = "ÓRBITA COMPLETA" if won else "SÓ MAIS UMA VEZ?"
	panel.find_child("Description", true, false).text = reason + "\n\nPontos: %d    Recorde: %d    Abates: %d\nArena: %d/%d    Tempo: %ds" % [score, best, kills, room + 1, total_rooms(), int(elapsed)]
	bind_button("RestartButton", start_run)
	bind_button("MenuButton", show_menu)

func show_menu() -> void:
	state = "menu"
	show_screen("menu")
	bind_button("StartButton", start_run)
	bind_button("ControlsButton", show_controls)

func show_controls() -> void:
	show_screen("controls")
	bind_button("BackButton", show_menu)

func close_panel() -> void:
	if is_instance_valid(panel):
		panel.get_parent().remove_child(panel)
		panel.queue_free()
	panel = null

func show_screen(screen_name: String) -> void:
	close_panel()
	panel = SCREENS[screen_name].instantiate()
	$UI/ScreenHost.add_child(panel)

func bind_button(node_name: String, action: Callable) -> void:
	var button: Button = panel.find_child(node_name, true, false)
	button.pressed.connect(action)

func _process(_delta: float) -> void:
	$UI/HUD.update_game(self)

func text_at(at: Vector2, text: String, size: int, color: Color = Color("e0e8f3")) -> void:
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	for i in 90:
		var star := Vector2(fmod(i * 173.7, 1152), fmod(i * 97.3, 720))
		draw_rect(Rect2(star.snapped(Vector2(4, 4)), Vector2(2, 2)), Color(0.45, 0.6, 0.8, 0.3))
	for hazard in hazards:
		var active := fmod(elapsed, 7) > 4
		draw_circle(hazard, 54, Color(0.65, 0.85, 0.25, 0.25 if active else 0.06))
		draw_arc(hazard, 54, 0, TAU, 40, Color("a5bb55"), 2)
		if active:
			text_at(hazard - Vector2(23, -5), "ÁCIDO", 14)
	for effect in effects:
		draw_arc(effect.pos, (0.4 - effect.life) * 85 + 5, 0, TAU, 20, Color(effect.color, effect.life * 2), 3)
	if is_instance_valid(player):
		if state == "exit":
			draw_arc(portal, 32, 0, TAU, 40, Color("71e4c5"), 5)
			var arrow: Vector2 = player.position.direction_to(portal)
			var tip: Vector2 = player.position + arrow * 65
			draw_line(player.position + arrow * 35, tip, Color("71e4c5"), 4)
			draw_line(tip, tip - arrow.rotated(0.55) * 15, Color("71e4c5"), 4)
			draw_line(tip, tip - arrow.rotated(-0.55) * 15, Color("71e4c5"), 4)
		elif state == "playing" and pending == 0 and enemies.get_child_count() > 0:
			var target: Node2D = enemies.get_child(0)
			var direction: Vector2 = player.position.direction_to(target.position)
			draw_line(player.position + direction * 34, player.position + direction * 48, Color(1, 1, 1, 0.4), 2)
	if flash > 0:
		draw_rect(Rect2(0, 0, 1152, 720), Color(0.3, 0.9, 0.9, minf(flash * 0.4, 0.25)))
