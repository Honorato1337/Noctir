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
 game.set_process(false)
 game.start_run()
 var player = game.player
 player.set_physics_process(false)
 player.shotgun_owned = true
 player.equip_weapon("shotgun")
 var limit: int = game.projectile_limit(false)
 for mode in ["original", "shotgun", "berserk"]:
  game.clear_container(game.bullets)
  player.equip_weapon("original" if mode == "original" else "shotgun")
  for i in limit - 1:
   var bullet = game.shoot(player.position, Vector2.RIGHT, 1, false)
   bullet.set_physics_process(false)
  var shots: Array[Vector2] = player.fire_berserk() if mode == "berserk" else player.fire(player.position, Vector2.RIGHT, false)
  check(shots.size() == 1 and game.bullets.get_child_count() == limit, mode + " records only accepted shots at a partial cap")
  shots = player.fire_berserk() if mode == "berserk" else player.fire(player.position, Vector2.RIGHT, false)
  check(shots.is_empty(), mode + " records no shots at the full cap")
 player.history.clear()
 player.cooldown = 0
 game.controls.touch_aim = Vector2.RIGHT
 player._physics_process(1.0/60)
 check(player.history[-1].shots.is_empty(), "history excludes a rejected volley")
 game.controls.touch_aim = Vector2.ZERO
 game.controls.last_device = "joypad"
 for i in 60: player._physics_process(1.0/60)
 game.clear_container(game.bullets)
 player.rewind()
 player._physics_process(1.0/60)
 check(game.bullets.get_child_count() == 0, "Echo cannot recreate rejected shots")
 player.echo_frames.clear()
 check(player.fire(player.position, Vector2.RIGHT, false).size() == 3, "uncapped shotgun retains three pellets")
 check(player.fire_berserk().size() == 18, "uncapped Berserk retains eighteen directions")
 game.queue_free()
 await process_frame
 quit(failures)
