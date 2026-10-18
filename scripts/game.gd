extends Node2D

const Vfx = preload("res://scripts/pixel_effects.gd")
const Planets = preload("res://scripts/planets.gd")
const Economy = preload("res://scripts/economy.gd")
const Progression = preload("res://scripts/progression.gd")
const UserSettings = preload("res://scripts/user_settings.gd")
const MENU_INTRO = preload("res://musica/processed/soundmenu1.wav")
const MENU_LOOP = preload("res://musica/processed/SoundMenu.wav")
const Player = preload("res://scenes/actors/player.tscn")
const Enemy = preload("res://scenes/actors/enemy.tscn")
const Projectile = preload("res://scenes/actors/projectile.tscn")
const SCREENS = {
	"travel": preload("res://scenes/ui/travel_screen.tscn"),
	"death": preload("res://scenes/ui/death_menu.tscn"),
	"difficulty": preload("res://scenes/ui/difficulty_menu.tscn"),
	"menu": preload("res://scenes/ui/main_menu.tscn"),
	"test": preload("res://scenes/ui/test_arena_menu.tscn"),
	"controls": preload("res://scenes/ui/controls.tscn"),
	"pause": preload("res://scenes/ui/pause_menu.tscn"),
	"shop": preload("res://scenes/ui/shop_screen.tscn"),
	"permanent": preload("res://scenes/ui/permanent_shop.tscn"),
	"settings": preload("res://scenes/ui/settings_menu.tscn"),
	"upgrade": preload("res://scenes/ui/upgrade_screen.tscn"),
	"result": preload("res://scenes/ui/result_screen.tscn")
}
const DIFFICULTIES := {
 "easy": {"name": "FÁCIL", "reward": 0.25, "health": 0.7, "speed": 0.85, "waves": 0.7, "bullets": 0.85, "time": 1.2},
 "medium": {"name": "MÉDIO", "reward": 1.0, "health": 1.0, "speed": 1.0, "waves": 1.0, "bullets": 1.0, "time": 1.0},
 "hard": {"name": "DIFÍCIL", "reward": 1.5, "health": 1.35, "speed": 1.15, "waves": 1.3, "bullets": 1.2, "time": 0.95}
}
var run_difficulty := "medium"
var run_mode := "campaign"
var selected_run_mode := "campaign"
var survival = preload("res://scripts/survival.gd").new()

func difficulty() -> Dictionary:
	return DIFFICULTIES[run_difficulty]

const ARENAS_PER_PLANET := 4
@export var arena_scenes: Array[PackedScene] = [
	preload("res://scenes/world/arena.tscn"),
	preload("res://scenes/world/mars_quarry.tscn"),
	preload("res://scenes/world/mars_hangars.tscn"),
	preload("res://scenes/world/mars_reactor.tscn"),
	preload("res://scenes/world/neptune_outpost.tscn"),
	preload("res://scenes/world/neptune_frostfields.tscn"),
	preload("res://scenes/world/neptune_windways.tscn"),
	preload("res://scenes/world/neptune_storm_core.tscn"),
	preload("res://scenes/world/jupiter_docks.tscn"),
	preload("res://scenes/world/jupiter_relays.tscn"),
	preload("res://scenes/world/jupiter_eye.tscn"),
	preload("res://scenes/world/jupiter_heart.tscn"),
	preload("res://scenes/world/alien_throne.tscn")
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
var environment_clock := 0.0
var pending := 0
var spawn_cd := 0.0
var clear_wait := 0.0
var room_cleared := false
const COLLECTION_DURATION := 15.0
const SHOP_DURATION := 20.0
var shop_left := 0.0
var lost_loot := {"coins":0,"items":0}
var collection_left := 0.0
var extraction_boarded := false
var paused_from := "playing"
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
const DEVELOPER_PASSWORD_HASH := "36247c6dbfe4bea703caf8208399b5689bd983227ca42bfedd47013ccd60bcb6"
var developer_unlocked := false
var practice_mode := false
var practice_invincible := true
var practice_equipment := "mine"
var room_spawn_index := 0
var progression := Progression.new()
var run_active := false
var run_reward := 0
var run_space_reward := 0
var permanent_tab := "attributes"
var preferences := UserSettings.new()
var controls: Node
var touch_controls: Control
var remap_action := ""
var preferences_timer: Timer
var preferences_autosave := 0.0
var menu_clock_tick := 0.0
var planet_music_index := -1
var planet_music_stream: AudioStreamWAV
var menu_intro_completed := false
var menu_loop_stream: AudioStreamWAV = MENU_LOOP.duplicate()
var deployables: Node2D
var loot: Node2D
var weather: Node2D
var encounters: Node2D
var contracts: Node
var fx: Node2D
var boss_spawned := false
var boss_ref: Node2D
var boss_summon_cd := 7.0
var boss_summon_budget := 0
var wave_total := 0
var phase_kills := 0
var shop_stock: Array[Dictionary] = []
var shop_purchased: Array[bool] = [false, false, false]
var shop_supplies: Array[String] = []
var shop_rerolls := 0
const MAX_ACTIVE_ENEMIES := 80
const TRAVEL_DURATION := 2.4
var travel_kind := "rover"
const EXTRACTION_RANGE := 100.0
var travel_clock := 0.0
const RUN_CHANCES := 3
var run_chances_left := RUN_CHANCES
var extraction_penalty := 0
var rewarded_superboss_rooms: Array[int] = []
const ENDLESS_BERSERK_COOLDOWN := 90.0
const ENDLESS_ECHO_COOLDOWN := 45.0
var berserk_cd := 0.0
var echo_cd := 0.0
var berserk_used := false

func _ready() -> void:
	menu_loop_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	menu_loop_stream.loop_begin = 0
	menu_loop_stream.loop_end = int(round(menu_loop_stream.get_length() * menu_loop_stream.mix_rate))
	$GameAudio.game = self
	deployables = $Deployables
	deployables.game = self
	weather = $ArenaWeather
	weather.game = self
	encounters = $PlanetEncounters
	encounters.game = self
	contracts = $RunContracts
	contracts.game = self
	$MenuMusic.finished.connect(on_menu_music_finished)
	smoke_mode = smoke_mode or "--smoke" in OS.get_cmdline_user_args()
	$GameAudio.enabled = not smoke_mode
	contracts.enabled = not smoke_mode
	if smoke_mode:
		$MenuMusic.volume_db = -80.0
	if not smoke_mode:
		progression.load_profile()
		preferences.load_settings()
	preferences.apply_audio()
	$MenuMusic.bus = &"Music"
	$PlanetMusic.bus = &"Music"
	controls = load("res://scripts/game_controls.gd").new()
	controls.game = self
	add_child(controls)
	Input.joy_connection_changed.connect(on_joy_connection_changed)
	if not smoke_mode:
		preferences.apply_video()
	preferences_timer = Timer.new()
	preferences_timer.one_shot = true
	preferences_timer.wait_time = 0.4
	add_child(preferences_timer)
	preferences_timer.timeout.connect(save_preferences)
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
	$UI/HUD/Cleanup/Box/CleanupShopButton.pressed.connect(board_after_clear)
	$ExtractionRover.game = self
	touch_controls = load("res://scripts/touch_controls.gd").new()
	touch_controls.game = self
	layer.add_child(touch_controls)
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
	controls.configure()


const SURVIVAL_PLANET := {"name":"PLUTÃO","subtitle":"Planície do Exílio","floor":Color("1c2936"),"accent":Color("b3e6ed"),"enemy":Color("bad4e5"),"kind":0,"speed":76.0,"hazard":"ANOMALIAS / sobreviva ao frio e às fendas"}

func planet() -> Dictionary:
	return SURVIVAL_PLANET if run_mode == "endless" else Planets.DATA[planet_index]

func start_run(as_practice: bool = false, initial_room: int = 0, mode: String = "medium", game_mode: String = "campaign") -> void:
	if as_practice and not developer_unlocked: return
	settle_run()
	run_mode = "endless" if game_mode == "endless" and not as_practice else "campaign"
	practice_mode = as_practice
	run_difficulty = mode if DIFFICULTIES.has(mode) and not as_practice else "medium"
	survival.reset(self)
	berserk_used = false
	berserk_cd = 0
	echo_cd = 0
	run_chances_left = RUN_CHANCES
	rewarded_superboss_rooms.clear()
	contracts.enabled = not smoke_mode and not practice_mode and run_difficulty != "easy"
	menu_intro_completed = true
	$MenuMusic.stop()
	$GameAudio.death_voice.stop()
	$PlanetMusic.stream_paused = false
	close_panel()
	if is_instance_valid(player):
		remove_child(player)
		player.queue_free()
	player = Player.instantiate()
	player.game = self
	add_child(player)
	progression.apply_to(player)
	if practice_mode:
		player.pickup_bonus = maxf(player.pickup_bonus, 200)
	room = clampi(initial_room, 0, total_rooms() - 1)
	planet_index = 0
	score = 0
	kills = 0
	time_bonus = int(progression.levels.time) * 2
	elapsed = 0
	chosen_upgrades.clear()
	loot.reset_run()
	deployables.reset_run()
	if practice_mode:
		deployables.inventory = practice_equipment
	contracts.reset_run()
	run_reward = 0
	run_space_reward = 0
	run_active = true
	start_room()

func start_room() -> void:
	room_cleared = false
	collection_left = 0
	shop_left = 0
	lost_loot = {"coins":0,"items":0}
	extraction_boarded = false
	extraction_penalty = 0
	encounters.reset()
	deployables.clear_room()
	environment_clock = 0.0
	room_spawn_index = 0
	clear_container(enemies)
	clear_container(bullets)
	effects.clear()
	loot.drops.clear()
	fx.particles.clear()
	fx.labels.clear()
	fx.shake = 0
	planet_index = room / ARENAS_PER_PLANET
	play_planet_music()
	contracts.start_room()
	var next_scene: PackedScene = preload("res://scenes/world/pluto_survival.tscn") if run_mode == "endless" else arena_scenes[room]
	if $Arena.scene_file_path != next_scene.resource_path:
		var old_arena := $Arena
		remove_child(old_arena)
		old_arena.queue_free()
		var next_arena := next_scene.instantiate()
		next_arena.name = "Arena"
		next_arena.z_index = -1
		add_child(next_arena)
	$Arena.apply_to(self)
	configure_camera()
	player.history.clear()
	player.echo_frames.clear()
	player.rewind_ready = true
	player.immunity = 1.5
	player.dash_cd = 0
	wave_total = ceili((132 if room == 12 else 36 + room * 6) * float(difficulty().waves))
	pending = wave_total
	phase_kills = 0
	boss_spawned = false
	boss_ref = null
	boss_summon_budget = ceili((12 + room) * float(difficulty().waves))
	boss_summon_cd = 7.0
	spawn_cd = 0.15
	clear_wait = 0
	time_left = ((240.0 if room == 12 else 105.0 + room * 6.0) + time_bonus) * float(difficulty().time)
	weather.reset_room()
	message = $Arena.layout_name
	message_time = 3
	state = "playing"
	if run_mode == "endless":
		survival.start_wave()

func _physics_process(delta: float) -> void:
	if state == "shop":
		shop_left = maxf(0,shop_left-delta)
		update_shop_clock()
		if shop_left <= 0:
			extraction_boarded = true
			leave_shop()
		return
	if state == "travel":
		travel_clock += delta
		if travel_clock >= TRAVEL_DURATION:
			close_panel()
			if room >= total_rooms()-1:
				finish(true, "O Deus Alienígena caiu. Treze arenas conquistadas!")
			else:
				room += 1
				start_room()
		return
	flash = maxf(0, flash - delta)
	if Input.is_action_just_pressed("pause"):
		if state in ["playing", "cleared", "exit"]:
			pause_run()
		elif state == "paused":
			state = paused_from
			close_panel()
	if state == "ended" and Input.is_action_just_pressed("restart"):
		restart_current_run()
	if state == "playing":
		if run_mode == "endless":
			berserk_cd = maxf(0,berserk_cd-delta)
			echo_cd = maxf(0,echo_cd-delta)
			if echo_cd <= 0: player.rewind_ready = true
		elapsed += delta
		environment_clock += delta
		if planet_index == 1 and fmod(environment_clock, 7.0) >= 3.5 and fmod(environment_clock - delta, 7.0) < 3.5:
			play_sfx("frost_warning")
			message = "GEADA CHEGANDO • saia das áreas marcadas ou use o dash!"
			message_time = 1.5
		if run_mode == "endless":
			message_time -= delta
			survival.tick(delta)
		else:
			time_left = maxf(0, time_left - delta) if not practice_mode else time_left
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
					boss_summon_cd = 5.5 if boss_ref.superboss else 7.0
					fx.floating(boss_ref.position, "REFORÇOS!", Color("ff7e8d"))
			if planet_index == 1 and frost_active():
				for hazard in hazards:
					if player.position.distance_to(hazard) < 54:
						player.hurt(1)
			if state == "playing" and time_left <= 0:
				finish(false, "A janela de extração fechou. Priorize os alvos distantes.")
			if state == "playing" and boss_spawned and pending == 0 and enemies.get_child_count() == 0:
				finish_arena()
	elif state in ["cleared", "exit"]:
		var direction: Vector2 = controls.movement()
		move_actor(player,direction*player.speed*delta,13)
		player.queue_redraw()
		if Input.is_action_just_pressed("interact"):
			if state == "cleared": board_after_clear()
			elif player.position.distance_to(portal) < EXTRACTION_RANGE: start_transfer()
		if state == "cleared":
			collection_left = maxf(0, collection_left-delta)
			if collection_left <= 0: board_after_clear(true)
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
	enemy.kind = room_spawn_index % 3 if room == 12 and not is_boss else int(planet().kind)
	if not is_boss:
		room_spawn_index += 1
	if run_mode == "endless":
		enemy.kind = survival.enemy_kind(is_boss)
	enemy.boss = is_boss
	enemy.superboss = is_boss and ((room + 1) % ARENAS_PER_PLANET == 0 or room == 12)
	enemy.god = is_boss and room == 12
	if run_mode == "endless":
		enemy.superboss = is_boss and survival.boss_number % 3 == 0
		enemy.god = enemy.superboss and survival.boss_number % 6 == 0
		if enemy.god: enemy.kind = 3
	enemy.speed = float(Planets.DATA[enemy.kind].speed) + 12 + (room % ARENAS_PER_PLANET) * 6
	enemy.health = 2.0 + planet_index * 0.65 + floorf(room / 6.0) * 0.5
	if is_boss:
		enemy.health = 40.0 + room * 12.0
		enemy.radius = 40 if enemy.superboss else 32
		if enemy.superboss:
			enemy.health *= 2.4
		enemy.speed = 90 + room * 3
		if enemy.god:
			enemy.health = 520
			enemy.radius = 44
			enemy.speed = 165
	if enemy.kind == 2 and not is_boss:
		enemy.jupiter_role = rng.randi_range(0, 2)
		enemy.health *= 1.35 if enemy.jupiter_role == 2 else 1.15
	# Later arenas must remain threatening after repeated damage purchases.
	enemy.health *= (1.6 + room*0.06) if is_boss else (1.4 + room*0.07)
	enemy.health *= progression.enemy_health_factor() * float(difficulty().health)
	enemy.speed *= float(difficulty().speed)
	enemy.speed *= 1 + .45 * progression.prestige_cycles / (progression.prestige_cycles + 8.0)
	if run_mode == "endless":
		enemy.health *= survival.health_factor()
		enemy.speed *= survival.speed_factor()
	enemy.max_health = enemy.health
	if is_boss and enemy.kind >= 1:
		enemy.max_shield = enemy.health * (.75 if enemy.god else ((.55 if enemy.superboss else .35) if enemy.kind == 1 else (.85 if enemy.superboss else .65)))
		enemy.shield = enemy.max_shield
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
	if run_mode == "endless":
		enemy.position = survival.spawn_position(enemy.radius)
	enemy.shot_cd = rng.randf_range(0.6, 2.0)
	enemies.add_child(enemy)
	burst(enemy.position, planet().accent)

func shoot(origin: Vector2, direction: Vector2, amount: float, hostile: bool, is_echo: bool = false) -> void:
	if not hostile and bullets.get_child_count() >= 900:
		return
	var bullet := Projectile.instantiate()
	bullet.game = self
	bullet.position = origin + direction * (35 if hostile else 25)
	bullet.velocity = direction * (255 * float(difficulty().bullets) if hostile else 660)
	bullet.damage = amount * enemy_damage() if hostile else amount
	bullet.hostile = hostile
	if hostile and run_mode == "endless":
		bullet.velocity *= minf(1.6, 1.0 + survival.tier * 0.025)
	bullet.frost = hostile and planet_index == 1
	bullet.echo = is_echo
	bullet.radius = 6 if hostile else clampf(3.5 + amount, 4, 8)
	bullets.add_child(bullet)
	fx.sparks(bullet.position, Color("78dfff") if bullet.frost else (Color("ff7e8d") if hostile else Color("ffe5a0")), 2, 55)

func blocked(point: Vector2, radius: float) -> bool:
	for obstacle in obstacles:
		var nearest := point.clamp(obstacle.position, obstacle.end)
		if nearest.distance_squared_to(point) < radius * radius:
			return true
	return false

func move_actor(actor: Node2D, movement: Vector2, radius: float) -> void:
	# Sweep long dashes in short steps so pillars cannot be skipped.
	var steps := maxi(1, ceili(movement.length() / 12.0))
	var part := movement / steps
	for step in steps:
		var next := actor.position + Vector2(part.x, 0)
		if not blocked(next, radius):
			actor.position.x = clampf(next.x, arena.position.x + radius, arena.end.x - radius)
		next = actor.position + Vector2(0, part.y)
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
	message = boss_ref.display_name() + " • elimine o chefe e os reforços!"
	message_time = 4
	if planet_index == 1:
		environment_clock = 3.5
		message = boss_ref.display_name() + " • cuidado com a geada e os reforços!"
	if boss_ref.superboss:
		pending += 10
		boss_summon_budget += 8
		boss_summon_cd = 5.5
		time_left += 100 if boss_ref.god else 50
		message = "SUPERCHEFE • " + boss_ref.superboss_name()
		message_time = 4
	play_sfx("boss_alert")
	fx.explosion(boss_ref.position, planet().accent, 90)

func choose_upgrade() -> void:
	# Compatibility entry point for scene previews.
	open_shop()

func open_shop() -> void:
	clear_combat_effects()
	room_cleared = true
	state = "shop"
	shop_left = 10.0 if run_mode == "endless" else SHOP_DURATION
	$GameAudio.stop_alarm()
	play_sfx("stage_clear")
	clear_container(bullets)
	player.echo_frames.clear()
	lost_loot = {"coins":0,"items":0} if run_mode == "endless" else loot.discard_remaining()
	show_screen("shop")
	shop_stock.clear()
	shop_purchased = [false, false, false]
	shop_supplies.clear()
	shop_rerolls = 0
	roll_shop_stock()
	for i in 3:
		var button: Button = panel.find_child("Choice%d" % (i + 1), true, false)
		button.pressed.connect(buy_upgrade.bind(i))
	bind_button("RepairButton", buy_supply.bind("repair"))
	bind_button("BombButton", buy_supply.bind("bomb"))
	bind_button("ShieldButton", buy_supply.bind("shield"))
	bind_button("OverdriveButton", buy_supply.bind("overdrive"))
	bind_button("LeaveButton", leave_shop)
	bind_button("RerollButton", reroll_shop)
	for kind: String in ["mine", "turret", "beacon"]:
		bind_button(kind.capitalize() + "Button", buy_supply.bind(kind))
	refresh_shop()
	if contracts.enabled:
		shop_notice(contracts.status_text())

func roll_shop_stock() -> void:
	var options: Array[Dictionary] = []
	for upgrade: Dictionary in Planets.UPGRADES:
		if upgrade.key == "spread" and player.spread >= 3:
			continue
		var already_bought := false
		for index in shop_stock.size():
			if shop_purchased[index] and shop_stock[index].key == upgrade.key:
				already_bought = true
		if not already_bought:
			options.append(upgrade)
	for index in 3:
		if index < shop_stock.size() and shop_purchased[index]:
			continue
		var pick := rng.randi_range(0, options.size() - 1)
		var stock := Economy.offer(options[pick], room, chosen_upgrades, rng)
		options.remove_at(pick)
		if index < shop_stock.size():
			shop_stock[index] = stock
		else:
			shop_stock.append(stock)

func reroll_shop() -> bool:
	if state != "shop" or shop_left <= 0 or shop_rerolls >= 2 or not shop_purchased.has(false):
		return false
	var cost := Economy.reroll_price(room, shop_rerolls)
	if loot.coins < cost:
		shop_notice("Moedas insuficientes para trocar as ofertas.")
		return false
	loot.coins -= cost
	shop_rerolls += 1
	roll_shop_stock()
	shop_notice("Novas ofertas. Trocar novamente custa mais; não há garantia de desconto.")
	refresh_shop()
	return true

func shop_notice(text: String) -> void:
	panel.find_child("Notice", true, false).text = text
	if "insuficientes" in text or "cheios" in text:
		play_sfx("error")

func refresh_shop() -> void:
	update_shop_clock()
	panel.find_child("Wallet", true, false).text = "MOEDAS   %03d" % loot.coins
	panel.find_child("ShopPhase", true, false).text = "%s  /  ARENA %02d CONCLUÍDA" % [planet().name, room + 1]
	if run_mode == "endless":
		panel.find_child("ShopPhase", true, false).text = "SOBREVIVÊNCIA / HORDA %d CONCLUÍDA" % survival.wave
	if int(lost_loot.coins)+int(lost_loot.items) > 0:
		panel.find_child("ShopPhase", true, false).text += "  /  PERDIDO: %d MOEDAS, %d %s" % [lost_loot.coins,lost_loot.items,"ITEM" if lost_loot.items == 1 else "ITENS"]
	for index in 2:
		var icon: TextureRect = panel.find_child("StoreIcon%d" % (index + 1), true, false)
		icon.texture = loot.ICONS.get(loot.slots[index], null)
		icon.get_parent().mouse_filter = Control.MOUSE_FILTER_PASS
		icon.get_parent().tooltip_text = "[%d] %s" % [index + 1, slot_name(index)]
	panel.find_child("StoreIcon3", true, false).texture = loot.ICONS.get(deployables.inventory, null)
	var ground_slot: Control = panel.find_child("StoreSlot3", true, false)
	ground_slot.mouse_filter = Control.MOUSE_FILTER_PASS
	ground_slot.tooltip_text = "[3] " + ("Vazio • exclusivo para equipamentos de chão." if deployables.inventory.is_empty() else deployables.DATA[deployables.inventory].name + " • use [3] durante o combate para colocar no chão.")
	for kind: String in ["mine", "turret", "beacon"]:
		var button: Button = panel.find_child(kind.capitalize() + "Button", true, false)
		var cost := Economy.supply_price(kind, room)
		button.text = "%s / %d" % [deployables.DATA[kind].name, cost]
		button.disabled = not deployables.inventory.is_empty() or shop_supplies.has(kind) or loot.coins < cost
		button.tooltip_text = {"mine": "Mina: explosão de raio 240 px. Arma após 0,65 s; dura 24 s.", "turret": "Torreta: atira automaticamente por 18 s, alcance 460 px.", "beacon": "Baliza: raio de 320 px, lentidão de 80% (50% nos chefes), limpa tiros a cada 0,35 s. Dura 20 s."}[kind] + "\nOcupa só o slot [3]. Coloque no chão durante o combate."
	if extraction_penalty > 0 or collection_left <= 0 and extraction_boarded:
		panel.find_child("ShopPhase", true, false).text = "ATRASO / INVENTÁRIO PERDIDO / -%d MOEDAS" % extraction_penalty
	var full: bool = not loot.slots.has("")
	panel.find_child("InventoryHint", true, false).text = "Carga cheia. Use [1] e [2] na próxima arena." if full else "Colete itens e use [1] e [2] durante o combate."
	panel.find_child("InventoryHint", true, false).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for i in 3:
		var stock: Dictionary = shop_stock[i]
		var button: Button = panel.find_child("Choice%d" % (i + 1), true, false)
		panel.find_child("ModuleTitle%d" % (i + 1), true, false).text = stock.name
		panel.find_child("ModuleDesc%d" % (i + 1), true, false).text = stock.desc
		var price: Label = panel.find_child("ModuleCost%d" % (i + 1), true, false)
		price.text = "INSTALADO" if shop_purchased[i] else ("OFERTA! %d MOEDAS >" if stock.bargain else "%d MOEDAS  >") % stock.cost
		price.modulate = Color("71e4c5") if shop_purchased[i] else (Color.WHITE if loot.coins >= int(stock.cost) else Color("b37777"))
		button.disabled = shop_purchased[i]
		button.tooltip_text = "%s\n%s\n\n%s" % [stock.name, stock.desc, "Instalado nesta expedição." if shop_purchased[i] else "Custa %d moedas. Módulos repetidos ficam mais caros." % stock.cost]
		if stock.bargain and not shop_purchased[i]:
			button.tooltip_text += " Oferta: desconto de 35% sobre o preço atual."
	var supplies := {"repair": ["RepairButton", "Reparo +%d" % (2 + progression.prestige_cycles)], "bomb": ["BombButton", "Bomba"], "shield": ["ShieldButton", "Escudo"], "overdrive": ["OverdriveButton", "Sobrecarga"]}
	for kind: String in supplies:
		var button: Button = panel.find_child(supplies[kind][0], true, false)
		var cost := Economy.supply_price(kind, room)
		var sold: bool = shop_supplies.has(kind)
		var unavailable: bool = player.health >= player.max_health if kind == "repair" else full
		button.text = "%s / %s" % [supplies[kind][1], "X" if sold else str(cost)]
		button.disabled = sold or unavailable or loot.coins < cost
		button.tooltip_text = {"repair": "Recupera %d corações imediatamente." % (2 + progression.prestige_cycles), "bomb": "Explosão: 12 de dano (24 em chefes) em todos os inimigos e limpa os projéteis da arena.", "shield": "Proteção por 5 segundos.", "overdrive": "Cadência e poder aumentados por 9 segundos."}[kind] + "\nUma unidade por parada. Custa %d moedas." % cost
		if sold:
			button.tooltip_text += "\n%s esgotado nesta parada." % supplies[kind][1]
		if unavailable:
			button.tooltip_text += "\n" + ("Vida cheia." if kind == "repair" else "Os dois slots estão cheios.")
	var reroll: Button = panel.find_child("RerollButton", true, false)
	var reroll_cost := Economy.reroll_price(room, shop_rerolls)
	reroll.text = "TROCAR / %d" % reroll_cost if shop_rerolls < 2 else "TROCAS ESGOTADAS"
	reroll.disabled = shop_rerolls >= 2 or loot.coins < reroll_cost or not shop_purchased.has(false)
	reroll.tooltip_text = "Troca apenas os módulos não comprados. Até duas trocas pagas; o desconto depende da sorte."
	panel.find_child("LeaveButton", true, false).text = ("VIAJAR DE " if extraction_boarded else "SEGUIR PARA O ") + extraction_name()
	panel.refresh_details()

func slot_name(index: int) -> String:
	return "vazio" if loot.slots[index].is_empty() else loot.ITEMS[loot.slots[index]].name

func buy_upgrade(index: int) -> bool:
	if state != "shop" or shop_left <= 0 or index < 0 or index >= shop_stock.size() or shop_purchased[index]:
		return false
	var stock: Dictionary = shop_stock[index]
	if loot.coins < int(stock.cost):
		shop_notice("Moedas insuficientes.")
		return false
	loot.coins -= int(stock.cost)
	shop_purchased[index] = true
	apply_upgrade(stock.key)
	play_sfx("purchase")
	shop_notice("Módulo instalado: " + stock.name)
	refresh_shop()
	return true

func buy_supply(kind: String) -> bool:
	if state != "shop" or shop_left <= 0 or kind not in ["repair", "bomb", "shield", "overdrive", "mine", "turret", "beacon"] or shop_supplies.has(kind):
		return false
	var cost := Economy.supply_price(kind, room)
	if loot.coins < cost:
		shop_notice("Moedas insuficientes.")
		return false
	if kind == "repair":
		if player.health >= player.max_health:
			shop_notice("Seu traje já está reparado.")
			return false
		player.health = mini(player.max_health, player.health + 2 + progression.prestige_cycles)
	elif deployables.DATA.has(kind) and not deployables.inventory.is_empty():
		shop_notice("O slot [3] está ocupado. Coloque o equipamento antes de comprar outro.")
		return false
	elif not loot.add_item(kind):
		shop_notice("Os dois slots estão cheios. Use seus itens na próxima arena.")
		return false
	loot.coins -= cost
	shop_supplies.append(kind)
	play_sfx("purchase")
	shop_notice("Compra concluída.")
	refresh_shop()
	return true

func leave_shop() -> void:
	if state != "shop":
		return
	close_panel()
	if run_mode == "endless":
		room_cleared = false
		state = "playing"
		survival.start_wave()
		return
	state = "exit"
	if extraction_boarded:
		player.position = portal
		start_transfer()

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
			player.health = mini(player.max_health, player.health + 2 + progression.prestige_cycles)
		"speed":
			player.speed *= 1.18
			player.dash_recharge = maxf(0.6, player.dash_recharge * 0.85)
		"damage": player.damage *= 1.35
		"time":
			time_bonus += 8
			player.health = mini(player.max_health, player.health + 1)

func finish(won: bool, reason: String, result_sound: bool = true) -> void:
	if not run_active:
		return
	state = "ended"
	if result_sound: play_sfx("victory" if won else "defeat")
	if won:
		score += player.health * 200
	settle_run()
	best = maxi(score, best) if not practice_mode else best
	if not smoke_mode and not practice_mode:
		var save := ConfigFile.new()
		save.set_value("score", "best", best)
		save.save("user://record.cfg")
	show_screen("result")
	panel.find_child("Title", true, false).text = "ÓRBITA COMPLETA" if won else "SÓ MAIS UMA VEZ?"
	panel.find_child("Description", true, false).text = reason + ("\nObrigado por jogar One More Orbit!" if won and not practice_mode else "")
	panel.find_child("Status", true, false).text = "MISSÃO CUMPRIDA" if won else "SINAL PERDIDO  /  RELATÓRIO DA EXPEDIÇÃO"
	panel.find_child("ScoreValue", true, false).text = "%05d" % score
	panel.find_child("BestValue", true, false).text = "%05d" % best
	panel.find_child("KillsValue", true, false).text = str(kills)
	panel.find_child("ArenaValue", true, false).text = "INFINITO / HORDA %d" % survival.wave if run_mode == "endless" else "%02d/%02d" % [room + 1, total_rooms()]
	panel.find_child("TimeValue", true, false).text = "%s / TEMPO %02d:%02d" % [difficulty().name, int(elapsed) / 60, int(elapsed) % 60]
	panel.find_child("RewardValue", true, false).text = "+%d COINS PERMANENTES  /  SALDO %d\nProgresso para o próximo coin: %d/%d pontos" % [run_reward, progression.coins, progression.remainder, Progression.POINTS_PER_COIN]
	panel.find_child("RewardValue", true, false).text += " / COINS %s×" % str(difficulty().reward)
	panel.find_child("RewardValue", true, false).text += "\n+%d SPACECOIN NOS CONTRATOS  /  SALDO %d" % [run_space_reward, progression.space_coins]
	if progression.last_save_error != OK:
		panel.find_child("RewardValue", true, false).text += "\nFalha ao salvar. Saldo mantido nesta sessão."
	bind_button("RestartButton", restart_current_run)
	bind_button("MenuButton", show_menu)
	if practice_mode:
		panel.find_child("Title", true, false).text = "TESTE CONCLUÍDO"
		panel.find_child("RewardValue", true, false).text = "MODO TESTE • Sem alteração de Coins, SpaceCoin ou recorde."
		panel.find_child("RestartButton", true, false).text = "REPETIR TESTE"
		panel.find_child("PermanentShopButton", true, false).text = "ESCOLHER OUTRA ARENA"
		bind_button("PermanentShopButton", show_test_menu)
	else:
		bind_button("PermanentShopButton", show_permanent_shop)

func settle_run() -> void:
	if not run_active:
		return
	run_active = false
	run_reward = 0 if practice_mode else progression.award_score(floori(score * float(difficulty().reward)), not smoke_mode)
	save_preferences()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not smoke_mode and state in ["playing", "cleared", "exit"]:
		pause_run()
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		settle_run()
		save_preferences()

func show_menu() -> void:
	settle_run()
	if state == "settings":
		save_preferences()
	state = "menu"
	show_screen("menu")
	var portrait: AnimatedSprite2D = panel.find_child("AstronautSprite",true,false)
	portrait.sprite_frames = Progression.Skins.DATA[progression.selected_skin].frames
	portrait.scale = Vector2.ONE*float(Progression.Skins.DATA[progression.selected_skin].menu_scale)
	portrait.play(&"walk")
	panel.find_child("Record", true, false).text = "RECORDE   %06d" % best
	panel.find_child("PermanentShopButton", true, false).text = "LOJA   /   %d COINS" % progression.coins
	bind_button("StartButton", show_difficulty_menu)
	bind_button("ControlsButton", show_controls)
	bind_button("PermanentShopButton", show_permanent_shop)
	bind_button("SettingsButton", show_settings)
	panel.find_child("TestButton", true, false).visible = developer_unlocked
	bind_button("TestButton", show_test_menu)
	update_menu_clock()

func show_difficulty_menu() -> void:
	settle_run()
	state = "difficulty"
	show_screen("difficulty")
	for mode: String in DIFFICULTIES:
		bind_button(mode.capitalize() + "Button", start_run.bind(false, 0, mode))
	var selector: OptionButton = panel.find_child("ModeSelector", true, false)
	selector.select(1 if selected_run_mode == "endless" else 0)
	selector.item_selected.connect(select_game_mode)
	select_game_mode(selector.selected)
	bind_button("BackButton", show_menu)

func select_game_mode(index: int) -> void:
	panel.find_child("ModeSelector", true, false).select(index)
	selected_run_mode = "endless" if index == 1 else "campaign"
	var infinite := index == 1
	panel.find_child("Description", true, false).text = "PLUTÃO / área 2× maior / hordas e anomalias sem fim." if infinite else "Escolha a dificuldade desta run. Você terá 3 chances por run."
	panel.find_child("Note", true, false).text = "Hordas crescentes sem fim. Chefes a cada 3 hordas. Loja por 10s." if infinite else "Multiplicador aplicado aos Coins da loja permanente."
	for key: String in DIFFICULTIES:
		var button: Button = panel.find_child(key.capitalize() + "Button", true, false)
		for connection: Dictionary in button.pressed.get_connections():
			button.pressed.disconnect(connection.callable)
		button.pressed.connect(start_run.bind(false, 0, key, selected_run_mode))
		if infinite:
			button.text = {"easy":"FÁCIL / 25% DOS COINS\nEscalada mais lenta, mas sem limite. Sem contratos.", "medium":"MÉDIO / 100% DOS COINS\nHordas crescentes, chefes a cada 3 hordas. Todas as espécies.", "hard":"DIFÍCIL / 150% DOS COINS\nMais inimigos desde o início. Hordas maiores e inimigos mais fortes."}[key]
		else:
			button.text = {"easy":"FÁCIL / 25% DOS COINS\nHordas menores e inimigos mais fracos. Sem contratos.", "medium":"MÉDIO / 100% DOS COINS\nCombate padrão. Contratos disponíveis.", "hard":"DIFÍCIL / 150% DOS COINS\nHordas maiores e inimigos mais rápidos. Contratos disponíveis."}[key]

func update_menu_clock() -> void:
	if state == "menu" and is_instance_valid(panel) and panel.name == "MainMenu":
		panel.find_child("Eyebrow", true, false).text = preferences.clock_text() + "    /    JOGADO " + preferences.play_time_text()

func show_settings() -> void:
	state = "settings"
	show_screen("settings")
	var slider: HSlider = panel.find_child("VolumeSlider", true, false)
	slider.value = preferences.volume
	slider.value_changed.connect(set_volume)
	var mute: Button = panel.find_child("MuteButton", true, false)
	mute.button_pressed = preferences.muted
	mute.toggled.connect(set_muted)
	for channel: String in ["music", "sfx", "ui"]:
		var node_name: String = {"music": "Music", "sfx": "Sfx", "ui": "Ui"}[channel]
		var channel_slider: HSlider = panel.find_child(node_name + "Slider", true, false)
		channel_slider.value = preferences.get(channel + "_volume")
		channel_slider.value_changed.connect(set_channel_volume.bind(channel))
	var resolution: OptionButton = panel.find_child("Resolution", true, false)
	for size: Vector2i in UserSettings.RESOLUTIONS:
		resolution.add_item("%d × %d" % [size.x, size.y])
	resolution.select(preferences.resolution_index)
	resolution.disabled = not preferences.desktop_video_available()
	resolution.item_selected.connect(set_resolution)
	var fullscreen: CheckButton = panel.find_child("Fullscreen", true, false)
	fullscreen.button_pressed = preferences.fullscreen
	fullscreen.disabled = not preferences.desktop_video_available()
	fullscreen.toggled.connect(set_fullscreen)
	var preset: OptionButton = panel.find_child("KeyboardPreset", true, false)
	preset.add_item("MOVER: WASD / TIRO: SETAS")
	preset.add_item("MOVER: SETAS / TIRO: WASD")
	preset.select(preferences.keyboard_preset)
	preset.item_selected.connect(set_keyboard_preset)
	var touch: OptionButton = panel.find_child("TouchMode", true, false)
	for text: String in ["TOQUE: AUTOMÁTICO", "TOQUE: ATIVADO", "TOQUE: DESATIVADO"]:
		touch.add_item(text)
	touch.select(preferences.touch_mode)
	touch.item_selected.connect(set_touch_mode)
	var bindings: GridContainer = panel.find_child("Bindings", true, false)
	for action: String in controls.DEFAULT_KEYS:
		var label := Label.new()
		label.text = controls.LABELS[action]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bindings.add_child(label)
		var button := Button.new()
		button.name = "Bind_" + action
		button.custom_minimum_size = Vector2(170, 44)
		button.text = controls.key_text(action)
		button.pressed.connect(begin_rebind.bind(action))
		bindings.add_child(button)
	var password: LineEdit = panel.find_child("DeveloperPassword", true, false)
	password.text_submitted.connect(func(_text: String): unlock_developer())
	bind_button("UnlockDeveloperButton", unlock_developer)
	bind_button("DeveloperTestsButton", show_test_menu)
	bind_button("LockDeveloperButton", lock_developer)
	refresh_developer_settings()
	bind_button("TestSoundButton", test_volume)
	bind_button("BackButton", show_menu)
	panel.find_child("Tabs", true, false).tab_changed.connect(settings_tab_changed)
	refresh_audio_settings()

func refresh_developer_settings() -> void:
	if state != "settings" or not is_instance_valid(panel): return
	panel.find_child("DeveloperPassword",true,false).visible = not developer_unlocked
	panel.find_child("UnlockDeveloperButton",true,false).visible = not developer_unlocked
	panel.find_child("DeveloperTestsButton",true,false).visible = developer_unlocked
	panel.find_child("LockDeveloperButton",true,false).visible = developer_unlocked
	panel.find_child("DeveloperNotice",true,false).text = "Acesso liberado nesta sessão." if developer_unlocked else "Área restrita ao desenvolvedor. Digite a senha para acessar os testes."

func unlock_developer() -> void:
	if state != "settings" or not is_instance_valid(panel): return
	var password: LineEdit = panel.find_child("DeveloperPassword",true,false)
	var valid := password.text.sha256_text() == DEVELOPER_PASSWORD_HASH
	password.clear()
	if not valid:
		panel.find_child("DeveloperNotice",true,false).text = "Senha incorreta."
		play_sfx("error")
		password.grab_focus()
		return
	developer_unlocked = true
	refresh_developer_settings()
	panel.find_child("DeveloperTestsButton",true,false).grab_focus()
	play_sfx("purchase")

func lock_developer() -> void:
	developer_unlocked = false
	if state == "settings":
		panel.find_child("DeveloperPassword",true,false).clear()
		refresh_developer_settings()
		panel.find_child("DeveloperPassword",true,false).grab_focus()

func set_volume(value: float) -> void:
	preferences.volume = clampf(value, 0, 100)
	preferences.apply_audio()
	refresh_audio_settings()
	preferences_timer.start()

func set_muted(value: bool) -> void:
	preferences.muted = value
	preferences.apply_audio()
	refresh_audio_settings()
	preferences_timer.start()

func refresh_audio_settings() -> void:
	if state != "settings" or not is_instance_valid(panel):
		return
	for channel: String in ["music", "sfx", "ui"]:
		var node_name: String = {"music": "Music", "sfx": "Sfx", "ui": "Ui"}[channel]
		panel.find_child(node_name + "Value", true, false).text = "%d%%" % int(preferences.get(channel + "_volume"))
	panel.find_child("VolumeValue", true, false).text = "%d%%" % int(preferences.volume)
	panel.find_child("MuteButton", true, false).text = "MUDO: ATIVADO" if preferences.muted else "MUDO: DESATIVADO"
	panel.find_child("TestSoundButton", true, false).disabled = preferences.muted or preferences.volume <= 0 or preferences.sfx_volume <= 0

func test_volume() -> void:
	if preferences.muted or preferences.volume <= 0 or preferences.sfx_volume <= 0:
		return
	var sound: AudioStreamPlayer = panel.find_child("PreviewSound", true, false)
	if sound.stream == null:
		sound.stream = preferences.test_tone()
	sound.play()

func save_preferences() -> void:
	if is_instance_valid(preferences_timer):
		preferences_timer.stop()
	if not smoke_mode and preferences.save_settings() != OK:
		if state == "settings" and is_instance_valid(panel):
			panel.find_child("SettingsNotice", true, false).text = "Não foi possível salvar. Ajustes mantidos nesta sessão."

func show_permanent_shop() -> void:
	settle_run()
	permanent_tab = "attributes"
	state = "permanent"
	show_screen("permanent")
	for index in Progression.UPGRADES.size():
		bind_button("PermanentBuy%d" % (index + 1), buy_permanent.bind(index))
	bind_button("BackButton", show_menu)
	for tab: String in ["attributes", "skills", "equipment", "prestige", "skins"]:
		bind_button(tab.capitalize() + "Tab", set_permanent_tab.bind(tab))
	for index in Progression.ABILITIES.size():
		bind_button("AbilityBuy%d" % (index + 1), buy_ability.bind(index))
	bind_button("OriginalWeaponButton", equip_player_weapon.bind("original"))
	bind_button("ShotgunWeaponButton", equip_player_weapon.bind("shotgun"))
	bind_button("AstronautSkinButton", equip_player_skin.bind("astronaut"))
	bind_button("GuanapoSkinButton", equip_player_skin.bind("guanapo"))
	bind_button("PrestigeButton", request_prestige)
	panel.find_child("PrestigeConfirmation", true, false).confirmed.connect(perform_prestige)
	refresh_permanent_shop()

func refresh_permanent_shop() -> void:
	panel.find_child("PermanentWallet", true, false).text = "COINS %d    SPACECOIN %d    PRESTÍGIO %d" % [progression.coins, progression.space_coins, progression.prestige]
	for index in Progression.UPGRADES.size():
		var upgrade: Dictionary = Progression.UPGRADES[index]
		panel.find_child("PermanentBuy%d" % (index + 1), true, false).find_child("Effect", true, false).text = upgrade.effect
		var level: int = progression.levels[upgrade.key]
		var cost := progression.price(index)
		panel.find_child("PermanentLevel%d" % (index + 1), true, false).text = "NÍVEL %d/%d  /  %s" % [level, progression.max_level(upgrade.key), progression.bonus_text(upgrade.key)]
		var button: Button = panel.find_child("PermanentBuy%d" % (index + 1), true, false)
		panel.find_child("PermanentCost%d" % (index + 1), true, false).text = "NÍVEL MÁXIMO" if cost < 0 else "COMPRAR   /   %d COINS" % cost
		button.disabled = cost < 0 or progression.coins < cost
		button.get_node("Margin").modulate = Color(1, 1, 1, 0.75) if button.disabled else Color.WHITE
		button.tooltip_text = "Melhoria permanente. Ativa a partir da próxima expedição."
	panel.find_child("PermanentProgress", true, false).text = "100 PONTOS = 1 COIN  /  Progresso acumulado: %d/100 pontos" % progression.remainder
	panel.find_child("PrestigeRequirements", true, false).text = "ATRIBUTOS NO MÁXIMO %d/%d  /  COINS %d/%d" % [progression.maxed_attributes(), Progression.UPGRADES.size(), progression.coins, Progression.PRESTIGE_COST]
	panel.find_child("PrestigeButton", true, false).disabled = not progression.can_prestige()
	for index in Progression.ABILITIES.size():
		var ability: Dictionary = Progression.ABILITIES[index]
		var level: int = progression.abilities[ability.key]
		var price: int = progression.ability_price(index)
		panel.find_child("AbilityLevel%d" % (index + 1), true, false).text = ("NÍVEL %d/5 / MOEDAS %d px / ITENS %d px" % [level, 80 + level * 40, 24 + level * 40]) if index == 0 else ("DESBLOQUEADO / UMA VEZ POR RUN" if level > 0 else "BLOQUEADO")
		panel.find_child("AbilityCost%d" % (index + 1), true, false).text = ("NÍVEL MÁXIMO" if index == 0 else "ADQUIRIDO") if price < 0 else "COMPRAR / %d SPACECOIN" % price
		panel.find_child("AbilityBuy%d" % (index + 1), true, false).disabled = price < 0 or progression.space_coins < price
	for key: String in Progression.Skins.DATA:
		var prefix := "Astronaut" if key == "astronaut" else "Guanapo"
		var button: Button = panel.find_child(prefix+"SkinButton",true,false)
		button.text = "EQUIPADA" if progression.selected_skin == key else ("EQUIPAR" if key in progression.owned_skins else "COMPRAR / 1 PRESTÍGIO")
		button.disabled = progression.selected_skin == key or (key not in progression.owned_skins and progression.prestige < 1)
	for key: String in ["original","shotgun"]:
		var button: Button = panel.find_child("OriginalWeaponButton" if key == "original" else "ShotgunWeaponButton",true,false)
		var owned: bool = key in progression.owned_weapons
		var status := "EQUIPADA" if progression.selected_weapon == key else ("EQUIPAR" if owned else "COMPRAR / %d SPACECOIN" % Progression.SHOTGUN_COST)
		button.text = ("ARMA ORIGINAL\nTIRO SIMPLES\n" if key == "original" else "ESPINGARDA\n3 PROJÉTEIS\n") + status
		button.disabled = progression.selected_weapon == key or (not owned and progression.space_coins < Progression.SHOTGUN_COST)
	set_permanent_tab(permanent_tab)

func equip_player_weapon(key: String) -> bool:
	if state != "permanent": return false
	if not progression.equip_weapon(key, not smoke_mode):
		panel.find_child("PermanentNotice",true,false).text = "Compra recusada: SpaceCoin insuficiente ou falha ao salvar."
		play_sfx("error")
		return false
	refresh_permanent_shop()
	panel.find_child("PermanentNotice",true,false).text = "Espingarda equipada para a próxima run." if key == "shotgun" else "Arma original equipada para a próxima run."
	play_sfx("purchase")
	return true

func set_permanent_tab(tab: String) -> void:
	if state != "permanent" or tab not in ["attributes", "skills", "equipment", "prestige", "skins"]:
		return
	permanent_tab = tab
	for key: String in ["attributes", "skills", "equipment", "prestige", "skins"]:
		panel.find_child(key.capitalize(), true, false).visible = key == tab
		panel.find_child(key.capitalize() + "Tab", true, false).theme_type_variation = &"PrimaryButton" if key == tab else &""
	panel.find_child("PermanentProgress", true, false).visible = tab == "attributes"
	panel.find_child("PermanentNotice", true, false).text = {
		"attributes": "Coins melhoram os atributos iniciais das próximas runs.",
		"skills": "SpaceCoin compra habilidades permanentes. Elas permanecem após o Prestígio.",
		"equipment": "SpaceCoin desbloqueia equipamentos permanentes. Escolha a arma da próxima run.",
		"prestige": "CICLO %d • +1 nível máximo por reset. Inimigos +18%% de vida/ciclo." % progression.prestige_cycles,
		"skins": "Aparências cosméticas. Sua escolha fica salva para as próximas runs."
	}[tab]

func equip_player_skin(key: String) -> bool:
	if state != "permanent": return false
	if not progression.equip_skin(key,not smoke_mode):
		panel.find_child("PermanentNotice",true,false).text = "Prestígio insuficiente ou falha ao salvar."
		play_sfx("error")
		return false
	refresh_permanent_shop()
	panel.find_child("PermanentNotice",true,false).text = "Skin equipada: "+str(Progression.Skins.DATA[key].title)
	play_sfx("purchase")
	return true

func request_prestige() -> void:
	if state != "permanent" or not progression.can_prestige():
		return
	panel.find_child("PrestigeConfirmation", true, false).popup_centered()

func perform_prestige() -> bool:
	if state != "permanent":
		return false
	if not progression.reset_for_prestige(not smoke_mode):
		panel.find_child("PermanentNotice", true, false).text = "Reset recusado: requisitos incompletos ou falha ao salvar."
		play_sfx("error")
		return false
	refresh_permanent_shop()
	panel.find_child("PermanentNotice", true, false).text = "+1 PRESTÍGIO • Atributos zerados. Um novo ciclo começa."
	play_sfx("purchase")
	return true

func buy_permanent(index: int) -> bool:
	if state != "permanent":
		return false
	if not progression.buy(index, not smoke_mode):
		panel.find_child("PermanentNotice", true, false).text = "Compra recusada: saldo insuficiente, nível máximo ou falha ao salvar."
		return false
	refresh_permanent_shop()
	panel.find_child("PermanentNotice", true, false).text = "%s aprimorado. O bônus estará ativo na próxima run." % Progression.UPGRADES[index].name
	play_sfx("purchase")
	return true

func show_controls() -> void:
	show_screen("controls")
	var movement: Label = panel.get_node("Center/Card/Box/Instructions/Movement/Keys")
	movement.text = "[%s %s %s %s] Mover\n[Mouse / teclas de tiro] Atirar\n[%s] Dash / [%s] Berserk\n[%s] Pausar\n\nJoystick: dois analógicos\nCelular: dois direcionais de toque" % [controls.key_text("up"), controls.key_text("left"), controls.key_text("down"), controls.key_text("right"), controls.hint("dash"), controls.hint("berserk"), controls.hint("pause")]
	panel.get_node("Center/Card/Box/Instructions/Equipment/Keys").text = "[%s] Eco: voltar 5s\n[%s / %s] Consumíveis\n[%s] Equipamento no chão\n[%s] Embarcar no rover\n\nEco: uma carga por arena.\n3 chances por run inteira." % [controls.hint("rewind"), controls.hint("slot_one"), controls.hint("slot_two"), controls.hint("slot_three"), controls.hint("interact")]
	bind_button("BackButton", show_menu)

func close_panel() -> void:
	remap_action = ""
	if is_instance_valid(panel):
		panel.get_parent().remove_child(panel)
		panel.queue_free()
	panel = null

func show_screen(screen_name: String) -> void:
	if screen_name in ["menu", "controls", "settings", "permanent", "test", "result", "difficulty"]:
		$PlanetMusic.stop()
		planet_music_index = -1
	if screen_name in ["menu", "controls", "settings", "permanent", "test", "difficulty"]:
		$GameAudio.death_voice.stop()
	if screen_name in ["menu", "controls", "settings", "permanent", "test", "difficulty"] and not $MenuMusic.playing:
		$MenuMusic.stream = menu_loop_stream if menu_intro_completed else MENU_INTRO
		$MenuMusic.play()
	close_panel()
	panel = SCREENS[screen_name].instantiate()
	$UI/ScreenHost.add_child(panel)
	var focus_names := {"menu": "StartButton", "controls": "BackButton", "pause": "ResumeButton", "shop": "LeaveButton", "result": "RestartButton", "permanent": "BackButton", "settings": "VolumeSlider", "test": "BackButton", "difficulty": "MediumButton", "death": "ContinueButton"}
	if focus_names.has(screen_name):
		panel.find_child(focus_names[screen_name], true, false).grab_focus()

func bind_button(node_name: String, action: Callable) -> void:
	var button: Button = panel.find_child(node_name, true, false)
	button.pressed.connect(action)
	button.pressed.connect(func(): play_sfx("ui_click"))

func play_sfx(event: String, at: Vector2 = Vector2.INF) -> bool:
	return $GameAudio.play_event(event, at)

func on_menu_music_finished() -> void:
	menu_intro_completed = true
	if state in ["menu", "settings", "permanent", "testing", "difficulty"]:
		$MenuMusic.stream = menu_loop_stream
		$MenuMusic.play()

func configure_camera() -> void:
	var camera: Camera2D = $Camera2D
	# Leave room for the fixed HUD and first-arena tutorial at map edges.
	camera.limit_left = int(arena.position.x) - 64
	camera.limit_top = int(arena.position.y) - 104
	camera.limit_right = int(arena.end.x) + 64
	camera.limit_bottom = int(arena.end.y) + 56
	camera.position = player.position
	camera.reset_smoothing()
	camera.force_update_scroll()

func _process(delta: float) -> void:
	$PlanetMusic.pitch_scale = planet_music_rate()
	$PlanetMusic.volume_db = -80.0 if smoke_mode else (-23.0 if state in ["shop", "paused", "death", "cleared", "travel"] else -16.0)
	if state in ["menu", "settings", "permanent", "testing", "difficulty"] and not $MenuMusic.playing:
		on_menu_music_finished()
	if state in ["playing", "cleared", "exit"]:
		$Camera2D.position = player.position
		preferences.played_seconds += delta if not practice_mode else 0
		preferences_autosave += delta
		if preferences_autosave >= 30:
			preferences_autosave = 0
			save_preferences()
	menu_clock_tick += delta
	if menu_clock_tick >= 1:
		menu_clock_tick = 0
		update_menu_clock()
	$UI/HUD.update_game(self)

func text_at(at: Vector2, text: String, size: int, color: Color = Color("e0e8f3")) -> void:
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func frost_active() -> bool:
	return planet_index == 1 and (state == "playing" or (state == "paused" and paused_from == "playing")) and fmod(environment_clock, 7.0) >= 5.0

func frost_slowdown(at: Vector2) -> float:
	if run_mode == "endless": return weather.player_slowdown(at)
	if planet_index == 1 and frost_active():
		for hazard in hazards:
			if at.distance_to(hazard) < 54:
				return 0.6
	return 1.0

func neptune_wind() -> Vector2:
	return Vector2(70, -16) if planet_index == 1 and frost_active() else Vector2.ZERO

func _draw() -> void:
	for i in 90:
		var star := Vector2(fmod(i * 173.7, 1152), fmod(i * 97.3, 720))
		if arena.has_point(star):
			continue
		draw_rect(Rect2(star.snapped(Vector2(4, 4)), Vector2(2, 2)), Color(0.45, 0.6, 0.8, 0.3))
	for hazard in hazards:
		var active := frost_active()
		var warning := state in ["playing", "paused"] and fmod(environment_clock, 7.0) >= 3.5
		draw_circle(hazard, 54, Color(0.36, 0.76, 1, 0.23 if active else (0.1 if warning else 0.035)))
		draw_arc(hazard, 54, 0, TAU, 24, Color("b7f2ff") if warning else Color("41738e"), 3 if warning else 2)
		for branch in 4:
			var direction := Vector2.RIGHT.rotated(branch * PI / 2)
			draw_line(hazard + direction * 12, hazard + direction * 36, Color("78cef5"), 2)
		if warning:
			text_at(hazard + Vector2(-32, 6), "GEADA" if active else "AVISO", 18, Color("d4f6ff"))
	if planet_index == 1 and state == "playing":
		for i in 28:
			var at := arena.position + Vector2(fmod(i * 97 + environment_clock * (130 if frost_active() else 32), arena.size.x), fposmod(i * 71 - environment_clock * 18, arena.size.y))
			Vfx.draw_particle(self, at, Vector2.ONE * 12, 2, (i+int(environment_clock*5))%4, Color(1,1,1,0.3 if frost_active() else 0.14))
	for effect in effects:
		draw_arc(effect.pos, (0.4 - effect.life) * 85 + 5, 0, TAU, 20, Color(effect.color, effect.life * 2), 3)
	if is_instance_valid(player):
		if state in ["cleared", "exit"]:
			var arrow: Vector2 = player.position.direction_to(portal)
			var tip: Vector2 = player.position + arrow * 65
			draw_line(player.position + arrow * 35, tip, Color("71e4c5"), 4)
			draw_line(tip, tip - arrow.rotated(0.55) * 15, Color("71e4c5"), 4)
			draw_line(tip, tip - arrow.rotated(-0.55) * 15, Color("71e4c5"), 4)
		elif state == "playing" and pending == 0 and enemies.get_child_count() > 0:
			var target: Node2D = enemies.get_child(0)
			var direction: Vector2 = player.position.direction_to(target.position)
			draw_line(player.position + direction * 34, player.position + direction * 48, Color(1, 1, 1, 0.4), 2)

func reward_planet_superboss() -> void:
	if run_mode != "campaign" or room >= 12 or (room + 1) % ARENAS_PER_PLANET != 0 or rewarded_superboss_rooms.has(room): return
	rewarded_superboss_rooms.append(room)
	run_chances_left += 1
	message = "SUPERCHEFE VENCIDO / +1 CHANCE / %d RESTANTES" % run_chances_left
	message_time = 4
	fx.floating(player.position + Vector2(0, -40), "+1 CHANCE", Color("81edac"))

func planet_music_rate() -> float:
	var mode: float = {"easy":0.96,"medium":1.0,"hard":1.08}[run_difficulty]
	return mode * (1.0 + (room % ARENAS_PER_PLANET) * 0.025 if run_mode != "endless" else 1.0 + minf(survival.tier * 0.01, 0.2))

func play_planet_music() -> void:
	$PlanetMusic.pitch_scale = planet_music_rate()
	if planet_music_index != planet_index or not $PlanetMusic.playing:
		planet_music_index = planet_index
		planet_music_stream = load("res://assets/audio/music/%s.wav" % ["mars", "neptune", "jupiter"][mini(planet_index, 2)]).duplicate()
		planet_music_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		planet_music_stream.loop_begin = 0
		planet_music_stream.loop_end = int(round(planet_music_stream.get_length() * planet_music_stream.mix_rate))
		$PlanetMusic.stream = planet_music_stream
		$PlanetMusic.volume_db = -80.0 if smoke_mode else -16.0
		$PlanetMusic.play()

func enemy_ability_rate() -> float:
	var stage: int = survival.tier if run_mode == "endless" else room
	var mode: float = {"easy":0.9,"medium":1.0,"hard":1.1}[run_difficulty]
	return (1.2+minf(stage*0.025,0.4))*mode

func enemy_damage() -> int:
	return 1 + progression.prestige_cycles / 4

func restart_current_run() -> void:
	start_run(practice_mode, room if practice_mode else 0, run_difficulty, run_mode)

func show_test_menu() -> void:
	if not developer_unlocked: return
	settle_run()
	state = "testing"
	show_screen("test")
	for index in total_rooms():
		bind_button("TestArena%d" % (index + 1), start_practice.bind(index, false))
		bind_button("TestBoss%d" % (index + 1), start_practice.bind(index, true))
	bind_button("BackButton", show_menu)

func start_practice(index: int, boss_only: bool = false) -> void:
	if not developer_unlocked: return
	var equipment: int = panel.find_child("TestEquipment", true, false).selected
	practice_invincible = panel.find_child("TestInvincible", true, false).button_pressed
	practice_equipment = ["mine", "turret", "beacon"][equipment]
	start_run(true, index)
	loot.coins = 999
	loot.slots.assign(["bomb", "shield"])
	if boss_only:
		pending = 0
		phase_kills = wave_total
		begin_boss()
	message = "TESTE • habilidades liberadas. [F] Berserk / [3] Equipamento. Sem recompensas."
	message_time = 5

func buy_ability(index: int) -> bool:
	if state != "permanent":
		return false
	if not progression.buy_ability(index, not smoke_mode):
		panel.find_child("PermanentNotice", true, false).text = "Compra recusada: SpaceCoin insuficiente, limite ou falha ao salvar."
		play_sfx("error")
		return false
	refresh_permanent_shop()
	panel.find_child("PermanentNotice", true, false).text = "%s adquirida. Disponível na próxima run." % Progression.ABILITIES[index].name
	play_sfx("purchase")
	return true

func can_use_berserk() -> bool:
	return practice_mode or int(progression.abilities.berserk) > 0

func activate_berserk() -> bool:
	if state != "playing" or not is_instance_valid(player):
		return false
	if (run_mode == "endless" and (berserk_cd > 0 or player.berserk_time > 0)) or (run_mode != "endless" and berserk_used):
		return false
	if not can_use_berserk():
		message = "Desbloqueie BERSERK na aba Habilidades da Loja."
		message_time = 2
		return false
	berserk_used = true
	if run_mode == "endless": berserk_cd = ENDLESS_BERSERK_COOLDOWN
	player.berserk_time = 6.0
	player.cooldown = 0
	play_sfx("overdrive")
	fx.explosion(player.position, Color("ffad70"), 80)
	message = "BERSERK • dispare em todas as direções!"
	message_time = 2
	return true

func handle_player_death() -> void:
	if state != "playing" or player.health > 0:
		return
	$GameAudio.play_death()
	$PlanetMusic.stream_paused = true
	contracts.record("death")
	run_chances_left = maxi(0, run_chances_left - 1)
	player.berserk_time = 0
	if run_chances_left == 0:
		finish(false, "Todas as chances desta expedição acabaram.", false)
		return
	state = "death"
	player.velocity = Vector2.ZERO
	show_screen("death")
	panel.find_child("Chances", true, false).text = "%d CHANCES RESTANTES NA RUN" % run_chances_left
	bind_button("ContinueButton", continue_after_death)
	bind_button("MenuButton", show_menu)

func continue_after_death() -> void:
	if state != "death" or not run_active or run_chances_left <= 0:
		return
	$GameAudio.death_voice.stop()
	$PlanetMusic.stream_paused = false
	close_panel()
	var candidates: Array[Vector2] = [$Arena/PlayerSpawn.global_position, arena.get_center()]
	candidates.append_array($Arena.spawn_gates())
	var safest: Vector2 = $Arena/PlayerSpawn.global_position
	var best_distance := -1.0
	for candidate in candidates:
		if blocked(candidate, 18) or not arena.grow(-18).has_point(candidate):
			continue
		var nearest := INF
		for enemy in enemies.get_children():
			if not enemy.is_queued_for_deletion():
				nearest = minf(nearest, candidate.distance_to(enemy.position))
		if nearest > best_distance:
			best_distance = nearest
			safest = candidate
	player.position = safest
	player.health = player.max_health
	player.velocity = Vector2.ZERO
	player.dash_time = 0
	player.dash_cd = 0
	player.immunity = 3.0
	weather.clear_active(8.0)
	player.history.clear()
	player.echo_frames.clear()
	for bullet in bullets.get_children():
		if bullet.hostile:
			bullet.queue_free()
	encounters.reset()
	if is_instance_valid(boss_ref) and not boss_ref.is_queued_for_deletion():
		boss_ref.super_followups.clear()
		boss_ref.super_telegraph = 0
		boss_ref.super_attack_timer = 1.8
	configure_camera()
	fx.explosion(player.position, Color("91eaff"), 90)
	play_sfx("heal")
	state = "playing"
	message = "TRAJE RECONSTRUÍDO • %d CHANCES RESTANTES" % run_chances_left
	message_time = 3

func set_channel_volume(value: float, channel: String) -> void:
	preferences.set(channel + "_volume", clampf(value, 0, 100))
	preferences.apply_audio()
	refresh_audio_settings()
	preferences_timer.start()

func set_resolution(index: int) -> void:
	preferences.resolution_index = clampi(index, 0, UserSettings.RESOLUTIONS.size()-1)
	preferences.apply_video()
	preferences_timer.start()

func set_fullscreen(value: bool) -> void:
	preferences.fullscreen = value
	preferences.apply_video()
	preferences_timer.start()

func set_keyboard_preset(index: int) -> void:
	preferences.keyboard_preset = clampi(index, 0, 1)
	preferences.keybinds.clear()
	remap_action = ""
	controls.configure()
	refresh_key_buttons()
	preferences_timer.start()

func set_touch_mode(index: int) -> void:
	preferences.touch_mode = clampi(index, 0, 2)
	touch_controls.release_all()
	preferences_timer.start()

func refresh_key_buttons() -> void:
	if state != "settings" or not is_instance_valid(panel): return
	for action: String in controls.DEFAULT_KEYS:
		panel.find_child("Bind_" + action, true, false).text = controls.key_text(action)

func begin_rebind(action: String) -> void:
	remap_action = action
	panel.find_child("SettingsNotice", true, false).text = "%s: pressione a nova tecla. Esc cancela." % controls.LABELS[action]

func _input(event: InputEvent) -> void:
	if state != "settings" or remap_action.is_empty(): return
	if event is InputEventKey and event.pressed and not event.echo:
		var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if code != KEY_ESCAPE:
			controls.rebind(remap_action, code)
			preferences_timer.start()
		remap_action = ""
		refresh_key_buttons()
		panel.find_child("SettingsNotice", true, false).text = "Teclas atualizadas. Selecionar um preset restaura as teclas padrão."
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and remap_action.is_empty():
		if state in ["settings", "difficulty", "testing", "permanent"]:
			show_menu()
			get_viewport().set_input_as_handled()
		elif state == "paused" and is_instance_valid(panel) and not event.is_action_pressed("pause"):
			panel.find_child("ResumeButton", true, false).pressed.emit()
			get_viewport().set_input_as_handled()

func pause_run() -> void:
	if state not in ["playing", "cleared", "exit"]: return
	paused_from = state
	var previous := state
	state = "paused"
	touch_controls.release_all()
	show_screen("pause")
	bind_button("ResumeButton", func(): state = previous; close_panel())
	bind_button("RestartButton", restart_current_run)
	bind_button("MenuButton", show_menu)

func on_joy_connection_changed(_device: int, connected: bool) -> void:
	if not connected and controls.last_device == "joypad":
		pause_run()

func settings_tab_changed(index: int) -> void:
	remap_action = ""
	panel.find_child("SettingsNotice", true, false).text = "Clique numa tecla para remapear. Esc cancela; teclas repetidas são trocadas." if index == 2 else "Os ajustes são salvos automaticamente."
	if index == 3:
		panel.find_child("SettingsNotice",true,false).text = "O acesso de desenvolvedor vale apenas para esta sessão."
		if not developer_unlocked: panel.find_child("DeveloperPassword",true,false).grab_focus()

func start_transfer() -> bool:
	if state != "exit" or player.position.distance_to(portal) >= EXTRACTION_RANGE:
		return false
	travel_kind = extraction_vehicle()
	state = "travel"
	travel_clock = 0
	player.velocity = Vector2.ZERO
	touch_controls.release_all()
	weather.clear_active()
	play_sfx("stage_clear")
	show_screen("travel")
	panel.game = self
	$GameAudio.play_transport(travel_kind)
	return true

func extraction_vehicle() -> String:
	if room >= total_rooms()-1:
		return "rocket"
	return "rocket" if (room+1) / ARENAS_PER_PLANET != room / ARENAS_PER_PLANET else "rover"

func extraction_name() -> String:
	return "ROVER" if extraction_vehicle() == "rover" else "FOGUETE"

func clear_combat_effects() -> void:
	weather.clear_active()
	encounters.reset()
	deployables.clear_room()
	clear_container(bullets)
	hazards.clear()
	effects.clear()
	fx.particles.clear()
	fx.labels.clear()
	fx.shake = 0
	fx.queue_redraw()
	flash = 0
	player.echo_frames.clear()
	player.dash_time = 0
	player.velocity = Vector2.ZERO
	player.queue_redraw()
	queue_redraw()

func finish_arena() -> void:
	if state != "playing" or room_cleared: return
	room_cleared = true
	score += int(time_left)*10
	clear_combat_effects()
	state = "cleared"
	collection_left = COLLECTION_DURATION
	extraction_boarded = false
	extraction_penalty = 0
	message = "EMBARQUE EM %ds / Atraso: perde inventário e 1/3 das moedas." % int(COLLECTION_DURATION)
	message_time = 0
	play_sfx("stage_clear")
	$GameAudio.sync_state()

func board_after_clear(automatic: bool = false) -> bool:
	if state != "cleared": return false
	if not automatic and player.position.distance_to(portal) >= EXTRACTION_RANGE: return false
	if automatic:
		extraction_penalty = ceili(loot.coins / 3.0)
		loot.coins -= extraction_penalty
		loot.slots.assign(["", ""])
		deployables.inventory = ""
	extraction_boarded = true
	player.velocity = Vector2.ZERO
	open_shop()
	return true

func extraction_pulse() -> float:
	if state != "cleared": return 0.0
	var urgent := collection_left <= 10.0
	return (0.10 if urgent else 0.035) + (0.12 if urgent else 0.05) * (0.5 + 0.5 * sin((COLLECTION_DURATION-collection_left)*TAU*(1.5 if urgent else 0.75)))

func update_shop_clock() -> void:
	if state != "shop" or not is_instance_valid(panel): return
	var clock: Label = panel.find_child("ShopTimer",true,false)
	clock.text = "%02ds" % ceili(shop_left)
	clock.tooltip_text = "Embarque automático ao zerar. Comprar ou trocar ofertas não reinicia o prazo."
	clock.modulate = Color("ff657b") if shop_left <= 5 else Color("ffdf72")
