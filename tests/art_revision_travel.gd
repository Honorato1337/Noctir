extends SceneTree
const Vehicles = preload("res://scripts/expedition_vehicles.gd")
const Terrain = preload("res://scripts/planet_terrain.gd")
const Vfx = preload("res://scripts/pixel_effects.gd")
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
 check(Terrain.texture().get_size() == Vector2(128,128) and Vfx.texture().get_size() == Vector2(64,64), "terrain uses native 32px tiles and effects use 16px frames")
 for kind: String in ["rover","rocket"]:
  var image: Image = Vehicles.texture(kind).get_image()
  var colors := {}
  for y in image.get_height():
   for x in image.get_width():
    var pixel := image.get_pixel(x,y)
    if pixel.a > 0: colors[pixel.to_html()] = true
  check(image.get_size() == Vector2i(64,32) and colors.size() <= 8, "two native 32px frames and original short palette: "+kind)
  var frame0 := image.get_region(Rect2i(Vehicles.region(kind,0)))
  var frame1 := image.get_region(Rect2i(Vehicles.region(kind,1)))
  check(frame0.get_data() != frame1.get_data(), "vehicle animation has visibly different frames: "+kind)
 for room_index in 13:
  game.room = room_index
  game.start_room()
  var expected := "rocket" if room_index in [3,7,11,12] else "rover"
  check(game.extraction_vehicle() == expected, "correct vehicle for arena %d" % (room_index+1))
  game.state = "exit"
  game.player.position = game.portal
  game.run_chances_left = 1
  game.berserk_used = true
  check(game.start_transfer() and game.travel_kind == expected, "boarding launches correct animation %d" % (room_index+1))
  game._physics_process(game.TRAVEL_DURATION*0.5)
  if room_index in [0,3]: await capture("revised-rover-travel" if room_index == 0 else "revised-rocket-travel")
  game._physics_process(game.TRAVEL_DURATION)
  check(game.run_chances_left == 1 and game.berserk_used and game.state == ("ended" if room_index == 12 else "playing"), "travel preserves run state %d" % (room_index+1))
  if room_index == 12: game.start_run()
 game.room = 4
 game.start_room()
 game.spawn_enemy()
 var neptune = game.enemies.get_child(-1)
 neptune.update_visual()
 check(neptune.get_node("NeptuneVisual").visible and neptune.get_node("NeptuneVisual").sprite_frames.get_frame_count(&"walk") == 3, "supplied Neptune mob animation replaces generic art")
 game.room = 3
 game.start_room()
 game.state = "exit"
 game.player.position = game.portal
 game.preferences.touch_mode = 1
 game.get_node("UI/HUD").update_game(game)
 check(game.get_node("UI/HUD").find_child("ExtractHeader").text.contains("FOGUETE") and game.get_node("UI/HUD").find_child("ExtractHint").text.contains("TOQUE EM IR"), "mobile boarding hint matches the rocket action button")
 game.queue_free()
 await process_frame
 print("ART REVISION RESULT: %d failures" % failures)
 quit(1 if failures else 0)
