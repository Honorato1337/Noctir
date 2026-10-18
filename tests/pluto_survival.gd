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
	game.start_run(false,0,"hard","endless")
	game.player.set_physics_process(false)
	game.weather.set_physics_process(false)
	var weather = game.weather
	check(game.planet().name == "PLUTÃO" and game.get_node("Arena").sector_index == 4, "survival loads dedicated Pluto arena and visual theme")
	check(game.arena.size == Vector2(2048,1344) and game.obstacles.size() == 8, "double-size arena has eight frozen rock formations")
	check(not game.blocked(game.player.position,20), "central player spawn is clear")
	for gate: Vector2 in game.get_node("Arena").spawn_gates():
		check(not game.get_node("Arena").route(game.player.position,gate,46).is_empty(), "boss navigation connects center to entry gate")
	for kind: String in weather.PLUTO_EVENTS:
		game.player.health = game.player.max_health
		game.player.immunity = 999
		weather.start_event(kind)
		check(weather.event == kind and weather.active and weather.warning >= 2, "Pluto event has advance warning: "+kind)
		weather._physics_process(weather.warning+0.01)
		weather.pulse = 0
		weather._physics_process(0.01)
		check(not weather.strikes.is_empty(), "event produces its own hazards: "+kind)
		if kind == "rift":
			var at: Vector2 = weather.vortices[0].pos+Vector2(100,0)
			check(weather.vortices.size() == 2 and weather.player_force(at).length() > 0, "gravitational rifts attract with two moving cores")
		if kind == "whiteout":
			check(weather.player_force(game.player.position).length() > 0 and weather.player_slowdown(game.player.position) < 1, "whiteout adds wind and cold slowdown")
		weather.strikes.clear()
		var strike_kind: String = {"nitrogen":"nitrogen","comets":"comet","rift":"void","whiteout":"ice"}[kind]
		weather.add_strike(strike_kind,game.player.position)
		game.player.immunity = 0
		var hp: int = game.player.health
		weather.pulse = 99
		weather.vortices.clear()
		weather._physics_process(0.3)
		check(game.player.health == hp, "marked area cannot damage before impact: "+kind)
		weather.strikes[0].age = weather.strikes[0].warning
		weather._physics_process(0.01)
		check(game.player.health < hp, "impact causes damage: "+kind)
		if kind == "nitrogen": check(game.frost_slowdown(game.player.position) == 0.6, "active nitrogen slows the player inside its field")
		var age: float = weather.age
		game.state = "paused"
		weather._physics_process(5)
		check(weather.age == age, "pause freezes Pluto event: "+kind)
		game.state = "playing"
		weather.start_event()
		check(weather.event != kind, "random selection avoids immediate repetition: "+kind)
	weather.start_event("rift")
	game.open_shop()
	check(not weather.active and weather.strikes.is_empty() and weather.vortices.is_empty(), "shop clears every environmental threat")
	game.leave_shop()
	check(game.state == "playing" and game.shop_left == 10, "leaving shop resumes same Pluto arena")
	if "--preview" in OS.get_cmdline_user_args():
		root.size = Vector2i(1920,1080)
		game.player.immunity = 999
		game.player.health = game.player.max_health
		game.flash = 0
		game.elapsed = 20
		game.progression.abilities.berserk = 1
		game.survival.wave = 4
		game.survival.start_wave()
		for i in 36: game.spawn_enemy()
		weather.start_event("nitrogen")
		weather.age = 3
		for at: Vector2 in [game.player.position+Vector2(-160,20),game.player.position+Vector2(190,-70),game.player.position+Vector2(140,160)]:
			weather.add_strike("nitrogen",at)
			weather.strikes[-1].age = 2
		weather.queue_redraw()
		game.message_time = 0
		for i in 5: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/media/10-plutao.png")
	game.start_run()
	check(game.planet().name == "MARTE" and game.get_node("Arena").sector_index == 0, "campaign retains Mars identity")
	game.queue_free()
	await process_frame
	quit(failures)
