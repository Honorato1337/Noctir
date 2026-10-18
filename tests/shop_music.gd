extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok:
		failures += 1

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	for frame in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/preview-" + name + ".png")

func hover(control: Control) -> void:
	var event := InputEventMouseMotion.new()
	event.position = control.get_global_rect().get_center()
	event.global_position = event.position
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await process_frame

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run()
	game.player.set_physics_process(false)
	var music: AudioStreamPlayer = game.get_node("PlanetMusic")
	var identities: Array[AudioStreamWAV] = []
	for sector in 3:
		game.room = sector * 4
		game.start_room()
		identities.append(music.stream)
		check(music.playing and music.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "sector %d starts looping melodic music" % sector)
		var stream: AudioStreamWAV = music.stream
		var playback := stream.instantiate_playback()
		playback.start()
		var silent := false
		var blocks := int(ceil(stream.get_length() * 2.2))
		for second in blocks:
			var samples: PackedVector2Array = playback.mix_audio(1, int(AudioServer.get_mix_rate()))
			var energy := 0.0
			for sample in samples:
				energy += sample.length_squared()
			silent = silent or energy < 0.001
		check(playback.is_playing() and not silent, "sector %d decodes across two loop boundaries without silence" % sector)
		playback.stop()
		game.room += 1
		game.start_room()
		check(music.stream == stream, "music continues across arenas on the same planet")
	check(identities[0] != identities[1] and identities[1] != identities[2], "each planet has its own composition")
	game.room = 2
	game.start_room()
	game.loot.coins = 122
	game.player.health = 3
	game.loot.add_item("overdrive")
	game.open_shop()
	var shop: Control = game.panel
	await process_frame
	check(not shop.find_child("ModuleDesc1").visible and not shop.find_child("InventoryHint").visible and not shop.details.visible, "idle store hides specifications and long explanations")
	await capture("shop")
	var choice: Button = shop.find_child("Choice2")
	await hover(choice)
	check(shop.details.visible and shop.description.text.contains(game.shop_stock[1].desc), "real mouse hover reveals the correct module benefits and penalties")
	await capture("shop-hover")
	await hover(shop.find_child("Wallet"))
	check(not shop.details.visible, "moving away hides the details")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_TAB
	key.pressed = true
	shop._input(key)
	shop.find_child("Choice3").grab_focus()
	check(shop.details.visible and shop.description.text.contains(game.shop_stock[2].desc), "keyboard focus also reveals specifications")
	game.buy_upgrade(2)
	check(not shop.details.visible and shop.find_child("Choice3").get_meta("specifications").contains("Instalado"), "purchase refreshes tooltip state without stale prices")
	var shield: Button = shop.find_child("ShieldButton")
	shop.show_details(shield)
	check(shop.description.text.contains("5 segundos"), "supplies describe their actual effect")
	game._process(.01)
	check(is_equal_approx(music.volume_db, -80), "smoke mode keeps music silent")
	game.show_menu()
	check(not music.playing and game.get_node("MenuMusic").playing, "return to menu stops planet music and restores menu music")
	game.set_process(false)
	game.get_node("MenuMusic").stop()
	await create_timer(.2).timeout
	game.queue_free()
	await process_frame
	print("SHOP MUSIC RESULT: %d failures" % failures)
	quit(1 if failures else 0)
