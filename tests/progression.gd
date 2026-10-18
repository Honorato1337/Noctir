extends SceneTree

const Progression = preload("res://scripts/progression.gd")
var failures := 0
const TEST_PATH := "res://tmp/progression-test.cfg"

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, detail: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + detail)
	if not ok:
		failures += 1

func run() -> void:
	var profile := Progression.new()
	profile.save_path = TEST_PATH
	check(profile.award_score(1234, false) == 12 and profile.coins == 12 and profile.remainder == 34, "score converts to coins with fractional progress preserved")
	check(profile.award_score(76, false) == 1 and profile.coins == 13 and profile.remainder == 10, "score remainder carries between runs")
	check(profile.award_score(-999, false) == 0 and profile.coins == 13, "invalid negative scores cannot remove progress")
	check(not profile.buy(0, false) and profile.coins == 13, "unaffordable permanent upgrades cannot be purchased")
	profile.coins = 5000
	check(profile.buy(0, true) and profile.coins == 4955 and profile.levels.health == 1 and profile.price(0) == 100, "permanent purchase charges exact price and next level costs more")
	var reloaded := Progression.new()
	reloaded.save_path = TEST_PATH
	check(reloaded.load_profile() == OK and reloaded.coins == 4955 and reloaded.levels.health == 1 and reloaded.remainder == 10, "balance, levels and remainder survive reopening the save")
	check(reloaded.buy(1, true), "a second purchase replaces an existing save successfully")
	var second_load := Progression.new()
	second_load.save_path = TEST_PATH
	check(second_load.load_profile() == OK and second_load.coins == 4925 and second_load.levels.health == 1 and second_load.levels.damage == 1, "replaced profile retains both purchases and the remaining balance")
	for i in 2:
		reloaded.buy(0, false)
	var before := reloaded.coins
	check(reloaded.price(0) == -1 and not reloaded.buy(0, false) and reloaded.coins == before, "maximum rank cannot be exceeded or charged again")
	check(not reloaded.buy(-1, false) and not reloaded.buy(999, false), "unknown upgrade indices are rejected")
	var bad_path := Progression.new()
	bad_path.save_path = "res://tmp/missing-progression-directory/profile.cfg"
	bad_path.coins = 100
	check(not bad_path.buy(0) and bad_path.coins == 100 and bad_path.levels.health == 0, "failed save rolls back a purchase without losing coins")
	var invalid := ConfigFile.new()
	invalid.set_value("wallet", "coins", -10)
	invalid.set_value("wallet", "remainder", 150)
	invalid.set_value("upgrades", "health", 999)
	invalid.set_value("upgrades", "damage", "broken")
	invalid.save(TEST_PATH)
	reloaded.load_profile()
	check(reloaded.coins == 0 and reloaded.remainder == 99 and reloaded.levels.health == 3 and reloaded.levels.damage == 0, "out-of-range and malformed saved values are sanitized")
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.progression.coins = 5000
	game.panel.find_child("PermanentShopButton", true, false).pressed.emit()
	check(game.state == "permanent" and game.panel.name == "PermanentShop", "main menu opens the permanent shop")
	for i in Progression.UPGRADES.size():
		game.panel.find_child("PermanentBuy%d" % (i + 1), true, false).pressed.emit()
	check(game.progression.levels.values().count(1) == 6, "all six authored shop buttons purchase their respective upgrades")
	game.panel.find_child("BackButton", true, false).pressed.emit()
	check(game.state == "menu", "permanent shop returns to main menu")
	game.start_run()
	game.player.set_physics_process(false)
	check(game.player.max_health == 6 and game.player.health == 6 and is_equal_approx(game.player.damage, 1.05), "fresh run starts with permanent life and damage bonuses")
	check(is_equal_approx(game.player.interval, 0.18 / 1.04) and is_equal_approx(game.player.speed, 218.4) and is_equal_approx(game.player.dash_recharge, 1.504) and game.time_bonus == 2, "permanent cadence, movement, dash and arena-time bonuses apply")
	check(game.chosen_upgrades.is_empty() and game.loot.coins == 0 and game.loot.slots == ["", ""], "permanent progression does not grant run money or temporary modules")
	game.score = 1234
	before = game.progression.coins
	game.finish(false, "Teste")
	check(game.run_reward == 12 and game.progression.coins == before + 12 and game.panel.find_child("RewardValue", true, false).text.contains("+12"), "defeat awards coins and shows them in the results")
	game.finish(false, "Teste repetido")
	game.panel.find_child("PermanentShopButton", true, false).pressed.emit()
	game.show_menu()
	check(game.progression.coins == before + 12 and game.progression.remainder == 34, "repeated finish and result navigation cannot duplicate rewards")
	game.start_run()
	game.player.set_physics_process(false)
	check(game.player.max_health == 6 and is_equal_approx(game.player.damage, 1.05), "permanent bonuses persist without compounding on restart")
	game.score = 66
	game.start_run()
	game.player.set_physics_process(false)
	check(game.progression.coins == before + 13 and game.progression.remainder == 0, "abandoning through restart settles the old score once")
	game.score = 200
	game.show_menu()
	check(game.progression.coins == before + 15, "returning to menu banks the abandoned run")
	game.start_run()
	game.player.set_physics_process(false)
	game.score = 100
	before = game.progression.coins
	var expected: int = (100 + game.player.health * 200) / 100
	game.finish(true, "Teste de vitória")
	check(game.progression.coins == before + expected, "victory converts the final score including its life bonus")
	game.start_run()
	game.player.set_physics_process(false)
	game.score = 100
	before = game.progression.coins
	game.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	check(game.progression.coins == before + 1 and not game.run_active, "normal window close settles the current run")
	game.set_process(false)
	game.get_node("MenuMusic").stop()
	game.get_node("PlanetMusic").stop()
	await create_timer(.2).timeout
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	print("PROGRESSION RESULT: %d failures" % failures)
	quit(1 if failures else 0)
