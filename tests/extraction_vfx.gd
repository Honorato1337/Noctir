extends SceneTree
const Vfx = preload("res://scripts/pixel_effects.gd")
const Vehicles = preload("res://scripts/expedition_vehicles.gd")
var failures := 0
func _initialize() -> void:
 call_deferred("run")
func check(ok: bool, detail: String) -> void:
 print(("PASS: " if ok else "FAIL: ") + detail)
 if not ok: failures += 1
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
 game.start_run()
 game.player.set_physics_process(false)
 game.weather.set_physics_process(false)
 game.fx.set_process(false)
 check(Vfx.texture() != null and Vehicles.texture("rover") != null and Vehicles.texture("ship") != null, "particle atlas, rover and ship are imported")
 check(Vfx.region(0,0) != Vfx.region(0,3) and Vfx.region(1,0) != Vfx.region(2,0), "particle families and animation frames have separate regions")
 for kind in 4:
  game.fx.sparks(game.player.position+Vector2(kind*35,0), Color.WHITE, 8, 40, kind)
 check(game.fx.particles.size() == 32 and game.fx.particles[24].kind == 3, "particles carry sprite family and lifetime animation")
 game.fx.queue_redraw()
 await capture("particle-effects")
 game.fx.particles.clear()
 game.state = "exit"
 game.player.position = game.portal - Vector2(160,0)
 game.configure_camera()
 game.get_node("UI/HUD").update_game(game)
 game.get_node("ExtractionRover")._process(0)
 check(game.get_node("ExtractionRover").visible and not game.start_transfer(), "rover is visible but boarding requires proximity")
 check(game.get_node("UI/HUD/Extract").visible and game.get_node("UI/HUD").find_child("ExtractHint").text.contains("SIGA"), "extraction card directs distant player to rover")
 game.player.position = game.portal - Vector2(80,0)
 game.controls.last_device = "joypad"
 game.get_node("UI/HUD").update_game(game)
 check(game.get_node("UI/HUD").find_child("ExtractHint").text.contains("[X]"), "boarding hint adapts to controller")
 game.controls.last_device = "keyboard"
 game.get_node("UI/HUD").update_game(game)
 await capture("rover-extraction")
 game.run_chances_left = 1
 game.berserk_used = true
 game.loot.slots[0] = "bomb"
 var score: int = game.score
 check(game.start_transfer() and not game.start_transfer(), "boarding launches exactly one ship transition")
 var time: float = game.time_left
 game._physics_process(game.TRAVEL_DURATION*0.5)
 check(game.state == "travel" and game.time_left == time and game.room == 0, "ship animation freezes combat until arrival")
 await capture("orbital-ship")
 game._physics_process(game.TRAVEL_DURATION)
 check(game.state == "playing" and game.room == 1 and game.run_chances_left == 1 and game.berserk_used and game.loot.slots[0] == "bomb" and game.score == score, "arrival preserves run chances, used powers, inventory and score")
 game.room = game.total_rooms()-1
 game.start_room()
 game.state = "exit"
 game.player.position = game.portal
 game.start_transfer()
 game._physics_process(game.TRAVEL_DURATION)
 check(game.state == "ended" and not game.run_active, "final ship evacuation completes expedition")
 game.start_run()
 game.player.set_physics_process(false)
 game.state = "exit"
 game.player.position = game.portal
 game.start_transfer()
 game.show_menu()
 game._physics_process(10)
 check(game.state == "menu" and game.room == 0, "leaving interrupted travel cannot advance a later run")
 game.queue_free()
 await process_frame
 print("EXTRACTION VFX RESULT: %d failures" % failures)
 quit(1 if failures else 0)
