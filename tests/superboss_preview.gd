extends SceneTree
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.start_run()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.room = 3
	game.start_room()
	game.player.position = Vector2(970, 650)
	game.player.immunity = 100
	game.player.dash_cd = 0.8
	game.begin_boss()
	var boss = game.boss_ref
	boss.set_physics_process(false)
	boss.position = Vector2(1250, 500)
	boss.health = boss.max_health * 0.2
	boss.tick_superboss(0.01)
	game.message_time = 0
	for i in 36:
		game.spawn_enemy()
		var mob = game.enemies.get_child(game.enemies.get_child_count() - 1)
		mob.set_physics_process(false)
		var at: Vector2 = game.player.position + Vector2.RIGHT.rotated(i * TAU / 36) * (150 + (i % 5) * 35)
		if not game.blocked(at, mob.radius):
			mob.position = at
	boss.super_attack_timer = 0
	boss.tick_superboss(0.01)
	boss.tick_superboss(0.91)
	for frame in 100:
		boss.tick_superboss(1.0 / 60)
		for bullet in game.bullets.get_children():
			if not bullet.is_queued_for_deletion():
				bullet._physics_process(1.0 / 60)
		game.fx._process(1.0 / 60)
	game.player.aim = game.player.position.direction_to(boss.position)
	game.get_node("Camera2D").position = game.player.position
	game.get_node("Camera2D").reset_smoothing()
	game.queue_redraw()
	boss.queue_redraw()
	for i in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/preview-superboss.png")
	game.queue_free()
	await process_frame
	quit()
