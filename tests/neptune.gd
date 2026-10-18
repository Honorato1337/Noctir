extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, detail: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + detail)
	if not ok:
		failures += 1

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.start_run()
	game.player.set_physics_process(false)
	for room in range(4, 8):
		game.room = room
		game.start_room()
		check(game.planet().name == "NETUNO" and game.get_node("Arena").scene_file_path.contains("neptune_"), "arena %d belongs to Neptune" % (room + 1))
		check(game.environment_clock == 0 and game.hazards.size() > 0, "new arena starts with safe weather and authored frost zones")
	var hazard: Vector2 = game.hazards[0]
	game.environment_clock = 4.9
	check(not game.frost_active() and game.frost_slowdown(hazard) == 1.0 and game.neptune_wind() == Vector2.ZERO, "telegraph gives time to escape without slow or wind")
	game.environment_clock = 5.1
	check(game.frost_active() and is_equal_approx(game.frost_slowdown(hazard), 0.6) and game.neptune_wind().length() > 60, "active storm slows frost zones and applies a visible-direction gust")
	check(game.frost_slowdown(game.portal) == 1.0, "ground slowdown is confined to the marked zones")
	game.player.position = hazard
	game.player.immunity = 0
	var health: int = game.player.health
	game._physics_process(0.016)
	check(game.player.health == health - 1, "active frost damages an unprotected player inside the zone")
	game.state = "paused"
	var before: float = game.environment_clock
	game._physics_process(1)
	check(game.environment_clock == before, "pausing freezes the storm clock")
	game.state = "playing"
	game.environment_clock = 7.1
	check(not game.frost_active() and game.frost_slowdown(hazard) == 1.0, "frost slow and gust expire at the end of each cycle")
	game.clear_container(game.enemies)
	game.clear_container(game.bullets)
	game.spawn_enemy()
	var enemy = game.enemies.get_child(0)
	enemy.set_physics_process(false)
	enemy.shot_cd = 0
	enemy._physics_process(0.016)
	check(game.bullets.get_child_count() == 2, "Neptune sentinels shoot a two-shard fan")
	var shards := true
	for bullet in game.bullets.get_children():
		shards = shards and bullet.frost and bullet.hostile
	check(shards, "enemy shots use the cold shard visual")
	game.begin_boss()
	check(game.environment_clock == 3.5 and game.message.contains(game.boss_ref.superboss_name()), "guardian entry starts a telegraphed frost cycle")
	game.room = 0
	game.start_room()
	game.environment_clock = 5.5
	check(game.frost_slowdown(hazard) == 1.0 and game.neptune_wind() == Vector2.ZERO and game.hazards.is_empty(), "Mars is unaffected by Neptune weather")
	# Drain the asynchronous playback stopped when the run began.
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	print("NEPTUNE RESULT: %d failures" % failures)
	quit(1 if failures else 0)
