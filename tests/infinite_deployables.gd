extends SceneTree

const Progression = preload("res://scripts/progression.gd")
var failures := 0
const PATH := "res://tmp/infinite-progression-test.cfg"

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok:
		failures += 1

func shot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	for frame in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/preview-" + name + ".png")

func click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)
	Input.flush_buffered_events()
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await process_frame

func run() -> void:
	var profile := Progression.new()
	profile.save_path = PATH
	for cycle in 6:
		for upgrade: Dictionary in Progression.UPGRADES:
			profile.levels[upgrade.key] = profile.max_level(upgrade.key)
		profile.coins = 1000
		check(profile.reset_for_prestige() and profile.max_level("health") == 4 + cycle and profile.prestige_cycles == cycle + 1, "prestige cycle %d increases the next maximum" % cycle)
	var reopened := Progression.new()
	reopened.save_path = PATH
	reopened.load_profile()
	check(reopened.max_level("damage") == 11 and reopened.prestige_cycles == 6, "expanded limits persist with the cycle count")
	profile.prestige_cycles = 10000
	profile.levels.dash = 10003
	profile.levels.health = 10003
	profile.levels.damage = 10004
	check(profile.max_level("health") == 10003 and profile.price(1) > 0 and profile.dash_factor(10003) > 0, "high cycles have no configured ceiling, valid extended prices and positive dash cooldown")
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.encounters.set_physics_process(false)
	game.deployables.set_physics_process(false)
	game.contracts.set_physics_process(false)
	await process_frame
	await click(game.panel.find_child("TestButton"))
	check(game.panel.find_child("TestArena13") != null and game.panel.find_child("TestBoss13") != null, "Test tab lists all thirteen arenas and their bosses")
	await shot("arena-test-menu")
	game.panel.find_child("TestEquipment").select(1)
	await click(game.panel.find_child("TestArena13"))
	game.player.set_physics_process(false)
	check(game.practice_mode and game.room == 12 and game.deployables.inventory == "turret" and not game.contracts.enabled, "practice starts the selected arena and device with rewards disabled")
	var kinds: Array[int] = []
	for i in 3:
		game.spawn_enemy()
		var mob = game.enemies.get_child(-1)
		mob.set_physics_process(false)
		kinds.append(mob.kind)
	check(kinds == [0, 1, 2], "arena thirteen deterministically mixes all three planets")
	game.clear_container(game.enemies)
	game.begin_boss()
	var god = game.boss_ref
	god.set_physics_process(false)
	check(god.god and god.superboss and god.max_shield > 0, "arena thirteen ends with a shielded Alien God")
	for pattern in 3:
		game.encounters.reset()
		game.encounters.super_attack(god, pattern)
		var types: Array[String] = []
		for field in game.encounters.fields:
			types.append(field.kind)
		check(types.has(["blast", "gravity", "storm"][pattern]), "Alien God power %d creates its distinctive terrain attack" % pattern)
	var shield_before: float = god.shield
	game.shoot(god.position - Vector2(god.radius + 41, 0), Vector2.RIGHT, 3, false)
	var shield_hit = game.bullets.get_child(-1)
	shield_hit._physics_process(0)
	check(shield_hit.is_queued_for_deletion() and god.shield == shield_before - 3, "projectiles collide with the visible shield before reaching the body")
	var hp: float = god.health
	var shield: float = god.shield
	god.hurt(10)
	check(god.health == hp and god.shield == shield - 10, "shield absorbs a hit before health")
	god.hurt(god.shield + 5)
	check(god.shield == 0 and god.health == hp - 5, "breaking a shield carries excess damage to health")
	god.health = god.max_health * .4
	god.tick_superboss(.01)
	check(god.shield > 0 and god.super_phase == 2, "Alien God restores a limited shield only when entering a new phase")
	var coins: int = game.progression.coins
	var space: int = game.progression.space_coins
	var best: int = game.best
	var played: float = game.preferences.played_seconds
	game.score = 100000
	game._process(3)
	game.finish(true, "Teste")
	check(game.progression.coins == coins and game.progression.space_coins == space and game.best == best and game.preferences.played_seconds == played, "practice cannot farm permanent coins, SpaceCoin, records or play time")
	game.restart_current_run()
	game.player.set_physics_process(false)
	check(game.practice_mode and game.room == 12 and game.deployables.inventory == "turret", "restarting practice retains its arena and chosen device")
	game.start_run()
	game.player.set_physics_process(false)
	game.room = 2
	game.start_room()
	game.player.position = Vector2(832, 552)
	game.clear_container(game.enemies)
	var devices = game.deployables
	check(devices.inventory == "mine" and game.loot.slots == ["", ""], "third equipment slot is independent of the two consumables")
	check(not game.loot.add_item("turret") and game.loot.slots == ["", ""], "ground equipment never overflows into consumable slots")
	check(devices.place() and devices.inventory.is_empty(), "placing a mine consumes only slot three")
	game.spawn_enemy()
	var target = game.enemies.get_child(-1)
	target.set_physics_process(false)
	target.position = game.player.position + Vector2(80, 0)
	target.health = 100
	target.max_health = 100
	game.spawn_enemy()
	var outer = game.enemies.get_child(-1)
	outer.set_physics_process(false)
	outer.position = game.player.position + Vector2(220, 0)
	outer.health = 100
	outer.max_health = 100
	devices._physics_process(.3)
	check(target.health == 100, "mine cannot explode before arming")
	devices._physics_process(.36)
	check(target.health < 100 and outer.health < 100 and devices.placed.is_empty(), "mine has a real 240-pixel area attack and detonates once")
	game.clear_container(game.bullets)
	devices.inventory = "turret"
	devices.place()
	devices._physics_process(.2)
	check(game.bullets.get_child_count() == 1 and not game.bullets.get_child(0).hostile, "turret acquires a target and fires allied projectiles")
	devices.clear_room()
	devices.inventory = "beacon"
	devices.place()
	game.shoot(game.player.position + Vector2(30, 0), Vector2.DOWN, 1, true)
	var hostile = game.bullets.get_child(-1)
	devices._physics_process(.2)
	check(hostile.is_queued_for_deletion() and devices.enemy_slowdown(game.player.position, false) < devices.enemy_slowdown(game.player.position, true), "beacon clears nearby hostile bullets and slows bosses less than mobs")
	var age: float = devices.placed[0].age
	game.state = "paused"
	devices._physics_process(20)
	check(devices.placed[0].age == age, "pause freezes deployed equipment lifetime")
	game.state = "playing"
	devices._physics_process(13)
	check(devices.placed.is_empty(), "deployed equipment expires and cannot accumulate forever")
	game.loot.coins = 100
	game.open_shop()
	var supply_cost: int = game.Economy.supply_price("turret", game.room)
	check(game.buy_supply("turret") and devices.inventory == "turret" and game.loot.coins == 100 - supply_cost and game.loot.slots == ["", ""], "orbital shop purchases ground equipment only into slot three")
	var after_purchase: int = game.loot.coins
	check(not game.buy_supply("mine") and game.loot.coins == after_purchase and not devices.place(), "occupied equipment slot and shop state reject invalid purchases or deployment")
	game.close_panel()
	game.state = "playing"
	devices.clear_room()
	for i in devices.MAX_ACTIVE:
		devices.inventory = "mine"
		devices.place()
	devices.inventory = "turret"
	check(not devices.place() and devices.inventory == "turret" and devices.placed.size() == devices.MAX_ACTIVE, "active device limit does not consume a rejected placement")
	game.clear_container(game.enemies)
	game.room = 3
	game.start_room()
	game.begin_boss()
	var mars = game.boss_ref
	mars.set_physics_process(false)
	check(mars.mars_super_visual.visible and mars.mars_super_visual.sprite_frames.get_frame_count("walk") == 4, "Mars superboss uses the supplied mob_marte3 animation")
	mars.age = 3.1
	var aim: Vector2 = mars.position.direction_to(game.player.position + Vector2(0, 28))
	game.player.velocity = Vector2(0, 100)
	mars.boss_motion(Vector2.LEFT, Vector2.LEFT, 300, false)
	check(mars.boss_warning and mars.boss_locked_dir.dot(aim) > .999, "Mars boss locks a predictive dash aim during its warning")
	mars.age = 4.0
	check(mars.boss_motion(Vector2.LEFT, Vector2.LEFT, 300, false).length() > 500, "boss executes its fast dash after telegraphing")
	var neptune_shield := 0.0
	for room in [7, 11]:
		game.room = room
		game.start_room()
		game.begin_boss()
		game.boss_ref.set_physics_process(false)
		if room == 7:
			neptune_shield = game.boss_ref.shield / game.boss_ref.health
		else:
			check(game.boss_ref.shield / game.boss_ref.health > neptune_shield, "Jupiter has proportionally more shield than Neptune")
	game.progression.prestige_cycles = 8
	game.room = 0
	game.start_room()
	game.spawn_enemy()
	var scaled = game.enemies.get_child(-1)
	scaled.set_physics_process(false)
	check(scaled.health > 2 and game.enemy_damage() == 3, "prestige increases enemy health and damage")
	game.progression.prestige_cycles = 0
	game.player.position = Vector2(832, 552)
	game.player.dash_cd = 0
	Input.action_press("dash")
	game.player._physics_process(.01)
	Input.action_release("dash")
	check(game.player.dash_duration * game.player.dash_speed > 200 and game.player.dash_time > .2, "player dash now covers over 200 pixels")
	var hearts = game.get_node("UI/HUD/Health")
	hearts.set_health(10000, 10005)
	check(hearts.heart_rects().size() == 1, "unbounded health uses a compact heart and exact numeric counter")
	game.set_process(false)
	game.get_node("PlanetMusic").stop()
	game.get_node("MenuMusic").stop()
	await create_timer(.2).timeout
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	print("INFINITE DEPLOYABLES RESULT: %d failures" % failures)
	quit(1 if failures else 0)
