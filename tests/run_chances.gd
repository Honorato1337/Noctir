extends SceneTree
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
 game.start_run(false, 0, "hard")
 game.player.set_physics_process(false)
 game.player.immunity = 0
 game.player.hurt(999)
 check(game.state == "death" and game.run_chances_left == 2 and game.player.health <= 0, "first death waits for player choice with two run lives")
 if "--preview" in OS.get_cmdline_user_args():
  for frame in 4: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/preview-death.png")
 var timer: float = game.time_left
 var pending: int = game.pending
 var position: Vector2 = game.player.position
 game._physics_process(5)
 game.player._physics_process(5)
 game.loot._physics_process(5)
 game.deployables._physics_process(5)
 game.encounters._physics_process(5)
 Input.action_press("pause")
 game._physics_process(0.01)
 Input.action_release("pause")
 check(game.state == "death" and game.time_left == timer and game.pending == pending and game.player.position == position, "death screen freezes combat and Escape cannot bypass it")
 game.player.hurt(999)
 game.handle_player_death()
 check(game.run_chances_left == 2, "duplicate damage cannot consume another life on death screen")
 game.panel.find_child("ContinueButton", true, false).pressed.emit()
 check(game.state == "playing" and game.player.health == game.player.max_health and game.player.immunity == 3 and game.run_chances_left == 2, "continue restores health and protects without restoring run lives")
 game.continue_after_death()
 check(game.run_chances_left == 2, "continue callback cannot run twice")
 game.room = 4
 game.start_room()
 check(game.run_chances_left == 2, "changing planet does not replenish chances")
 game.player.immunity = 0
 game.player.hurt(999)
 check(game.state == "death" and game.run_chances_left == 1, "second death opens choice with last run life")
 game.panel.find_child("ContinueButton", true, false).pressed.emit()
 game.room = 8
 game.start_room()
 check(game.run_chances_left == 1, "another planet retains last run life")
 game.player.immunity = 0
 game.player.hurt(999)
 check(game.state == "ended" and game.run_chances_left == 0 and game.panel.name != "DeathMenu", "third death ends run without another continue")
 game.restart_current_run()
 game.player.set_physics_process(false)
 check(game.run_chances_left == 3 and game.run_difficulty == "hard", "new run restores three lives and keeps difficulty")
 game.score = 10000
 var balance: int = game.progression.coins
 game.player.immunity = 0
 game.player.hurt(999)
 game.panel.find_child("MenuButton", true, false).pressed.emit()
 check(game.state == "menu" and not game.run_active and game.progression.coins == balance+150, "return from death ends run and settles hard-mode Coins once")
 game.show_menu()
 check(game.progression.coins == balance+150, "return cannot award twice")
 game.queue_free()
 await process_frame
 print("RUN CHANCES RESULT: %d failures" % failures)
 quit(1 if failures else 0)
