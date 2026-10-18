extends SceneTree

# Developer-only render check. Runs with a real renderer, closes automatically.
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/preview-menu.png")
	game.start_run()
	game.player.set_physics_process(false)
	game.room = 5
	game.start_room()
	game.player.position = Vector2(552, 384)
	game.player.immunity = 100
	game.player.overdrive_time = 9
	game.loot.coins = 87
	game.loot.add_item("bomb")
	game.loot.add_item("shield")
	game.player.queue_redraw()
	for i in 48:
		game.spawn_enemy()
	for enemy in game.enemies.get_children():
		enemy.set_physics_process(false)
	for frame in 150:
		for enemy in game.enemies.get_children():
			enemy._physics_process(1.0 / 60.0)
		for bullet in game.bullets.get_children():
			if not bullet.is_queued_for_deletion():
				bullet._physics_process(1.0 / 60.0)
		game.fx._process(1.0 / 60.0)
	game.begin_boss()
	game.boss_ref.set_physics_process(false)
	game.boss_ref.shot_cd = 0
	game.boss_ref._physics_process(0.016)
	for i in 12:
		game.shoot(game.player.position + Vector2.RIGHT.rotated(i * TAU / 12) * 100, Vector2.RIGHT.rotated(i * TAU / 12), 1, false)
	for enemy in game.enemies.get_children():
		if not enemy.boss:
			game.fx.sparks(enemy.position, game.planet().accent, 8, 120)
	game.loot.enemy_died(Vector2(520, 430), false)
	# Render the four actual item icons on the floor as an inventory reference.
	var item_kinds := ["medkit", "bomb", "shield", "overdrive"]
	for index in 4:
		game.loot.drop_item(Vector2(440 + index * 64, 560), item_kinds[index])
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/preview-arena.png")
	game.environment_clock = 5.5
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/preview-neptune-storm.png")
	game.player.health = 2
	game.get_node("UI/HUD").update_game(game)
	game.get_node("UI/HUD/Health").damage_flash = 0
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/preview-low-health.png")
	game.player.max_health = 20
	game.player.health = 13
	game.get_node("UI/HUD").update_game(game)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/preview-hearts-upgraded.png")
	game.player.max_health = 5
	game.player.health = 5
	game.choose_upgrade()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/preview-upgrade.png")
	root.get_texture().get_image().save_png("res://docs/preview-shop.png")
	game.close_panel()
	var atlas := Image.create(1728, 1440, false, Image.FORMAT_RGBA8)
	for index in game.total_rooms():
		game.room = index
		game.start_room()
		game.begin_boss()
		game.pending = 0
		game.player.immunity = 0
		game.player.queue_redraw()
		for enemy in game.enemies.get_children():
			enemy.set_physics_process(false)
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var shot := root.get_texture().get_image()
		if index == 7:
			shot.save_png("res://docs/preview-neptune.png")
		if index == game.total_rooms() - 1:
			shot.save_png("res://docs/preview-boss.png")
		shot.resize(576, 360, Image.INTERPOLATE_NEAREST)
		atlas.blit_rect(shot, Rect2i(0, 0, 576, 360), Vector2i((index % 3) * 576, (index / 3) * 360))
	atlas.save_png("res://docs/preview-arenas.png")
	game.queue_free()
	await process_frame
	quit()
