extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.smoke_mode = true
	game.start_run()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	var sheet := Image.create(1728, 360, false, Image.FORMAT_RGBA8)
	var room_indices := [0, 5, 10]
	var names := ["mars", "venus", "jupiter"]
	for index in 3:
		game.room = room_indices[index]
		game.start_room()
		game.begin_boss()
		game.boss_ref.set_physics_process(false)
		game.pending = 0
		game.player.position = Vector2(552, 448)
		game.player.aim = Vector2.RIGHT
		game.player.immunity = 0
		game.player.update_visual()
		game.player.queue_redraw()
		for x in [224, 400, 576, 752, 928]:
			game.spawn_enemy()
			var enemy = game.enemies.get_child(game.enemies.get_child_count() - 1)
			enemy.set_physics_process(false)
			enemy.position = Vector2(x, 184)
			enemy.update_visual()
		game.fx.particles.clear()
		game.fx.shake = 0
		game.message = game.get_node("Arena").layout_name
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var shot := root.get_texture().get_image()
		shot.save_png("res://docs/preview-%s-art.png" % names[index])
		shot.resize(576, 360, Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(shot, Rect2i(0, 0, 576, 360), Vector2i(index * 576, 0))
	sheet.save_png("res://docs/preview-biomes.png")
	game.queue_free()
	await process_frame
	quit()
