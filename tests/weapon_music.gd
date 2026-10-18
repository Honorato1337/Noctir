extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, detail: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + detail)
	if not ok:
		failures += 1

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	var music: AudioStreamPlayer = game.get_node("MenuMusic")
	check(music.playing and music.stream.resource_path.ends_with("soundmenu1.wav") and music.stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "menu starts with the trimmed non-looping introduction")
	music.finished.emit()
	check(music.playing and music.stream == game.menu_loop_stream and music.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "finishing the introduction switches to the guaranteed looping track")
	music.seek(1.0)
	var before := music.get_playback_position()
	game.show_permanent_shop()
	game.show_menu()
	game.show_settings()
	check(music.playing and music.get_playback_position() >= before - 0.05, "menu navigation keeps the track playing without restarting")
	game.set_volume(23)
	check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(0)), 0.23), "menu track uses the configured Master volume")
	game.set_muted(true)
	check(AudioServer.is_bus_mute(0), "menu track respects mute")
	game.set_muted(false)
	game.start_run()
	game.player.set_physics_process(false)
	check(not music.playing, "menu music stops when combat starts")
	var player = game.player
	check(player.weapon_sprite.texture.atlas.resource_path.ends_with("assets/gun/gun.png") and player.weapon_sprite.texture.region == Rect2(7, 12, 10, 9), "weapon uses the supplied art without editing its source")
	for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		player.aim = direction
		player.update_animation()
		check(is_equal_approx(player.weapon.rotation, direction.angle()) and player.weapon_sprite.flip_v == (direction.x < 0), "gun follows aim %s and remains upright" % direction)
	check(player.weapon.z_index == 1, "gun is in front when aiming downward")
	player.aim = Vector2.UP
	player.update_animation()
	check(player.weapon.z_index == -1, "gun goes behind the astronaut when aiming upward")
	player.immunity = 0.6
	player.clock = 0
	player.update_animation()
	check(not player.weapon.visible and not player.visual.visible, "gun follows the player's invulnerability blink")
	player.immunity = 0
	player.history.clear()
	for frame in 60:
		player.history.append({"t": float(frame) / 60, "pos": player.position, "health": player.health, "shots": [], "damage": 1.0, "visual_frame": 0, "aim": Vector2.LEFT})
	player.clock = 1
	player.rewind()
	player.update_animation()
	check(player.echo_weapon.visible and is_equal_approx(absf(player.echo_weapon.rotation), PI) and player.echo_weapon_sprite.flip_v, "echo weapon replays the recorded aim")
	game.show_menu()
	check(music.playing, "returning to menu starts music again")
	game.set_process(false)
	music.stop()
	# Let the audio mixer release the short-lived MP3 playback instances.
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	print("WEAPON MUSIC RESULT: %d failures" % failures)
	quit(1 if failures else 0)
