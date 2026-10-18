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

func frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.start_run()
	game.set_physics_process(false)
	var player = game.player
	await frames(2)
	check(player.visual.animation == &"idle" and player.visual.frame == 0, "stationary player uses original first frame")
	check(player.visual.scale == Vector2(2, 2) and not player.use_placeholder_graphics, "user animation replaces astronaut at integer 2x scale")
	Input.action_press("right")
	await frames(18)
	check(player.visual.animation == &"walk" and player.visual.frame > 0, "movement plays and advances the five-frame animation")
	Input.action_release("right")
	await frames(2)
	check(player.visual.animation == &"idle" and player.visual.frame == 0, "releasing movement returns to first frame")
	Input.action_press("right")
	await frames(8)
	game.state = "paused"
	await frames(2)
	var paused_frame: int = player.visual.frame
	await frames(20)
	check(not player.visual.is_playing() and player.visual.frame == paused_frame, "pause freezes animation")
	game.state = "playing"
	await frames(75)
	Input.action_release("right")
	player.rewind()
	await frames(2)
	check(player.echo_visual.visible and not player.rewind_ready, "rewind uses user's sprite for the echo")
	check(player.echo_visual.texture == player.visual.sprite_frames.get_frame_texture(&"walk", player.echo_frame), "echo reproduces recorded animation frames")
	game.state = "shop"
	await frames(2)
	check(not player.visual.is_playing(), "shop freezes the character animation")
	print("ANIMATION RESULT: %d failures" % failures)
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
