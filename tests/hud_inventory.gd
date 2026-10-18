extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, detail: String) -> void:
	if condition:
		print("PASS: " + detail)
	else:
		failures += 1
		push_error("FAIL: " + detail)

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.start_run()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.loot.set_physics_process(false)
	var hud = game.get_node("UI/HUD")
	var first: TextureRect = hud.get_node("SlotOne/SlotOneIcon")
	var second: TextureRect = hud.get_node("SlotTwo/SlotTwoIcon")
	game.loot.drop_item(game.player.position, "bomb")
	game.loot._physics_process(0)
	hud.update_game(game)
	check(first.texture == game.loot.ICONS.bomb, "ground pickup fills first slot with the same icon")
	game.loot.drop_item(game.player.position, "shield")
	game.loot._physics_process(0)
	hud.update_game(game)
	check(second.texture == game.loot.ICONS.shield, "second pickup fills second slot with shield icon")
	game.loot.drop_item(game.player.position, "medkit")
	game.loot._physics_process(0)
	check(game.loot.drops.size() == 1, "third item stays on ground when slots are full")
	game.loot.use_slot(0)
	hud.update_game(game)
	check(first.texture == null and second.texture == game.loot.ICONS.shield, "using first slot clears only its icon")
	game.loot._physics_process(0)
	hud.update_game(game)
	check(first.texture == game.loot.ICONS.medkit and game.loot.drops.is_empty(), "remaining ground item fills newly freed slot")
	game.loot.use_slot(1)
	hud.update_game(game)
	check(second.texture == null, "shield consumption clears second icon")
	game.start_run()
	hud.update_game(game)
	check(first.texture == null and second.texture == null, "new run resets both inventory icons")
	for slot in ["SlotOne","SlotTwo","SlotThree","EchoCard"]:
		check(hud.get_node(slot).get_script() == load("res://scripts/pixel_slot.gd"), "shared pixel frame on " + slot)
	game.player.rewind_ready = false
	hud.update_game(game)
	check(hud.get_node("EchoCard/EchoStatus").text == "USADO" and hud.get_node("EchoCard").charge == 0.0, "campaign Eco slot marks the consumed charge")
	check(hud.get_node("Echo").position.y >= hud.get_node("EchoCard").position.y + 64, "Eco name stays beneath its frame")
	game.run_mode = "endless"
	game.echo_cd = 30
	hud.update_game(game)
	check(hud.get_node("EchoCard/EchoStatus").text == "30s" and is_equal_approx(hud.get_node("EchoCard").charge,1.0/3.0), "survival Eco slot shows recharge time and progress")
	game.echo_cd = 0
	hud.update_game(game)
	check(hud.get_node("EchoCard/EchoStatus").text.is_empty() and hud.get_node("EchoCard/EchoIcon").modulate.a == 1.0, "ready Eco restores the unobstructed icon")
	print("HUD INVENTORY RESULT: %d failures" % failures)
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
