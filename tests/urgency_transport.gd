extends SceneTree
var failures := 0
func _initialize() -> void:call_deferred("run")
func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+message)
	if not ok:failures += 1
func capture(name: String) -> void:
	if "--preview" not in OS.get_cmdline_user_args():return
	for i in 4:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/preview-"+name+".png")
func clear_arena(game: Node2D) -> void:
	game.pending = 0
	game.boss_spawned = true
	game.clear_container(game.enemies)
	game.finish_arena()
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.start_run()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.loot.set_physics_process(false)
	var audio = game.get_node("GameAudio")
	var muted := AudioServer.is_bus_mute(0)
	AudioServer.set_bus_mute(0,true)
	audio.enabled = true
	clear_arena(game)
	check(game.collection_left == 15 and audio.alarm_voice.playing,"victory starts 15-second collection and supplied alarm")
	check(audio.alarm_voice.stream.format == AudioStreamWAV.FORMAT_16_BITS and audio.alarm_voice.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD,"alarm is a continuous PCM loop")
	var initial_pitch: float = audio.alarm_voice.pitch_scale
	var initial_volume: float = audio.alarm_voice.volume_db
	game._physics_process(10)
	audio.sync_state()
	check(game.collection_left == 5 and audio.alarm_voice.pitch_scale > initial_pitch and audio.alarm_voice.volume_db > initial_volume,"last five seconds increase siren speed and volume")
	game.pause_run()
	audio.sync_state()
	var remaining: float = game.collection_left
	game._physics_process(40)
	check(audio.alarm_voice.stream_paused and game.collection_left == remaining,"pause freezes countdown and siren")
	game.panel.find_child("ResumeButton",true,false).pressed.emit()
	audio.sync_state()
	check(not audio.alarm_voice.stream_paused and audio.alarm_voice.playing,"resume continues the same siren")
	game.loot.coins = 27
	game.loot.slots.assign(["bomb",""])
	game.deployables.inventory = "mine"
	game.loot.drops.clear()
	game.loot.drops.append({"type":"coin","value":50,"pos":game.arena.position+Vector2(50,50)})
	game.loot.drop_item(game.arena.position+Vector2(90,50),"shield")
	game.get_node("UI/HUD").update_game(game)
	await capture("urgent-extraction")
	game._physics_process(5.1)
	check(game.state == "shop" and game.shop_left == 20,"collection timeout opens shop with a fresh 20-second deadline")
	check(game.loot.coins == 18 and game.loot.slots[0].is_empty() and game.loot.slots[1].is_empty() and game.deployables.inventory.is_empty() and game.loot.drops.is_empty(),"timeout loses ground loot, inventory and one third of run coins")
	check(game.lost_loot.coins == 50 and game.lost_loot.items == 1,"shop reports the exact lost loot")
	check(not audio.alarm_voice.playing,"siren stops immediately on boarding")
	check(game.panel.find_child("ShopTimer",true,false).text == "20s","shop visibly shows its deadline")
	await capture("timed-shop")
	game._physics_process(7)
	game.loot.coins = 1000
	game.loot.slots.assign(["",""])
	check(game.buy_supply("bomb") and game.shop_left == 13,"buying does not reset the shop timer")
	var rerolled: bool = game.reroll_shop()
	check(rerolled and game.shop_left == 13,"rerolling does not reset the shop timer")
	game._physics_process(12)
	check(game.state == "shop" and game.panel.find_child("ShopTimer",true,false).text == "01s","shop remains open through the last second")
	game._physics_process(1.1)
	check(game.state == "travel" and audio.travel_voice.playing and audio.travel_voice.stream == audio.TRANSPORT_STREAMS.rover,"shop deadline launches rover and its car-engine sound")
	var balance: int = game.loot.coins
	check(not game.buy_supply("shield") and not game.buy_upgrade(0) and not game.reroll_shop() and game.loot.coins == balance,"late purchases are rejected after automatic departure")
	game._physics_process(game.TRAVEL_DURATION)
	audio.sync_state()
	check(game.state == "playing" and not audio.travel_voice.playing,"engine sound stops at the next arena")
	game.room = 3
	game.start_room()
	clear_arena(game)
	game.loot.drops.append({"type":"coin","value":99,"pos":game.player.position+Vector2(500,0)})
	var saved: int = game.loot.coins
	game.player.position = game.portal
	check(game.board_after_clear() and game.loot.coins == saved and game.lost_loot.coins == 99,"early manual boarding also leaves uncollected loot behind")
	game.leave_shop()
	check(game.travel_kind == "rocket" and audio.travel_voice.stream == audio.TRANSPORT_STREAMS.rocket and audio.travel_voice.playing,"interplanetary departure plays rocket ignition and exhaust")
	game.show_menu()
	audio.sync_state()
	check(not audio.alarm_voice.playing and not audio.travel_voice.playing,"returning to menu stops extraction and engine sounds")
	for kind: String in ["rover","rocket"]:
		check(is_equal_approx(audio.TRANSPORT_STREAMS[kind].get_length(),game.TRAVEL_DURATION),kind+" sound matches animation duration")
	audio.enabled = false
	AudioServer.set_bus_mute(0,muted)
	game.queue_free()
	await process_frame
	print("URGENCY TRANSPORT RESULT: %d failures" % failures)
	quit(1 if failures else 0)
