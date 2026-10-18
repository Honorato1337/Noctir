extends SceneTree

const Settings = preload("res://scripts/user_settings.gd")
const TEST_PATH := "res://tmp/settings-test.cfg"
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, detail: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + detail)
	if not ok:
		failures += 1

func run() -> void:
	var settings := Settings.new()
	settings.save_path = TEST_PATH
	settings.volume = 37
	settings.muted = true
	settings.played_seconds = 3661.5
	check(settings.save_settings() == OK, "volume, mute and total play time save to an isolated file")
	var loaded := Settings.new()
	loaded.save_path = TEST_PATH
	loaded.load_settings()
	check(loaded.volume == 37 and loaded.muted and loaded.played_seconds == 3661.5, "audio and play time survive reopening")
	check(loaded.play_time_text() == "01:01:01", "play time formats as hours, minutes and seconds")
	var date := Time.get_datetime_dict_from_system()
	check(loaded.clock_text().begins_with("%02d/%02d/%04d" % [date.day, date.month, date.year]), "menu clock follows the system's local calendar")
	var master := AudioServer.get_bus_index("Master")
	var old_volume := AudioServer.get_bus_volume_db(master)
	var old_mute := AudioServer.is_bus_mute(master)
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	check(game.panel.find_child("Record", true, false).get_parent().get_parent().name == "Astronaut", "record sits in the astronaut panel")
	check(not game.panel.find_child("Eyebrow", true, false).text.contains("ONE MORE"), "live date and total play time replace the old heading")
	game.panel.find_child("SettingsButton", true, false).pressed.emit()
	check(game.state == "settings", "main menu opens settings")
	game.panel.find_child("VolumeSlider", true, false).value = 37
	check(game.preferences.volume == 37 and is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(master)), 0.37), "volume slider actually controls the Master bus")
	game.panel.find_child("MuteButton", true, false).button_pressed = true
	check(AudioServer.is_bus_mute(master) and game.panel.find_child("TestSoundButton", true, false).disabled, "mute silences audio and disables sound preview")
	game.panel.find_child("MuteButton", true, false).button_pressed = false
	game.panel.find_child("VolumeSlider", true, false).value = 0
	check(AudioServer.is_bus_mute(master), "zero volume is fully silent")
	game.panel.find_child("VolumeSlider", true, false).value = 64
	check(not AudioServer.is_bus_mute(master), "raising volume restores audio when mute is off")
	check(game.preferences.test_tone().data.size() == 22050, "preview generates a complete short audio sample")
	game.panel.find_child("BackButton", true, false).pressed.emit()
	check(game.state == "menu", "settings returns to the menu")
	game.start_run()
	game.player.set_physics_process(false)
	var before: float = game.preferences.played_seconds
	game._process(3.5)
	check(is_equal_approx(game.preferences.played_seconds, before + 3.5), "total play time advances inside a run")
	game.state = "paused"
	game._process(10)
	game.state = "shop"
	game._process(10)
	game.show_menu()
	game._process(10)
	check(is_equal_approx(game.preferences.played_seconds, before + 3.5), "menus, shop and pause do not inflate play time")
	game.start_run()
	game.player.set_physics_process(false)
	var hearts = game.get_node("UI/HUD/Health")
	game.player.max_health = 20
	game.player.health = 2
	game.get_node("UI/HUD").update_game(game)
	check(hearts.current == 2 and hearts.maximum == 20 and hearts.damage_flash > 0, "hearts track damage and permanent plus temporary life upgrades")
	var contained := true
	for rect: Rect2 in hearts.heart_rects():
		contained = contained and Rect2(Vector2.ZERO, hearts.size).encloses(rect)
	check(contained and hearts.heart_rects().size() == 20, "all twenty possible hearts fit inside the compact HUD")
	game.loot.add_item("medkit")
	game.loot.use_slot(0)
	game.get_node("UI/HUD").update_game(game)
	check(hearts.current == 5, "healing restores filled hearts")
	game.player.health = 0
	game.get_node("UI/HUD").update_game(game)
	check(hearts.current == 0, "fatal damage leaves no filled hearts")
	game.queue_free()
	await process_frame
	AudioServer.set_bus_volume_db(master, old_volume)
	AudioServer.set_bus_mute(master, old_mute)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	print("INTERFACE SETTINGS RESULT: %d failures" % failures)
	quit(1 if failures else 0)
