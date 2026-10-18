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
	game.start_run()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	check(game.arena.size == Vector2(1536, 896), "arena is larger than the 1152x720 viewport")
	var camera: Camera2D = game.get_node("Camera2D")
	var hud = game.get_node("UI/HUD")
	var hud_position: Vector2 = hud.get_node("Health").get_global_transform_with_canvas().origin
	game.player.position = Vector2(250, 300)
	for i in 8:
		await process_frame
	camera.reset_smoothing()
	camera.force_update_scroll()
	var before := camera.get_screen_center_position()
	game.player.position = Vector2(1350, 850)
	for i in 8:
		await process_frame
	camera.reset_smoothing()
	camera.force_update_scroll()
	var after := camera.get_screen_center_position()
	check(after.x > before.x + 200 and after.y > before.y + 150, "camera scrolls in both axes as the player crosses the map")
	var view := Rect2(after - Vector2(576, 360), Vector2(1152, 720))
	var limits := Rect2(Vector2(camera.limit_left, camera.limit_top), Vector2(camera.limit_right - camera.limit_left, camera.limit_bottom - camera.limit_top))
	check(limits.encloses(view), "camera remains within the arena presentation bounds")
	check(hud.get_node("Health").get_global_transform_with_canvas().origin == hud_position, "HUD remains fixed while the world camera moves")
	game.player.dash_cd = 0.8
	game.player.dash_recharge = 1.6
	hud.update_game(game)
	check(hud.get_node("DashCard/DashStatus").text.contains("0.8s") and is_equal_approx(hud.get_node("DashCard/DashCooldown").value, 0.5), "dash shows seconds remaining and proportional recharge")
	game.player.dash_cd = 0
	hud.update_game(game)
	check(hud.get_node("DashCard/DashStatus").text.contains("PRONTO") and hud.get_node("DashCard/DashCooldown").value == 1, "dash visibly returns to ready")
	game.spawn_enemy()
	var mob = game.enemies.get_child(0)
	mob.set_physics_process(false)
	check(mob.mars_visual.visible and mob.mars_visual.sprite_frames.get_frame_count(&"walk") == 3 and mob.mars_visual.scale == Vector2(2, 2), "small Mars enemy uses the three original frames at pixel scale")
	game.spawn_enemy(true)
	var boss = game.boss_ref
	boss.set_physics_process(false)
	check(not boss.mars_visual.visible and boss.mars_boss_visual.visible, "Mars boss uses its own supplied sprite")
	game.state = "paused"
	mob.update_visual()
	check(not mob.mars_visual.is_playing(), "pause freezes the new enemy animation")
	game.room = 4
	game.start_room()
	game.spawn_enemy()
	var neptune = game.enemies.get_child(0)
	check(not neptune.mars_visual.visible, "Mars sprite is not applied to other planets")
	game.queue_free()
	await process_frame
	print("CAMERA DASH MARS RESULT: %d failures" % failures)
	quit(1 if failures else 0)
