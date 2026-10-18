extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, detail: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + detail)
	if not ok: failures += 1

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.start_run()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.weather.set_physics_process(false)
	game.encounters.set_physics_process(false)
	game.clear_container(game.enemies)
	for i in 60:
		game.spawn_enemy(i == 59)
	var all: Array[Node] = game.enemies.get_children()
	for i in all.size():
		all[i].set_physics_process(false)
		all[i].position = game.arena.position + Vector2(100 + (i % 10) * 125, 70 + (i / 10) * 90)
	game.target_grid_frame = -1
	var full_checks := 0
	var grid_checks := 0
	var missed := 0
	for i in 1000:
		var point: Vector2 = game.arena.position + Vector2((i * 73) % int(game.arena.size.x), (i * 47) % int(game.arena.size.y))
		var nearby: Array = game.projectile_targets(point)
		full_checks += all.size()
		grid_checks += nearby.size()
		for enemy in all:
			var reach: float = enemy.radius + (13 if enemy.shield > 0 else 0) + 8
			if point.distance_squared_to(enemy.position) < reach * reach and enemy not in nearby:
				missed += 1
	check(missed == 0, "spatial collision grid preserves every hit, including boss shields")
	check(grid_checks < full_checks / 3, "spatial grid reduces collision candidates: %d vs %d" % [grid_checks, full_checks])
	game.fx.particles.clear()
	game.fx.emission_frame = -1
	for i in 100: game.fx.sparks(game.player.position, Color.WHITE, 5000)
	check(game.fx.particles.size() <= 96, "simultaneous explosions obey the per-frame emission budget")
	game.fx.set_process(false)
	game.fx._process(0.8)
	check(game.fx.particles.is_empty(), "expired particles are released together without array shifts")
	for i in 60: game.fx._process(1.0 / 20.0)
	check(game.fx.quality < 1.0, "sustained slow frames reduce decorative density automatically")
	game.fx.particles.clear()
	game.fx.emission_frame = -1
	game.fx.sparks(Vector2(-100000, -100000), Color.WHITE, 5000)
	check(game.fx.particles.is_empty(), "offscreen sparks do not allocate particles")
	game.queue_free()
	await process_frame
	quit(failures)
