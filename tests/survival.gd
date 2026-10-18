extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, detail: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+detail)
	if not ok: failures += 1
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.show_difficulty_menu()
	game.select_game_mode(1)
	if "--preview" in OS.get_cmdline_user_args():
		for frame in 3: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/preview-survival-menu.png")
	game.panel.find_child("HardButton",true,false).pressed.emit()
	game.player.set_physics_process(false)
	check(game.panel == null, "mode selection closes when combat begins")
	check(game.run_mode == "endless" and game.run_difficulty == "hard", "menu starts infinite hard mode")
	check(game.arena.size == Vector2(2048,1344), "arena has exactly twice the campaign floor area")
	check(game.survival.boss_left == 45, "hard boss arrives after 45 active seconds")
	game._physics_process(1)
	check(game.enemies.get_child_count() > 0 and game.pending == 0, "continuous spawns without finite wave backlog")
	for enemy in game.enemies.get_children():
		check(enemy.position.distance_to(game.player.position) >= 300 and not game.blocked(enemy.position,enemy.radius), "spawn stays away from player and rocks")
	game.elapsed = 600
	game.survival.shop_at = 10000
	game.survival.boss_left = 0
	game.survival.tick(0.1)
	check(game.survival.tier == 14 and game.survival.health_factor() > 6, "difficulty keeps scaling beyond campaign length")
	check(is_instance_valid(game.boss_ref), "boss spawns while hordes remain")
	for i in 100: game.survival.tick(1)
	check(game.enemies.get_child_count() <= game.MAX_ACTIVE_ENEMIES, "bounded simultaneous actors during endless pressure")
	game.clear_container(game.enemies)
	game.boss_ref = null
	game._physics_process(0.1)
	check(game.state == "playing", "empty arena never triggers campaign victory or extraction")
	game.survival.shop_at = game.elapsed
	game.survival.tick(0.1)
	check(game.state == "shop" and game.shop_left == 20, "periodic timed shop remains available")
	game.run_chances_left = 2
	game.leave_shop()
	check(game.state == "playing" and game.run_chances_left == 2, "shop resumes same arena and keeps run chances")
	game.restart_current_run()
	check(game.run_mode == "endless" and game.survival.tier == 0 and game.run_chances_left == 3, "restart preserves mode and resets escalation")
	var samples: Array[float] = []
	for mode: String in ["easy","medium","hard"]:
		game.start_run(false,0,mode,"endless")
		game.player.set_physics_process(false)
		game._physics_process(0.2)
		samples.append(game.enemies.get_child(0).health)
		check(game.survival.boss_left > 0 and game.run_mode == "endless", "survival starts on "+mode)
	check(samples[0] < samples[1] and samples[1] < samples[2], "enemy health is ordered by difficulty")
	game.paused_from = "playing"
	game.state = "paused"
	var frozen: float = game.elapsed
	game._physics_process(10)
	check(game.elapsed == frozen, "paused combat does not advance endless pressure")
	game.start_run()
	check(game.run_mode == "campaign" and game.pending > 0 and game.arena.size == Vector2(1536,896), "campaign geometry and finite waves are preserved")
	game.queue_free()
	await process_frame
	quit(failures)
