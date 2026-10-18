extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, detail: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+detail)
	if not ok: failures += 1
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	check(not game.developer_unlocked and not game.panel.find_child("TestButton",true,false).visible, "player menu hides tests by default")
	game.show_test_menu()
	check(game.state == "menu", "locked developer cannot enter test menu")
	game.start_run(true)
	check(not game.run_active, "locked developer cannot start practice directly")
	game.show_settings()
	game.panel.find_child("Tabs",true,false).current_tab = 3
	var password: LineEdit = game.panel.find_child("DeveloperPassword",true,false)
	check(password.secret and password.visible and not game.panel.find_child("DeveloperTestsButton",true,false).visible, "developer tab masks password and hides test access")
	password.text = "wrong password"
	game.panel.find_child("UnlockDeveloperButton",true,false).pressed.emit()
	check(not game.developer_unlocked and password.text.is_empty() and game.panel.find_child("DeveloperNotice",true,false).text == "Senha incorreta.", "wrong password is rejected and cleared")
	if "--preview" in OS.get_cmdline_user_args():
		game.panel.find_child("DeveloperNotice",true,false).text = "Área restrita ao desenvolvedor. Digite a senha para acessar os testes."
		for i in 4: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/preview-developer-settings.png")
	var supplied := OS.get_environment("OMO_DEV_TEST_PASSWORD")
	if supplied.is_empty():
		check(false,"valid-password test requires OMO_DEV_TEST_PASSWORD")
	else:
		password.text = supplied
		password.text_submitted.emit(password.text)
		check(game.developer_unlocked and password.text.is_empty() and not password.visible, "correct password unlocks via Enter without retaining password")
		check(game.panel.find_child("DeveloperTestsButton",true,false).visible, "unlocked developer can open arenas from settings")
		game.show_menu()
		check(game.panel.find_child("TestButton",true,false).visible, "test shortcut is visible only after session unlock")
		game.panel.find_child("TestButton",true,false).pressed.emit()
		check(game.state == "testing", "unlocked developer opens test menu")
		game.panel.find_child("TestArena1",true,false).pressed.emit()
		check(game.practice_mode and game.state == "playing", "unlocked developer can run authored arena tests")
		game.show_menu()
		game.show_settings()
		game.panel.find_child("LockDeveloperButton",true,false).pressed.emit()
		check(not game.developer_unlocked, "developer can lock access again")
		game.show_menu()
		check(not game.panel.find_child("TestButton",true,false).visible, "locking hides menu shortcut again")
		game.start_run()
		check(game.state == "playing" and not game.practice_mode, "normal expedition remains available while developer locked")
	var fresh = load("res://scenes/main.tscn").instantiate()
	fresh.smoke_mode = true
	root.add_child(fresh)
	check(not fresh.developer_unlocked, "new game session starts locked")
	fresh.queue_free()
	game.queue_free()
	await process_frame
	quit(failures)
