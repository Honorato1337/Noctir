extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func shot(name: String) -> void:
	for frame in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/preview-" + name + ".png")

func capture() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.show_test_menu()
	await shot("arena-test-menu")
	game.panel.find_child("TestBoss13").pressed.emit()
	game.player.set_physics_process(false)
	game.encounters.set_physics_process(false)
	game.deployables.set_physics_process(false)
	game.fx.set_process(false)
	game.player.position = Vector2(950, 650)
	var boss = game.boss_ref
	boss.position = Vector2(1320, 500)
	boss.set_physics_process(false)
	boss.health = boss.max_health * .2
	boss.shield = 0
	boss.tick_superboss(.01)
	for i in 34:
		game.spawn_enemy()
		var mob = game.enemies.get_child(-1)
		mob.set_physics_process(false)
		mob.health = 80
		mob.max_health = 80
		var at: Vector2 = game.player.position + Vector2.RIGHT.rotated(i * TAU / 34) * (160 + i % 4 * 45)
		if not game.blocked(at, mob.radius):
			mob.position = at
	game.deployables.inventory = "turret"
	game.deployables.place()
	game.player.position += Vector2(-110, 0)
	game.deployables.inventory = "beacon"
	game.deployables.place()
	game.deployables.inventory = "mine"
	for frame in 485:
		boss._physics_process(1.0 / 60)
		game.encounters._physics_process(1.0 / 60)
		game.deployables._physics_process(1.0 / 60)
		for bullet in game.bullets.get_children():
			bullet.set_physics_process(false)
			if not bullet.is_queued_for_deletion():
				bullet._physics_process(1.0 / 60)
		game.fx._process(1.0 / 60)
		if frame % 12 == 0:
			await process_frame
	game.player.aim = game.player.position.direction_to(boss.position)
	game.message_time = 0
	game.queue_redraw()
	boss.queue_redraw()
	game.get_node("Camera2D").position = game.player.position
	game.get_node("Camera2D").reset_smoothing()
	await shot("alien-god")
	game.start_run()
	game.player.set_physics_process(false)
	game.room = 3
	game.start_room()
	game.player.position = Vector2(970, 650)
	game.begin_boss()
	game.boss_ref.position = Vector2(1250, 500)
	game.boss_ref.set_physics_process(false)
	game.get_node("Camera2D").position = game.player.position
	game.get_node("Camera2D").reset_smoothing()
	await shot("mars-superboss-sprite")
	game.set_process(false)
	game.get_node("PlanetMusic").stop()
	await create_timer(.2).timeout
	game.queue_free()
	await process_frame
	quit()
