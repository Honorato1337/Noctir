extends SceneTree
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	root.size = Vector2i(1920,1080)
	game.preferences.touch_mode = 2
	game.set_physics_process(false)
	game.start_run(false,7,"hard")
	game.player.set_physics_process(false)
	game.player.position = Vector2(800,560)
	game.player.aim = Vector2.RIGHT
	game.player.immunity = 999
	game.progression.abilities.berserk = 1
	game.loot.slots.assign(["bomb","shield"])
	game.configure_camera()
	game.begin_boss()
	var boss = game.boss_ref
	boss.set_physics_process(false)
	boss.position = Vector2(1140,520)
	boss.health = boss.max_health*.5
	boss.update_visual()
	for i in 26:
		game.spawn_enemy()
		var mob = game.enemies.get_child(-1)
		mob.set_physics_process(false)
		var at: Vector2 = game.player.position+Vector2.from_angle(PI/2+i*PI/26)*360
		if not game.blocked(at,mob.radius): mob.position = at
	for frame in 80:
		boss.tick_superboss(1.0/60)
		await physics_frame
	game.message_time = 0
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/media/11-leviata-boreal.png")
	print("Captured new Neptune superboss using original animation.")
	game.state = "paused"
	boss.update_visual()
	print("Animation paused: "+str(not boss.neptune_super_visual.is_playing()))
	game.queue_free()
	await process_frame
	quit()
