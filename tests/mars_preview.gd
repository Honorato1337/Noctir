extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func shot(path: String) -> void:
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/" + path + ".png")

func capture() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.start_run()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.player.position = Vector2(850, 650)
	game.player.aim = Vector2.RIGHT
	game.player.immunity = 0
	game.player.dash_cd = 0.9
	game.loot.coins = 24
	for i in 24:
		game.spawn_enemy()
		var mob = game.enemies.get_child(i)
		mob.set_physics_process(false)
		var at: Vector2 = game.player.position + Vector2.RIGHT.rotated(i * TAU / 24) * (150 + (i % 4) * 30)
		if not game.blocked(at, mob.radius):
			mob.position = at
	game.get_node("Camera2D").position = game.player.position
	game.get_node("Camera2D").reset_smoothing()
	game.message = ""
	await shot("preview-mars-dash")
	game.player.position = Vector2(1400, 850)
	game.get_node("Camera2D").position = game.player.position
	game.get_node("Camera2D").reset_smoothing()
	await shot("preview-camera-east")
	game.queue_free()
	await process_frame
	quit()
