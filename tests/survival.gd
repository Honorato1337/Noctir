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
	game.show_difficulty_menu()
	game.select_game_mode(1)
	if "--preview" in OS.get_cmdline_user_args():
		for frame in 3: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/preview-survival-menu.png")
	game.panel.find_child("HardButton",true,false).pressed.emit()
	game.player.set_physics_process(false)
	check(game.run_mode == "endless" and game.survival.wave == 1 and game.pending == 34, "hard mode starts finite first wave")
	check(game.arena.size == Vector2(2048,1344), "double area retained")
	game._physics_process(1)
	check(game.enemies.get_child_count() > 0 and game.pending < 34, "wave budget decreases as enemies spawn")
	game.pending = 0
	game._physics_process(1)
	check(game.state == "playing", "shop waits until all enemies die")
	game.clear_container(game.enemies)
	game.loot.drops.append({"pos":Vector2(500,500),"type":"coin","value":10,"age":0.0})
	game._physics_process(0.1)
	check(game.state == "shop" and game.shop_left == 10 and game.loot.coins == 10, "wave completion banks loot and opens ten-second shop")
	game.run_chances_left = 2
	game._physics_process(9)
	check(game.state == "shop" and game.survival.wave == 1, "next wave cannot start before shop timer")
	game._physics_process(1)
	check(game.state == "playing" and game.survival.wave == 2 and game.pending > 34 and game.run_chances_left == 2, "timeout starts larger wave and preserves run lives")
	game.pending = 0
	game.clear_container(game.enemies)
	game._physics_process(0.1)
	game.leave_shop()
	check(game.survival.wave == 3 and game.survival.boss_due, "third wave schedules boss")
	game.pending = 0
	game._physics_process(0.1)
	check(is_instance_valid(game.boss_ref) and not game.survival.boss_due and game.state == "playing", "boss blocks wave completion")
	game.survival.wave = 100
	game.survival.start_wave()
	check(game.survival.wave == 101 and game.pending > 20000 and game.survival.health_factor() > 100, "wave size and health scale indefinitely")
	for i in 100: game.survival.tick(1)
	check(game.enemies.get_child_count() <= game.MAX_ACTIVE_ENEMIES, "large wave streams within actor budget")
	game.deployables.inventory = "beacon"
	check(game.deployables.place(), "beacon can be deployed")
	var at: Vector2 = game.player.position
	check(is_equal_approx(game.deployables.enemy_slowdown(at+Vector2(300,0),false),0.2), "beacon slows normal enemies by eighty percent over larger radius")
	check(is_equal_approx(game.deployables.enemy_slowdown(at,true),0.5), "beacon slows bosses by fifty percent")
	check(game.deployables.enemy_slowdown(at+Vector2(321,0),false) == 1, "slowdown respects visible radius")
	game.shoot(at+Vector2(280,0),Vector2.RIGHT,1,true)
	game.deployables._physics_process(0.2)
	check(game.bullets.get_child(game.bullets.get_child_count()-1).is_queued_for_deletion(), "beacon destroys hostile projectiles across its expanded field")
	check(game.deployables.placed[0].life > 19, "beacon lasts twenty seconds")
	game.restart_current_run()
	check(game.survival.wave == 1 and game.run_chances_left == 3, "restart resets waves and chances")
	game.start_run()
	check(game.run_mode == "campaign" and game.arena.size == Vector2(1536,896), "campaign unchanged")
	game.queue_free()
	await process_frame
	quit(failures)
