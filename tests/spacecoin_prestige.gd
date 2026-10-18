extends SceneTree

const Progression = preload("res://scripts/progression.gd")
const TEST_PATH := "res://tmp/spacecoin-prestige-test.cfg"
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, detail: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + detail)
	if not ok:
		failures += 1

func maximize(profile: RefCounted) -> void:
	for upgrade: Dictionary in Progression.UPGRADES:
		profile.levels[upgrade.key] = profile.max_level(upgrade.key)

func shot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	for frame in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/preview-" + name + ".png")

func run() -> void:
	var legacy := ConfigFile.new()
	legacy.set_value("wallet", "coins", 1250)
	legacy.set_value("wallet", "remainder", 34)
	legacy.set_value("upgrades", "health", 2)
	legacy.save(TEST_PATH)
	var profile := Progression.new()
	profile.save_path = TEST_PATH
	check(profile.load_profile() == OK and profile.coins == 1250 and profile.levels.health == 2 and profile.space_coins == 0 and profile.prestige == 0, "legacy saves gain empty special wallets without losing coins or attributes")
	check(profile.award_space_coins(3) == 3 and profile.award_space_coins(-9) == 0 and profile.coins == 1250, "SpaceCoin awards cannot spend or mix ordinary Coins")
	var reopened := Progression.new()
	reopened.save_path = TEST_PATH
	reopened.load_profile()
	check(reopened.space_coins == 3 and reopened.remainder == 34, "SpaceCoin persists independently with score remainder retained")
	check(not profile.reset_for_prestige(false), "large balance alone cannot prestige with incomplete attributes")
	maximize(profile)
	profile.coins = 999
	check(not profile.can_prestige() and not profile.reset_for_prestige(false), "maximum attributes alone cannot prestige below 1000 Coins")
	profile.coins = 1250
	check(profile.reset_for_prestige() and profile.coins == 250 and profile.prestige == 1 and profile.prestige_cycles == 1 and profile.space_coins == 3 and profile.remainder == 34, "prestige costs exactly 1000 Coins and preserves excess, SpaceCoin and fractional score")
	check(profile.levels.values().count(0) == 6 and not profile.reset_for_prestige(false), "prestige zeros all six attributes and cannot immediately repeat")
	reopened.load_profile()
	check(reopened.coins == 250 and reopened.prestige == 1 and reopened.prestige_cycles == 1 and reopened.levels.values().count(0) == 6, "complete prestige transaction survives reopening")
	maximize(profile)
	profile.coins = 1000
	check(profile.reset_for_prestige() and profile.prestige == 2 and profile.space_coins == 3 and profile.coins == 0, "another fully completed cycle adds one more Prestige")
	var broken := Progression.new()
	broken.save_path = "res://tmp/missing-prestige-directory/profile.cfg"
	maximize(broken)
	broken.coins = 1400
	broken.space_coins = 9
	broken.prestige = 4
	var levels := broken.levels.duplicate()
	check(not broken.reset_for_prestige() and broken.coins == 1400 and broken.prestige == 4 and broken.space_coins == 9 and broken.levels == levels and broken.prestige_cycles == 0, "save failure rolls back the entire reset without losing attributes or currency")
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.progression.save_path = TEST_PATH
	game.progression.space_coins = 8
	game.progression.coins = 999
	maximize(game.progression)
	game.show_permanent_shop()
	game.panel.find_child("EquipmentTab").pressed.emit()
	check(game.panel.find_child("Equipment").visible and not game.panel.find_child("Attributes").visible and game.panel.find_child("PermanentWallet").text.contains("SPACECOIN 8"), "shop opens the marked equipment test page with its special wallet")
	var previews: Array[Node] = game.panel.find_child("Equipment").get_node("Catalog").get_children()
	check(previews.size() == 3 and previews[0].disabled and previews[1].disabled and previews[2].disabled, "future suit, weapon and module previews cannot charge currency")
	await shot("equipment-test")
	game.panel.find_child("SkinsTab").pressed.emit()
	check(game.panel.find_child("Skins").visible, "skins page is available as an explicitly future catalog")
	await shot("skins-future")
	game.panel.find_child("PrestigeTab").pressed.emit()
	var dialog: ConfirmationDialog = game.panel.find_child("PrestigeConfirmation")
	check(game.panel.find_child("PrestigeButton").disabled, "prestige button remains disabled when balance is insufficient")
	game.request_prestige()
	check(not dialog.visible, "an invalid reset cannot open confirmation")
	game.progression.coins = 1000
	game.refresh_permanent_shop()
	check(not game.panel.find_child("PrestigeButton").disabled, "eligible player can access prestige")
	await shot("prestige-ready")
	game.panel.find_child("PrestigeButton").pressed.emit()
	check(dialog.visible and game.progression.coins == 1000 and game.progression.maxed_attributes() == 6, "opening confirmation never spends Coins or resets attributes")
	await shot("prestige-confirmation")
	dialog.get_cancel_button().pressed.emit()
	await process_frame
	check(not dialog.visible and game.progression.coins == 1000 and game.progression.maxed_attributes() == 6, "cancel preserves the entire profile")
	game.request_prestige()
	dialog.get_ok_button().pressed.emit()
	check(game.progression.prestige == 1 and game.progression.space_coins == 8 and game.progression.coins == 0 and game.progression.maxed_attributes() == 0, "confirm performs exactly one reset through the authored UI")
	check(game.panel.find_child("PrestigeButton").disabled and game.panel.find_child("PermanentWallet").text.contains("PRESTÍGIO 1"), "wallet and eligibility update immediately after prestige")
	await shot("prestige-complete")
	game.start_run()
	game.player.set_physics_process(false)
	game.contracts.set_physics_process(false)
	check(game.player.max_health == 6 and is_equal_approx(game.player.damage, 1.1) and game.time_bonus == 0, "next run uses reset attributes with the persistent cycle baseline")
	game.contracts.enabled = true
	game.contracts.kind = "bosses"
	game.contracts.target = 1
	game.contracts.reward = 1
	game.contracts.completed = false
	game.contracts.expired = false
	game.contracts.progress = 0
	var coins: int = game.loot.coins
	# Exercise the real immediate-save path against the isolated test profile.
	game.smoke_mode = false
	game.contracts.record("boss")
	game.smoke_mode = true
	game.contracts.record("boss")
	reopened.load_profile()
	check(game.progression.space_coins == 9 and reopened.space_coins == 9 and game.run_space_reward == 1 and game.loot.coins == coins, "contract saves one SpaceCoin immediately without modifying arena coins")
	game.finish(false, "Teste de persistência")
	check(game.progression.space_coins == 9 and game.panel.find_child("RewardValue").text.contains("+1 SPACECOIN"), "death retains special currency and reports the contract reward")
	game.start_run()
	game.player.set_physics_process(false)
	check(game.run_space_reward == 0 and game.progression.space_coins == 9, "new run resets its report while keeping the SpaceCoin wallet")
	game.set_process(false)
	game.get_node("PlanetMusic").stop()
	game.get_node("MenuMusic").stop()
	await create_timer(.2).timeout
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	print("SPACECOIN PRESTIGE RESULT: %d failures" % failures)
	quit(1 if failures else 0)
