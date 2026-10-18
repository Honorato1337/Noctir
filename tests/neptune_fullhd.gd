extends SceneTree
var failures := 0
func _initialize() -> void:call_deferred("run")
func check(ok: bool, detail: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+detail)
	if not ok:failures += 1
func settle() -> void:
	for i in 5:await process_frame
func capture(name: String) -> void:
	if "--preview" not in OS.get_cmdline_user_args():return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/preview-"+name+".png")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	root.size = Vector2i(1920,1080)
	await settle()
	var logical: Vector2 = root.get_visible_rect().size
	var physical: Vector2 = Vector2(root.size)
	print("FULLHD viewport physical=%s logical=%s" % [physical,logical])
	check(root.size == Vector2i(1920,1080) and logical.is_equal_approx(Vector2(1280,720)),"1920x1080 fills the window with expanded 16:9 canvas")
	check(is_equal_approx(physical.x/logical.x,physical.y/logical.y),"horizontal and vertical scales match without stretching art")
	var menu: Control = game.panel
	check(menu.get_global_rect().position.is_zero_approx() and menu.get_global_rect().size.is_equal_approx(logical),"menu and backdrop reach every viewport edge")
	await capture("fullhd-menu")
	game.start_run()
	game.room = 4
	game.start_room()
	game.player.set_physics_process(false)
	game.player.position = Vector2(650,430)
	game.configure_camera()
	game.spawn_enemy(true)
	var boss = game.boss_ref
	boss.set_physics_process(false)
	boss.position = Vector2(830,430)
	boss.update_visual()
	check(boss.neptune_boss_visual.visible and not boss.neptune_visual.visible and not boss.mars_boss_visual.visible,"regular Neptune boss uses its dedicated supplied art")
	var frames: SpriteFrames = boss.neptune_boss_visual.sprite_frames
	check(frames.get_frame_count(&"walk") == 3 and frames.get_frame_texture(&"walk",0).resource_path == "res://assets/mobs_netuno/mob_neturno2/pixil-frame-0.png","boss animation uses all three original frames")
	check(boss.neptune_boss_visual.flip_h and boss.neptune_boss_visual.is_playing(),"boss faces the player and animates during combat")
	await settle()
	var hud: Control = game.get_node("UI/HUD")
	hud.update_game(game)
	var header: Control = hud.get_node("TopBar")
	check(is_equal_approx(header.get_global_rect().get_center().x,logical.x/2),"HUD remains centered in Full HD")
	var flash: Control = hud.get_node("ScreenFlash")
	check(flash.get_global_rect().position.is_zero_approx() and flash.size.is_equal_approx(logical),"damage and extraction overlay covers the entire screen")
	await capture("fullhd-neptune-boss")
	game.state = "paused"
	boss.update_visual()
	check(not boss.neptune_boss_visual.is_playing(),"pause freezes the new boss animation")
	game.state = "playing"
	game.player.position.x = boss.position.x+100
	boss.update_visual()
	check(not boss.neptune_boss_visual.flip_h,"boss animation mirrors correctly when player changes sides")
	var hp: float = boss.health
	var shield: float = boss.shield
	boss.hurt(shield+1)
	check(shield > 0 and boss.shield == 0 and is_equal_approx(boss.health,hp-1),"Neptune shield still absorbs damage before health")
	game.show_menu()
	for target: Vector2i in [Vector2i(1152,720),Vector2i(1280,720)]:
		root.size = target
		await settle()
		logical = root.get_visible_rect().size
		check(absf(float(target.x)/target.y-logical.x/logical.y)<0.005,"canvas also fills %dx%d" % [target.x,target.y])
		game.get_node("UI/HUD").update_game(game)
		check(is_equal_approx(header.get_global_rect().get_center().x,logical.x/2),"HUD recenters after resolution change")
	game.queue_free()
	await process_frame
	print("NEPTUNE FULLHD RESULT: %d failures" % failures)
	quit(1 if failures else 0)
