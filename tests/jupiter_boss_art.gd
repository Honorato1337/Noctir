extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
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
 for room in [8, 11]:
  game.room = room
  game.start_room()
  game.begin_boss()
  var boss = game.boss_ref
  boss.set_physics_process(false)
  boss.update_visual()
  var sprite = boss.jupiter_super_visual if room == 11 else boss.jupiter_boss_visual
  var other = boss.jupiter_boss_visual if room == 11 else boss.jupiter_super_visual
  check(sprite.visible and not other.visible and not boss.jupiter_visual.visible and not boss.final_visual.visible, "correct Jupiter boss artwork in arena " + str(room+1))
  check(sprite.sprite_frames.get_frame_count(&"walk") == 21, "all twenty-one supplied frames load")
  var expected := "mob_jupiter3" if room == 11 else "mob_jupiter2"
  check(sprite.sprite_frames.get_frame_texture(&"walk",0).resource_path.contains(expected), "resource uses supplied " + expected)
  boss.age = .5
  boss.update_visual()
  check(sprite.frame == 6 and sprite.position.y < 0, "artwork animates and floats")
  boss.age = 2.9
  boss.update_visual()
  check(absf(sprite.rotation) > .1, "charge or core orbit rotates artwork")
  var before: Transform2D = sprite.transform
  var frame: int = sprite.frame
  game.state = "paused"
  boss._physics_process(.5)
  boss.update_visual()
  check(sprite.transform == before and sprite.frame == frame, "pause freezes the full animation")
  check(boss.shield > 0 and boss.radius == (40 if room == 11 else 32), "shield and collision remain unchanged")
  game.state = "playing"
 game.room = 12
 game.start_room()
 game.begin_boss()
 game.boss_ref.update_visual()
 check(game.boss_ref.final_visual.visible and not game.boss_ref.jupiter_super_visual.visible and not game.boss_ref.jupiter_boss_visual.visible, "final boss keeps its own artwork")
 game.queue_free()
 await process_frame
 quit(failures)

