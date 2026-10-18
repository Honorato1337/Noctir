extends SceneTree
var failures := 0
func _initialize() -> void:
 call_deferred("run")
func check(ok: bool, detail: String) -> void:
 print(("PASS: " if ok else "FAIL: ") + detail)
 if not ok: failures += 1
func key(code: int, pressed: bool) -> void:
 var event := InputEventKey.new()
 event.physical_keycode = code
 event.keycode = code
 event.pressed = pressed
 Input.parse_input_event(event)
 Input.flush_buffered_events()
func axis(which: int, value: float) -> void:
 var event := InputEventJoypadMotion.new()
 event.device = 0
 event.axis = which
 event.axis_value = value
 Input.parse_input_event(event)
 Input.flush_buffered_events()
func button(which: int, pressed: bool) -> void:
 var event := InputEventJoypadButton.new()
 event.device = 0
 event.button_index = which
 event.pressed = pressed
 Input.parse_input_event(event)
 Input.flush_buffered_events()
func touch(index: int, at: Vector2, pressed: bool) -> void:
 var event := InputEventScreenTouch.new()
 event.index = index
 event.position = at
 event.pressed = pressed
 Input.parse_input_event(event)
 Input.flush_buffered_events()
func capture(name: String) -> void:
 if "--preview" not in OS.get_cmdline_user_args(): return
 for frame in 4: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/preview-"+name+".png")
func run() -> void:
 var game = load("res://scenes/main.tscn").instantiate()
 game.smoke_mode = true
 root.add_child(game)
 game.set_physics_process(false)
 game.show_settings()
 game.panel.find_child("MusicSlider", true, false).value = 24
 game.panel.find_child("SfxSlider", true, false).value = 61
 game.panel.find_child("UiSlider", true, false).value = 43
 check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))), 0.24) and is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))),0.61), "music and effects buses have independent sliders")
 check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("UI"))),0.43) and game.get_node("MenuMusic").bus == &"Music" and game.get_node("PlanetMusic").bus == &"Music", "interface and music route to separate buses")
 game.get_node("GameAudio").enabled = true
 game.play_sfx("ui_click")
 game.play_sfx("dash")
 var has_ui := false
 var has_sfx := false
 for voice in game.get_node("GameAudio").voices:
  has_ui = has_ui or (voice.stream != null and voice.bus == &"UI")
  has_sfx = has_sfx or (voice.stream != null and voice.bus == &"SFX")
 check(has_ui and has_sfx, "actual UI and combat sounds use their assigned buses")
 game.get_node("GameAudio").enabled = false
 await capture("settings-audio")
 game.panel.find_child("Tabs", true, false).current_tab = 1
 await capture("settings-video")
 game.panel.find_child("Tabs", true, false).current_tab = 2
 game.panel.find_child("KeyboardPreset", true, false).select(1)
 game.panel.find_child("KeyboardPreset", true, false).item_selected.emit(1)
 check(game.controls.key_for("up") == KEY_UP and game.controls.key_for("aim_up") == KEY_W, "arrow preset swaps movement and directional shooting")
 game.panel.find_child("Bind_dash", true, false).pressed.emit()
 key(KEY_J, true)
 key(KEY_J, false)
 check(game.controls.key_for("dash") == KEY_J and game.remap_action.is_empty(), "remap captures an actual physical key")
 game.begin_rebind("left")
 key(KEY_UP, true)
 key(KEY_UP, false)
 check(game.controls.key_for("left") == KEY_UP and game.controls.key_for("up") == KEY_LEFT, "duplicate key swaps the previous binding")
 game.begin_rebind("dash")
 key(KEY_ESCAPE, true)
 key(KEY_ESCAPE, false)
 check(game.controls.key_for("dash") == KEY_J and game.state == "settings" and game.remap_action.is_empty(), "Escape cancels remapping without leaving settings")
 await capture("settings-controls")
 var settings = game.preferences
 settings.save_path = "res://tmp/platform-settings.cfg"
 settings.resolution_index = 3
 settings.touch_mode = 1
 settings.save_settings()
 var saved = load("res://scripts/user_settings.gd").new()
 saved.save_path = settings.save_path
 check(saved.load_settings() == OK and saved.music_volume == 24 and saved.sfx_volume == 61 and saved.ui_volume == 43 and saved.keyboard_preset == 1 and saved.keybinds.dash == KEY_J and saved.resolution_index == 3 and saved.touch_mode == 1, "volumes, video, preset, custom keys and touch mode persist")
 game.set_keyboard_preset(0)
 game.set_touch_mode(2)
 game.show_menu()
 var focused = game.panel.find_child("StartButton", true, false)
 focused.grab_focus()
 await process_frame
 button(JOY_BUTTON_A, true)
 await process_frame
 button(JOY_BUTTON_A, false)
 await process_frame
 check(game.state == "difficulty", "controller A navigates authored menu buttons")
 if game.preferences.desktop_video_available():
  game.set_resolution(0)
  for frame in 3: await process_frame
  check(DisplayServer.window_get_size() == Vector2i(960,600), "desktop resolution changes the actual window")
  game.set_resolution(1)
  for frame in 3: await process_frame
  check(DisplayServer.window_get_size() == Vector2i(1152,720), "desktop resolution can be restored")
 game.start_run()
 game.player.set_physics_process(false)
 game.player.immunity = 1000
 var before: Vector2 = game.player.position
 axis(JOY_AXIS_LEFT_X, 1)
 game.player._physics_process(0.1)
 check(game.player.position.x > before.x and game.controls.last_device == "joypad", "left stick moves player")
 axis(JOY_AXIS_LEFT_X, 0)
 axis(JOY_AXIS_RIGHT_Y, -0.6)
 game.player.cooldown = 0
 game.player._physics_process(0.1)
 check(game.bullets.get_child_count() > 0 and game.player.aim.is_equal_approx(Vector2.UP), "right stick aims and fires normalized shots")
 axis(JOY_AXIS_RIGHT_Y, 0)
 axis(JOY_AXIS_LEFT_X, 0.1)
 check(game.controls.movement() == Vector2.ZERO, "stick deadzone rejects drift")
 axis(JOY_AXIS_LEFT_X, 0)
 button(JOY_BUTTON_A, true)
 game.player.dash_cd = 0
 game.player._physics_process(0.01)
 button(JOY_BUTTON_A, false)
 check(game.player.dash_cd > 0, "controller A activates dash")
 game.on_joy_connection_changed(0, false)
 check(game.state == "paused", "controller disconnect pauses active run")
 game.panel.find_child("ResumeButton", true, false).pressed.emit()
 game.preferences.touch_mode = 1
 game.touch_controls._process(0)
 game.player.dash_time = 0
 game.player.dash_cd = 0
 before = game.player.position
 var left: Vector2 = game.touch_controls.left_center()
 var right: Vector2 = game.touch_controls.right_center()
 touch(1, left+Vector2(55,0), true)
 touch(2, right+Vector2(0,-55), true)
 game.player.cooldown = 0
 var shots: int = game.bullets.get_child_count()
 game.player._physics_process(0.1)
 check(game.player.position.x > before.x and game.bullets.get_child_count() > shots and game.player.aim.is_equal_approx(Vector2.UP), "two simultaneous touches move and shoot independently")
 touch(1, left, false)
 touch(2, right, false)
 check(game.controls.touch_move == Vector2.ZERO and game.controls.touch_aim == Vector2.ZERO, "releasing fingers stops sticks")
 var dash_at: Vector2 = game.touch_controls.buttons().dash
 touch(3, dash_at, true)
 game.player._physics_process(0.01)
 touch(3, dash_at, false)
 check(game.player.dash_cd > 0, "touch dash button activates dash")
 game.get_node("UI/HUD").update_game(game)
 check(not game.get_node("UI/HUD/MiniTutorial").visible and not game.get_node("UI/HUD/DashCard").visible and game.get_node("UI/HUD/SlotThree").position.y == 100, "mobile HUD avoids covering touch controls")
 await capture("touch-controls")
 touch(4, game.touch_controls.buttons().pause, true)
 game._physics_process(0.01)
 game.touch_controls._process(0)
 check(game.state == "paused" and game.touch_controls.fingers.is_empty(), "touch pause opens menu and clears held actions")
 for frame in 3: await process_frame
 var resume_point: Vector2 = game.panel.find_child("ResumeButton", true, false).get_global_rect().get_center()
 touch(0, resume_point, true)
 await process_frame
 touch(0, resume_point, false)
 await process_frame
 check(game.state == "playing", "touch can activate GUI resume button")
 game.queue_free()
 await process_frame
 DirAccess.remove_absolute(ProjectSettings.globalize_path("res://tmp/platform-settings.cfg"))
 print("PLATFORM CONTROLS RESULT: %d failures" % failures)
 quit(1 if failures else 0)
