extends SceneTree

var game: Node2D
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, detail: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + detail)
	else:
		print("PASS: " + detail)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	check(game.panel.find_child("StartButton", true, false) != null, "main menu loads authored scene nodes")
	game.panel.find_child("ControlsButton", true, false).pressed.emit()
	check(game.panel.name == "Controls", "how-to-play button opens controls scene")
	game.panel.find_child("BackButton", true, false).pressed.emit()
	check(game.panel.name == "MainMenu", "controls returns to main menu")
	check(game.panel.find_child("Title", true, false).get_theme_font("font").resource_path.ends_with("After Burner Neue.ttf"), "only main title retains After Burner")
	game.start_run()
	# Manual deterministic simulation; tree frames still drain queue_free.
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	check(game.state == "playing" and game.pending == 36, "run starts with first wave")
	check(game.total_rooms() == 13, "campaign includes thirteen authored arenas")
	check(game.get_node("UI/HUD").theme.default_font.resource_path.ends_with("W95F.otf"), "HUD inherits requested font")
	check(game.get_node("UI/HUD/TopBar").size.y == 72, "HUD uses compact 72px header")
	var pillar: ColorRect = game.get_node("Arena/Obstacles/PillarA")
	var cover_bounds := pillar.get_global_rect()
	check(game.blocked(cover_bounds.get_center(), 13), "pillars block actors and shots")
	var original_position := pillar.position
	pillar.position += Vector2(400, 80)
	game.get_node("Arena").apply_to(game)
	check(not game.blocked(cover_bounds.get_center(), 13) and game.blocked(pillar.get_global_rect().get_center(), 13), "moving scene pillar also moves collision")
	pillar.position = original_position
	game.get_node("Arena").apply_to(game)
	var wall_start := Vector2(cover_bounds.position.x - 16, cover_bounds.get_center().y)
	game.player.position = wall_start
	game.move_actor(game.player, Vector2(30, 0), 13)
	check(game.player.position == wall_start, "movement cannot cross pillar")
	game.player.position = Vector2(180, 386)
	game.player.immunity = 0
	game.player.hurt(1)
	check(game.player.health == 4, "contact damage")
	game.player.hurt(1)
	check(game.player.health == 4, "damage immunity prevents stacked hits")
	game.player.health = 5
	Input.action_press("fire")
	for i in 310:
		game.player._physics_process(1.0 / 60.0)
	Input.action_release("fire")
	game.player.health = 2
	game.player.position += Vector2(50, 0)
	var before: float = game.time_left
	game.player.rewind()
	check(game.player.health == 5 and not game.player.rewind_ready, "rewind restores life and consumes charge")
	check(game.time_left > before + 4.8 and not game.player.echo_frames.is_empty(), "rewind restores clock and creates replay")
	game.clear_container(game.bullets)
	for i in 60:
		game.player._physics_process(1.0 / 60.0)
	check(game.bullets.get_child_count() > 0, "echo replays recorded shots")
	game.clear_container(game.bullets)
	game.spawn_enemy()
	var target = game.enemies.get_child(0)
	target.set_physics_process(false)
	target.position = Vector2(550, 220)
	game.shoot(Vector2(520, 220), Vector2.RIGHT, 1, false)
	var bullet = game.bullets.get_child(0)
	bullet.set_physics_process(false)
	var enemy_health: float = target.health
	bullet._physics_process(0.008)
	check(target.health < enemy_health, "allied projectile collides and damages enemy")
	game.player.position = Vector2(520, 220)
	game.player.immunity = 0
	game.shoot(Vector2(480, 220), Vector2.RIGHT, 1, true)
	var hostile = game.bullets.get_child(game.bullets.get_child_count() - 1)
	hostile.set_physics_process(false)
	var life: int = game.player.health
	hostile._physics_process(0.01)
	check(game.player.health == life - 1, "hostile projectile damages astronaut")
	game.player.dash_cd = 0
	game.player.set_physics_process(true)
	Input.action_press("dash")
	await physics_frame
	await process_frame
	Input.action_release("dash")
	game.player.set_physics_process(false)
	check(game.player.dash_cd > 0 and game.player.immunity > 0, "dash grants immunity and starts cooldown")
	game.apply_upgrade("spread")
	game.apply_upgrade("rate")
	game.apply_upgrade("health")
	game.apply_upgrade("speed")
	game.apply_upgrade("damage")
	game.apply_upgrade("time")
	check(game.player.spread == 1 and game.player.max_health == 6 and game.time_bonus == 8, "all upgrade types apply")
	game.player.immunity = 100
	game.player.position = Vector2(cover_bounds.end.x + 120, cover_bounds.get_center().y)
	target.position = Vector2(cover_bounds.position.x - 120, cover_bounds.get_center().y)
	target.kind = 0
	target.speed = 100
	for i in 600:
		target._physics_process(1.0 / 60.0)
	check(target.position.distance_to(game.player.position) < 75, "enemy navigates around pillar to reach player")
	target.position = Vector2(cover_bounds.position.x - 120, cover_bounds.get_center().y)
	target.kind = 1
	target.route_clock = 0
	for i in 600:
		target._physics_process(1.0 / 60.0)
	var lane_clear := true
	var lane: Vector2 = target.position.direction_to(game.player.position)
	for step in range(1, int(target.position.distance_to(game.player.position) / 16) + 1):
		if game.blocked(target.position + lane * step * 16, target.radius + 4):
			lane_clear = false
	check(lane_clear, "ranged enemy repositions until cover no longer blocks its shot")
	# Inventory and economy behavior, independent of random drops.
	game.loot.reset_run()
	check(game.loot.add_item("medkit") and game.loot.add_item("shield") and not game.loot.add_item("bomb"), "inventory enforces exactly two slots")
	game.player.health = game.player.max_health
	check(not game.loot.use_slot(0) and game.loot.slots[0] == "medkit", "full health does not waste medkit")
	game.player.health = 1
	check(game.loot.use_slot(0) and game.player.health == 4 and game.loot.slots[0].is_empty(), "medkit heals three and consumes one slot")
	check(game.loot.use_slot(1) and game.player.immunity >= 5, "shield grants five seconds immunity")
	game.loot.add_item("overdrive")
	check(game.loot.use_slot(0) and game.player.overdrive_time == 9, "overdrive activates temporary firepower")
	game.player.overdrive_time = 0
	game.loot.add_item("bomb")
	game.spawn_enemy()
	var bomb_target = game.enemies.get_child(game.enemies.get_child_count() - 1)
	bomb_target.set_physics_process(false)
	check(game.loot.use_slot(0) and bomb_target.is_queued_for_deletion(), "bomb damages all enemies and consumes slot")
	await process_frame
	game.loot.reset_run()
	game.rng.seed = 45678
	for i in 2000:
		game.loot.enemy_died(Vector2(180, 386), false)
	var coin_drops := 0
	var item_drops := 0
	for drop in game.loot.drops:
		if drop.type == "coin":
			coin_drops += 1
		else:
			item_drops += 1
	check(coin_drops >= 1000 and coin_drops <= 1200 and item_drops >= 20 and item_drops <= 90, "seeded sample gives improved coin drops and rare consumables")
	game.loot.collect_remaining()
	check(game.loot.coins >= 1000 and game.loot.coins < 2200 and not game.loot.slots[0].is_empty() and not game.loot.slots[1].is_empty(), "phase cleanup banks base coin value and fills only available slots")
	check(game.loot.drops.size() == item_drops - 2, "full slots leave extra consumables on ground")
	game.open_shop()
	game.loot.coins = 0
	check(not game.buy_upgrade(0), "insufficient coins reject purchase")
	game.loot.coins = 100
	check(not game.buy_supply("bomb") and game.loot.coins == 100, "full inventory rejects paid item without charging")
	game.loot.slots[0] = ""
	game.loot.slots[1] = ""
	check(game.buy_supply("bomb") and game.loot.coins == 80, "store consumable fills slot and charges twenty")
	game.player.health = game.player.max_health
	check(not game.buy_supply("repair") and game.loot.coins == 80, "full health rejects repair without charging")
	game.close_panel()
	game.state = "playing"
	game.fx.particles.clear()
	game.fx.sparks(Vector2.ZERO, Color.WHITE, 5000)
	check(game.fx.particles.size() == game.fx.MAX_PARTICLES, "particles obey density budget")
	game.loot.reset_run()
	# Validate every actual wave, species, portal, upgrade panel and victory.
	var layouts: Array[String] = []
	for room_index in game.total_rooms():
		game.room = room_index
		game.start_room()
		check(game.planet_index == room_index / game.ARENAS_PER_PLANET, "planet mapping arena %d" % (room_index + 1))
		var layout = game.get_node("Arena")
		layouts.append(layout.scene_file_path)
		check(not game.blocked(game.player.position, 16) and not game.blocked(game.portal, 16), "spawn and extraction are clear %d" % (room_index + 1))
		check(not layout.route(game.player.position, game.portal).is_empty(), "extraction route is connected %d" % (room_index + 1))
		var gates_connected := true
		for gate in layout.spawn_gates():
			gates_connected = gates_connected and not game.blocked(gate, 16) and not layout.route(gate, game.player.position).is_empty()
		check(gates_connected, "enemy spawn routes are connected %d" % (room_index + 1))
		while game.pending > 0:
			game.spawn_enemy()
			game.pending -= 1
		for enemy in game.enemies.get_children():
			enemy.set_physics_process(false)
			enemy.hurt(10000)
		await process_frame
		game._physics_process(0.016)
		check(game.boss_spawned and is_instance_valid(game.boss_ref) and game.pending > 0, "every phase ends with boss and minions %d" % (room_index + 1))
		var boss = game.boss_ref
		boss.set_physics_process(false)
		boss.health = boss.max_health * 0.4
		boss.shot_cd = 0
		var before_shots: int = game.bullets.get_child_count()
		boss._physics_process(0.016)
		if boss.superboss:
			check(boss.super_phase == 2 and boss.super_attack_timer > 0, "superboss second phase starts with a breathing interval %d" % (room_index + 1))
			game.clear_container(game.bullets)
			boss.super_attack_timer = 0
			boss._physics_process(0.016)
			check(boss.super_telegraph > 0 and game.bullets.get_child_count() == 0, "superboss warns before firing %d" % (room_index + 1))
			boss._physics_process(0.91)
			check(game.bullets.get_child_count() >= 43 and game.bullets.get_child_count() <= 44, "superboss second-phase radial pattern %d" % (room_index + 1))
		else:
			check(game.bullets.get_child_count() - before_shots == 19 + game.planet_index * 2, "boss second-phase radial and aimed attack %d" % (room_index + 1))
		while game.pending > 0:
			game.spawn_enemy()
			game.pending -= 1
		for enemy in game.enemies.get_children():
			enemy.set_physics_process(false)
			enemy.hurt(10000)
		await process_frame
		game._physics_process(0.4)
		check(game.state == "cleared", "phase clear offers safe collection %d" % (room_index + 1))
		game.player.position = game.portal
		game.get_node("UI/HUD/Cleanup/Box/CleanupShopButton").pressed.emit()
		check(game.state == "shop" and game.loot.coins > 0, "opening shop salvages remaining coins %d" % (room_index + 1))
		var balance: int = game.loot.coins
		var price: int = game.shop_stock[0].cost
		# Transaction coverage is independent of whether this run can afford the stock.
		game.loot.coins = maxi(balance, price)
		balance = game.loot.coins
		check(game.buy_upgrade(0) and game.loot.coins == balance - price, "shop charges exact upgrade price %d" % (room_index + 1))
		check(not game.buy_upgrade(0), "shop cannot buy same stock twice %d" % (room_index + 1))
		game.panel.find_child("LeaveButton", true, false).pressed.emit()
		check(game.state == "travel", "onboard shop starts extraction %d" % (room_index + 1))
		check(game.state == "travel" and game.room == room_index, "boarding starts correct vehicle travel %d" % (room_index + 1))
		game._physics_process(game.TRAVEL_DURATION + 0.01)
		if room_index < game.total_rooms() - 1:
			check(game.room == room_index + 1 and game.state == "playing", "vehicle reaches next arena %d" % (room_index + 1))
		else:
			check(game.state == "ended" and game.score > 0, "final rover evacuation produces victory")
	var unique_layouts := {}
	for path in layouts:
		unique_layouts[path] = true
	check(unique_layouts.size() == 13, "all thirteen rooms use different scene files")
	game.start_run()
	game.time_left = 0.01
	game._physics_process(0.02)
	check(game.state == "ended", "timeout produces defeat")
	game.start_run()
	for death in 3:
		game.player.immunity = 0
		game.player.hurt(99)
		check(game.run_chances_left == 2 - death and game.state == ("ended" if death == 2 else "death"), "three run chances: death %d" % (death + 1))
		if game.state == "death":
			game.continue_after_death()
	game.start_run()
	check(game.room == 0 and game.player.max_health == 5 and game.chosen_upgrades.is_empty() and game.loot.coins == 0 and game.loot.slots == ["", ""], "new attempt resets upgrades and progress")
	print("SMOKE RESULT: %d failures" % failures)
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
