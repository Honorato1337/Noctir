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
	game.set_process(false)
	game.set_physics_process(false)
	check(game.MENU_INTRO.get_length() < 27 and game.menu_loop_stream.get_length() < 27, "both runtime tracks exclude the original 25-second silent tail")
	var playback = game.menu_loop_stream.instantiate_playback()
	playback.start()
	var rate := int(AudioServer.get_mix_rate())
	var silence := 0.0
	var longest_silence := 0.0
	for block in 360:
		var buffer: PackedVector2Array = playback.mix_audio(1.0, rate / 4)
		var energy := 0.0
		for sample in buffer:
			energy += sample.length_squared() / 2
		var rms := sqrt(energy / buffer.size())
		silence = silence + 0.25 if rms < 0.0002 else 0.0
		longest_silence = maxf(longest_silence, silence)
	# WAV playback does not implement get_loop_count; verify the decoded signal.
	print("LOOP METRICS: decoded=90s longest_silence=%.2fs" % longest_silence)
	check(playback.is_playing() and 90 > game.menu_loop_stream.get_length() * 3 and longest_silence < 1, "90 seconds of decoded looping audio contain no long silent gap")
	playback.stop()
	game.on_menu_music_finished()
	game.get_node("MenuMusic").stop()
	game._process(0.01)
	check(game.get_node("MenuMusic").playing, "menu watchdog restarts unexpectedly stopped playback")
	var clips := true
	for event: String in game.get_node("GameAudio").NAMES:
		var clip: AudioStreamWAV = game.get_node("GameAudio").streams[event]
		clips = clips and clip != null and clip.get_length() > 0.02 and clip.get_length() < 2
	check(clips and game.get_node("GameAudio").streams.size() == 22, "all 22 original sound effects load and have valid durations")
	var audio = game.get_node("GameAudio")
	var original_mute := AudioServer.is_bus_mute(0)
	AudioServer.set_bus_mute(0, true)
	audio.enabled = true
	for event in ["shot", "hit", "enemy_down", "coin", "dash", "echo", "heal", "bomb"]:
		audio.play_event(event)
	check(not audio.play_event("item_pickup") and audio.play_event("boss_alert") and audio.play_event("player_hurt"), "critical alerts retain reserved voices when ordinary effects saturate the pool")
	check(audio.voices.size() == 10, "audio concurrency stays within ten voices")
	audio.enabled = false
	for voice in audio.voices:
		voice.stop()
	AudioServer.set_bus_mute(0, original_mute)
	game.start_run()
	game.player.set_physics_process(false)
	for room in [3, 7, 11]:
		game.room = room
		game.start_room()
		game.player.immunity = 100
		var clock: float = game.time_left
		game.begin_boss()
		var boss = game.boss_ref
		boss.set_physics_process(false)
		check(boss.superboss and boss.radius == 40 and is_equal_approx(boss.max_health, (40 + room * 12) * 2.4 * (1.6 + room * .06) * game.progression.enemy_health_factor() * float(game.difficulty().health)) and game.time_left == clock + 70, "sector finale %d has a larger super boss and extra combat time" % (room + 1))
		game.clear_container(game.bullets)
		boss.super_attack_timer = 0
		boss.tick_superboss(0.01)
		check(boss.super_telegraph > 0 and game.bullets.get_child_count() == 0, "super boss warns before the first pattern")
		boss.tick_superboss(0.91)
		check(game.bullets.get_child_count() >= 36 and game.bullets.get_child_count() <= 37, "first-phase radial burst has 36–37 slow projectiles and a safe corridor")
		var first_count: int = game.bullets.get_child_count()
		boss.tick_superboss(0.33)
		check(game.bullets.get_child_count() > first_count, "delayed layers overlap without another immediate attack")
		var fair_damage := true
		var safe_gap := true
		for bullet in game.bullets.get_children():
			fair_damage = fair_damage and bullet.damage == 1 and bullet.velocity.length() <= 190
			safe_gap = safe_gap and absf(angle_difference(bullet.velocity.angle(), boss.super_gap_angle)) > 0.299
		check(safe_gap, "all radial layers preserve the signaled escape corridor")
		check(fair_damage, "dense attacks retain one-point damage and dodgeable speeds")
		var pending: int = game.pending
		boss.health = boss.max_health * 0.4
		boss.tick_superboss(0.01)
		check(boss.super_phase == 2 and game.pending == pending + 8, "second phase adds a finite reinforcement group")
		boss.health = boss.max_health * 0.2
		boss.tick_superboss(0.01)
		check(boss.super_phase == 3 and game.pending == pending + 16, "third phase adds one more finite group")
		var pending_after: int = game.pending
		boss.tick_superboss(0.01)
		check(game.pending == pending_after, "phase reinforcements cannot repeat every frame")
		for pattern in [1, 2]:
			game.clear_container(game.bullets)
			boss.super_attack_index = pattern
			boss.fire_super_attack()
			check(game.bullets.get_child_count() == (26 if pattern == 1 else 30), "third-phase fan/cross has the expected density")
		game.loot.drops.clear()
		boss.hurt(99999)
		check(game.loot.drops[0].value == 24 + room, "super boss guarantees its enhanced coin reward")
		await process_frame
	game.room = 2
	game.start_room()
	game.begin_boss()
	check(not game.boss_ref.superboss, "non-final arenas keep their regular boss")
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	print("SUPERBOSS AUDIO RESULT: %d failures" % failures)
	quit(1 if failures else 0)
