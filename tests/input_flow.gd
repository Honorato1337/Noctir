extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, detail: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + detail)
	if not ok:
		failures += 1

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	await process_frame
	await process_frame
	var start: Button = game.panel.find_child("StartButton", true, false)
	var point := start.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)
	Input.flush_buffered_events()
	await process_frame
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.position = point
		click.global_position = point
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		Input.parse_input_event(click)
		Input.flush_buffered_events()
		await process_frame
	check(game.state == "difficulty", "mouse click on start opens difficulty selection")
	if game.state != "difficulty":
		game.queue_free()
		quit(1)
		return
	point = game.panel.find_child("MediumButton", true, false).get_global_rect().get_center()
	motion = InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)
	Input.flush_buffered_events()
	await process_frame
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.position = point
		click.global_position = point
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		Input.parse_input_event(click)
		Input.flush_buffered_events()
		await process_frame
	check(game.state == "playing" and is_instance_valid(game.player), "difficulty selection enters gameplay")
	if game.state != "playing":
		game.queue_free()
		quit(1)
		return
	var before: Vector2 = game.player.position
	key(KEY_D, true)
	for frame in 12:
		await physics_frame
	key(KEY_D, false)
	check(game.player.position.x > before.x + 20, "physical D key moves player during actual physics frames")
	before = game.player.position
	key(KEY_W, true)
	for frame in 12:
		await physics_frame
	key(KEY_W, false)
	check(game.player.position.y < before.y - 20, "physical W key moves player upward")
	key(KEY_ESCAPE, true)
	await physics_frame
	await process_frame
	key(KEY_ESCAPE, false)
	check(game.state == "paused", "physical Escape pauses gameplay")
	key(KEY_ESCAPE, true)
	await physics_frame
	await process_frame
	key(KEY_ESCAPE, false)
	check(game.state == "playing", "physical Escape resumes without immediately pausing again")
	if game.state == "paused":
		game.panel.find_child("ResumeButton", true, false).pressed.emit()
	before = game.player.position
	key(KEY_A, true)
	for frame in 12:
		await physics_frame
	key(KEY_A, false)
	check(game.state == "playing" and game.player.position.x < before.x - 20, "movement remains active after resume")
	game.queue_free()
	await process_frame
	print("INPUT FLOW RESULT: %d failures" % failures)
	quit(1 if failures else 0)
