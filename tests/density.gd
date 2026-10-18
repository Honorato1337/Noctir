extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.start_run()
	game.room = 12 if "--god" in OS.get_cmdline_user_args() else 11 if "--jupiter" in OS.get_cmdline_user_args() else 7
	game.start_room()
	game.player.immunity = 10000
	game.player.spread = 2
	game.player.damage = 2
	game.begin_boss()
	game.boss_ref.health = game.boss_ref.max_health * 0.2
	if "--weather" in OS.get_cmdline_user_args():
		game.weather.start_event()
		game.weather.age = game.weather.warning
	Input.action_press("aim_up")
	var peak_enemies := 0
	var peak_bullets := 0
	var peak_particles := 0
	var peak_fields := 0
	var peak_weather := 0
	for frame in 720:
		await physics_frame
		var desired := Vector2(576 + sin(frame * 0.019) * 350, 384 + cos(frame * 0.027) * 180)
		if not game.blocked(desired, 18):
			game.player.position = desired
		peak_enemies = maxi(peak_enemies, game.enemies.get_child_count())
		peak_bullets = maxi(peak_bullets, game.bullets.get_child_count())
		peak_particles = maxi(peak_particles, game.fx.particles.size())
		peak_weather = maxi(peak_weather, game.weather.strikes.size())
		peak_fields = maxi(peak_fields, game.encounters.fields.size())
	Input.action_release("aim_up")
	print("DENSITY: enemies=%d projectiles=%d particles=%d fields=%d state=%s" % [peak_enemies, peak_bullets, peak_particles, peak_fields, game.state])
	var passed: bool = peak_enemies >= 45 and peak_enemies <= game.MAX_ACTIVE_ENEMIES and peak_bullets >= 20 and peak_particles > 100 and peak_particles <= game.fx.MAX_PARTICLES and game.state == "playing" and peak_fields > 0 and peak_fields <= game.encounters.MAX_FIELDS
	if "--weather" in OS.get_cmdline_user_args():
		passed = passed and peak_weather > 0 and peak_weather <= game.weather.MAX_STRIKES
		print("WEATHER PEAK: %d impacts" % peak_weather)
	print("DENSITY RESULT: " + ("PASS" if passed else "FAIL"))
	game.queue_free()
	await process_frame
	quit(0 if passed else 1)
