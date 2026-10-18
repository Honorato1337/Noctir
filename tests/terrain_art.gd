extends SceneTree
const Terrain = preload("res://scripts/planet_terrain.gd")
var failures := 0
func _initialize() -> void:
 call_deferred("run")
func check(ok: bool, detail: String) -> void:
 print(("PASS: " if ok else "FAIL: ") + detail)
 if not ok: failures += 1
func run() -> void:
 var game = load("res://scenes/main.tscn").instantiate()
 game.smoke_mode = true
 root.add_child(game)
 game.set_physics_process(false)
 game.start_run()
 game.player.set_physics_process(false)
 game.weather.set_physics_process(false)
 check(Terrain.texture() != null and Terrain.texture().get_width() == Terrain.texture().get_height(), "four-sector terrain atlas loads")
 for room_index in 13:
  game.room = room_index
  game.start_room()
  var layout = game.get_node("Arena")
  check(not layout.get_node("Border").visible, "technical border replaced by rocky wall %d" % (room_index+1))
  var valid := true
  for cover in layout.get_node("Obstacles").get_children():
   valid = valid and cover.color.a == 0 and game.blocked(cover.get_global_rect().get_center(), 13)
  check(valid, "rock formations replace boxes and retain collision %d" % (room_index+1))
  var route: PackedVector2Array = layout.route(layout.get_node("PlayerSpawn").position, layout.get_node("Portal").position)
  check(route.size() > 0, "rock arena remains traversable %d" % (room_index+1))
 if "--preview" in OS.get_cmdline_user_args():
  for sector in 4:
   game.room = sector*4
   game.start_room()
   game.player.position = Vector2(620, 325)
   game.configure_camera()
   for i in 6:
    game.spawn_enemy()
    var enemy = game.enemies.get_child(-1)
    enemy.set_physics_process(false)
    enemy.position = Vector2(740+i%3*80, 340+i/3*100)
   game.message_time = 0
   for frame in 4: await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://docs/preview-terrain-%d.png" % sector)
 game.queue_free()
 await process_frame
 print("TERRAIN ART RESULT: %d failures" % failures)
 quit(1 if failures else 0)
