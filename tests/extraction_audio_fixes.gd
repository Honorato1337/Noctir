extends SceneTree
const Vehicles = preload("res://scripts/expedition_vehicles.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, detail: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+detail)
	if not ok: failures += 1
func verify_loop(stream: AudioStreamWAV, label: String) -> void:
	var rate := int(AudioServer.get_mix_rate())
	var playback := stream.instantiate_playback()
	var longest := 0.0
	for cycle in 3:
		playback.start(stream.get_length()-0.20)
		var samples := playback.mix_audio(1.0,int(rate*0.45))
		var quiet := 0.0
		var block := maxi(1,rate/100)
		for at in range(0,samples.size()-block,block):
			var energy := 0.0
			for i in range(at,at+block): energy += samples[i].length_squared()*0.5
			quiet = quiet+0.01 if sqrt(energy/block) < 0.0005 else 0.0
			longest = maxf(longest,quiet)
		check(playback.is_playing(),label+" remains playing across seam %d" % cycle)
		playback.stop()
	print("LOOP SEAM "+label+": max quiet %.3fs" % longest)
	check(longest < 0.08 and stream.format == AudioStreamWAV.FORMAT_16_BITS,label+" loops in PCM without audible silent pause")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	verify_loop(game.menu_loop_stream,"menu")
	game.start_run()
	game.player.set_physics_process(false)
	for sector in 3:
		game.room = sector*4
		game.start_room()
		game.play_planet_music()
		verify_loop(game.planet_music_stream,["mars","neptune","jupiter"][sector])
	var original_mute := AudioServer.is_bus_mute(0)
	AudioServer.set_bus_mute(0,true)
	game.start_run()
	game.player.set_physics_process(false)
	var audio = game.get_node("GameAudio")
	audio.enabled = true
	for chance in 3:
		game.player.health = 0
		game.handle_player_death()
		check(audio.death_voice.playing and not audio.death_voice.stream.loop and audio.death_voice.stream.get_length() > 0,"dedicated non-looping morte1 plays on death %d" % (chance+1))
		check(game.run_chances_left == 2-chance,"death decrements run chances exactly once")
		game.handle_player_death()
		check(game.run_chances_left == 2-chance,"death screen cannot retrigger death")
		if chance < 2:
			game.continue_after_death()
			check(not audio.death_voice.playing and not game.get_node("PlanetMusic").stream_paused,"continue stops death clip and resumes planet music")
	check(game.state == "ended" and not audio.last_played.has("defeat"),"last death retains morte1 instead of overlapping defeat sound")
	audio.death_voice.stop()
	AudioServer.set_bus_mute(0,original_mute)
	var image := Vehicles.texture("rocket").get_image()
	var a := image.get_region(Rect2i(0,0,32,32)).get_used_rect()
	var b := image.get_region(Rect2i(32,0,32,32)).get_used_rect()
	check(a.position.y == b.position.y and absf(a.get_center().x-b.get_center().x) <= 0.5,"rocket hull stays centered between animation frames")
	game.start_run()
	game.room = 3
	game.start_room()
	game.state = "exit"
	game.player.position = game.portal
	game.start_transfer()
	var travel = game.panel
	var start: Vector2 = travel.rocket_position(0)
	check(start == travel.rocket_position(0.18) and start.y > 172 and start.y < 540,"rocket ignites on screen before ascent")
	var last := start
	var valid := true
	for i in range(1,145):
		var current: Vector2 = travel.rocket_position(float(i)/144)
		valid = valid and current.x == start.x and current.y <= last.y and last.y-current.y < 15
		last = current
	check(valid and last.y < 0,"rocket accelerates upward smoothly without lateral frame jumps")
	game.queue_free()
	await process_frame
	print("EXTRACTION AUDIO FIXES RESULT: %d failures" % failures)
	quit(1 if failures else 0)
