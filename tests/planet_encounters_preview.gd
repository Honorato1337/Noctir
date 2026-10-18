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
	game.start_run()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.encounters.set_physics_process(false)
	game.contracts.enabled = true
	game.contracts.set_physics_process(false)
	for sector in 3:
		game.room = sector * 4 + 3
		game.start_room()
		game.player.position = Vector2(970, 650)
		for offset: Vector2 in [Vector2.ZERO, Vector2(-110, 0), Vector2(0, 120), Vector2(110, 0)]:
			if not game.blocked(Vector2(970, 650) + offset, 18):
				game.player.position = Vector2(970, 650) + offset
				break
		game.player.immunity = 1000
		game.begin_boss()
		var boss = game.boss_ref
		boss.position = Vector2(1250, 500)
		boss.set_physics_process(false)
		boss.health = boss.max_health * .2
		boss.tick_superboss(.01)
		boss.super_aim = boss.position.direction_to(game.player.position)
		boss.super_gap_angle = boss.super_aim.angle() + .7
		boss.fire_super_attack()
		for frame in 70:
			boss.tick_superboss(1.0 / 60)
			for bullet in game.bullets.get_children():
				if not bullet.is_queued_for_deletion():
					bullet.set_physics_process(false)
					bullet._physics_process(1.0 / 60)
			game.fx._process(1.0 / 60)
		# Freeze a mixture of final warnings and active terrain mechanics.
		for index in game.encounters.fields.size():
			var field: Dictionary = game.encounters.fields[index]
			field.age = field.warning + .1 if index % 3 == 0 else field.warning * .75
		game.encounters.clock = .8
		game.encounters.queue_redraw()
		for i in 36:
			game.spawn_enemy()
			var mob = game.enemies.get_child(-1)
			mob.set_physics_process(false)
			var at: Vector2 = game.player.position + Vector2.RIGHT.rotated(i * TAU / 36) * (155 + i % 5 * 40)
			if not game.blocked(at, mob.radius):
				mob.position = at
		game.message_time = 0
		game.player.aim = game.player.position.direction_to(boss.position)
		game.get_node("Camera2D").position = game.player.position
		game.get_node("Camera2D").reset_smoothing()
		game.queue_redraw()
		boss.queue_redraw()
		await shot("encounter-" + ["mars", "neptune", "jupiter"][sector])
	game.room = 2
	game.start_room()
	game.player.position = Vector2(970, 650)
	game.begin_boss()
	game.boss_ref.position = Vector2(1150, 500)
	game.boss_ref.set_physics_process(false)
	game.get_node("Camera2D").position = game.player.position
	game.get_node("Camera2D").reset_smoothing()
	await shot("mars-authored-boss")
	game.set_process(false)
	game.get_node("PlanetMusic").stop()
	await create_timer(.2).timeout
	game.queue_free()
	await process_frame
	quit()
