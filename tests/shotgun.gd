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
	game.start_run()
	game.player.set_physics_process(false)
	game.clear_container(game.bullets)
	var player = game.player
	var shots: Array[Vector2] = player.fire(player.position,Vector2.RIGHT,false)
	check(shots.size() == 3 and game.bullets.get_child_count() == 3, "shotgun emits three pellets")
	check(shots[1].y > 0 and shots[2].y < 0, "pellets fan out on both sides")
	check(player.interval >= .45, "slower base cadence")
	player._process(.15)
	check(player.weapon_frame() == 3 and player.weapon_sprite.texture.resource_path.contains("gun2"), "authored ten-frame shotgun animation advances")
	check(player.weapon_sprite.flip_h, "left-facing source art is aligned to rightward aim")
	game.state = "paused"
	player._process(1)
	check(player.weapon_frame() == 3, "shot animation freezes on pause")
	game.state = "playing"
	game.apply_upgrade("spread")
	check(player.fire(player.position,Vector2.RIGHT,false).size() == 5, "Prisma adds two pellets")
	game.clear_container(game.bullets)
	player.echo_frames.assign([{"t":0.0,"pos":player.position,"health":5,"shots":shots,"damage":1.0,"weapon_frame":4},{"t":100.0,"pos":player.position,"shots":[],"damage":1.0}])
	player._physics_process(.01)
	check(game.bullets.get_child_count() == 3 and player.echo_weapon_frame == 4, "Echo replays three pellets and original weapon frame")
	game.start_run(false,0,"medium","endless")
	var survival_size: Vector2 = game.arena.size
	var survival_obstacles: Array = game.obstacles.duplicate()
	var survival_sector: int = game.get_node("Arena").sector_index
	game.run_mode = "campaign"
	game.room = 12
	game.start_room()
	check(game.arena.size == survival_size and game.obstacles == survival_obstacles and game.get_node("Arena").sector_index == survival_sector, "arena 13 matches original survival dimensions, rocks and visual sector")
	check(not game.blocked(game.player.position,20) and not game.get_node("Arena").route(game.player.position,game.portal,46).is_empty(), "final arena has clear spawn and navigable extraction")
	if "--preview" in OS.get_cmdline_user_args():
		game.player.immunity = 999
		game.player.aim = Vector2.RIGHT
		game.player.fire(game.player.position,Vector2.RIGHT,false)
		for i in 4: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tmp/shotgun-final-arena.png")
	game.queue_free()
	await process_frame
	quit(failures)
