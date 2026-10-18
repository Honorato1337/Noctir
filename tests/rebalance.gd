extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, detail: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+detail)
	if not ok: failures += 1
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run()
	game.player.set_physics_process(false)
	game.spawn_enemy()
	check(game.enemies.get_child(-1).health >= 2.8, "starting mobs withstand at least three base shots")
	game.room = 11
	game.start_room()
	game.spawn_enemy()
	check(game.enemies.get_child(-1).health > 7, "late campaign resistance rises beyond opening enemies")
	game.spawn_enemy(true)
	var boss = game.boss_ref
	boss.set_physics_process(false)
	boss.age = 2.2
	var warning_velocity: Vector2 = boss.boss_motion(Vector2.RIGHT,Vector2.RIGHT,300,false)
	check(boss.boss_warning and warning_velocity == Vector2.ZERO, "faster boss still warns before dash")
	boss.age = 2.9
	check(boss.boss_motion(Vector2.RIGHT,Vector2.RIGHT,300,false).length() >= 760, "Jupiter boss dash accelerates to 760 px per second")
	var weather = game.weather
	weather.set_physics_process(false)
	weather.start_event()
	check(weather.vortices[0].radius >= 350 and weather.vortices[0].velocity.length() >= 105, "Jupiter storm is larger and moves faster")
	weather.strikes.clear()
	weather.add_strike("meteor",game.player.position)
	check(weather.strikes[0].radius == 104 and weather.strikes[0].warning >= 1.35, "meteor has wider impact with preserved dodge warning")
	var hp: int = game.player.health
	game.player.immunity = 0
	weather.age = weather.warning
	weather.pulse = 99
	weather.vortices.clear()
	weather._physics_process(.5)
	check(game.player.health == hp, "enlarged meteor cannot hurt during warning")
	game.player.position = weather.strikes[0].pos+Vector2(120,0)
	weather._physics_process(.86)
	check(game.player.health == hp, "player can leave enlarged meteor impact before explosion")
	game.start_run(false,0,"medium","endless")
	game.player.set_physics_process(false)
	var relative_health: Array[float] = []
	for tier in [0,5,10,20]:
		game.survival.wave = tier
		game.survival.start_wave()
		game.clear_container(game.enemies)
		game.player.damage = pow(1.35,tier)
		game.spawn_enemy()
		relative_health.append(game.enemies.get_child(-1).health/game.player.damage)
	check(relative_health[2] > relative_health[0] and relative_health[3] > relative_health[2], "wave resistance keeps growing against a damage-upgrade-every-wave build")
	check(relative_health[3] > 6, "late survival mobs no longer collapse to one upgraded shot")
	check(game.enemy_ability_rate() > 1.5, "late enemy ability cooldowns accelerate")
	for i in 150: weather.add_strike("meteor",game.player.position)
	check(weather.strikes.size() <= weather.MAX_STRIKES, "stronger events retain bounded active impacts")
	game.queue_free()
	await process_frame
	quit(failures)
