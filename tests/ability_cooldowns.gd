extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, detail: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+detail)
	if not ok: failures += 1
func seed_echo(player: Node2D) -> void:
	player.history.clear()
	for i in 60:
		player.history.append({"pos":player.position,"health":player.health,"t":float(i)/60,"shots":[],"damage":1.0})
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.progression.abilities.berserk = 1
	game.start_run(false,0,"medium","endless")
	game.player.set_physics_process(false)
	check(game.activate_berserk() and game.berserk_cd == 90, "infinite Berserk starts ninety-second cooldown")
	check(not game.activate_berserk(), "Berserk cannot bypass cooldown")
	seed_echo(game.player)
	game.player.rewind()
	check(game.echo_cd == 45 and not game.player.rewind_ready, "infinite Echo starts forty-five-second cooldown")
	seed_echo(game.player)
	game.player.rewind()
	check(game.player.history.size() == 60, "Echo cannot bypass cooldown")
	for state: String in ["paused","death","shop"]:
		game.state = state
		game.shop_left = 20
		game._physics_process(1)
		check(game.berserk_cd == 90 and game.echo_cd == 45, "cooldowns freeze during "+state)
	game.state = "playing"
	game._physics_process(10)
	check(game.berserk_cd == 80 and game.echo_cd == 35, "only combat advances cooldowns")
	game.survival.start_wave()
	check(game.berserk_cd == 80 and game.echo_cd == 35, "new horde preserves cooldowns")
	game.player.berserk_time = 0
	game.get_node("UI/HUD").update_game(game)
	var hud = game.get_node("UI/HUD")
	check(hud.get_node("Echo").text.contains("35s") and hud.get_node("BerserkCard/BerserkStatus").text.contains("80s"), "compact HUD shows both remaining times")
	if "--preview" in OS.get_cmdline_user_args():
		for frame in 3: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/preview-ability-cooldowns.png")
	game._physics_process(35)
	check(game.player.rewind_ready and game.echo_cd == 0 and game.berserk_cd == 45, "Echo recharges before Berserk")
	game._physics_process(45)
	check(game.activate_berserk(), "Berserk can be used again in same run")
	seed_echo(game.player)
	game.player.rewind()
	check(game.echo_cd == 45, "Echo can be used again in same run")
	game.restart_current_run()
	check(game.berserk_cd == 0 and game.echo_cd == 0, "new run clears cooldowns")
	game.start_run()
	check(game.activate_berserk(), "campaign Berserk first activation works")
	game.player.berserk_time = 0
	check(not game.activate_berserk() and game.berserk_cd == 0, "campaign keeps once-per-run Berserk")
	seed_echo(game.player)
	game.player.rewind()
	check(not game.player.rewind_ready and game.echo_cd == 0, "campaign keeps once-per-arena Echo")
	game.queue_free()
	await process_frame
	quit(failures)
