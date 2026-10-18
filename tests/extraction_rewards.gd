extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, detail: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + detail)
	if not ok: failures += 1
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.start_run()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.loot.set_physics_process(false)
	game.loot.coins = 100
	game.loot.slots.assign(["bomb", "shield"])
	game.deployables.inventory = "mine"
	game.finish_arena()
	game._physics_process(15.1)
	check(game.state == "shop" and game.loot.coins == 66, "timeout deducts one third rounded up")
	check(game.loot.slots == ["", ""] and game.deployables.inventory.is_empty(), "timeout empties all three slots")
	game.board_after_clear(true)
	check(game.loot.coins == 66, "timeout cannot charge twice")
	game.start_run()
	game.set_physics_process(false)
	game.loot.coins = 90
	game.loot.slots.assign(["bomb", "shield"])
	game.deployables.inventory = "turret"
	game.finish_arena()
	game.player.position = game.portal
	game.board_after_clear()
	check(game.loot.coins == 90 and game.loot.slots[0] == "bomb" and game.deployables.inventory == "turret", "timely boarding preserves wallet and inventory")
	for room in [3,7,11]:
		game.room = room
		var before: int = game.run_chances_left
		game.reward_planet_superboss()
		game.reward_planet_superboss()
		check(game.run_chances_left == before+1, "each planetary superboss awards exactly one chance")
	check(game.run_chances_left == 6, "bonus chances can exceed initial three")
	game.room = 12
	game.reward_planet_superboss()
	check(game.run_chances_left == 6, "final alien is not a planetary bonus")
	game.run_difficulty = "easy"
	var easy: float = game.planet_music_rate()
	game.run_difficulty = "hard"
	check(game.planet_music_rate() > easy, "hard mode music is faster")
	game.finish(true, "A expedição terminou.")
	check("Obrigado por jogar" in game.panel.find_child("Description",true,false).text, "campaign victory thanks the player")
	game.queue_free()
	await process_frame
	quit(failures)
