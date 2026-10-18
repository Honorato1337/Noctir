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
 game.panel.find_child("StartButton", true, false).pressed.emit()
 check(game.state == "difficulty" and game.panel.name == "DifficultyMenu" and not game.run_active, "start opens difficulty menu without launching run")
 if "--preview" in OS.get_cmdline_user_args():
  for frame in 4: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/preview-difficulty.png")
 game.panel.find_child("BackButton", true, false).pressed.emit()
 check(game.state == "menu", "difficulty back returns to menu")
 var waves: Array[int] = []
 var hp: Array[float] = []
 var speeds: Array[float] = []
 var times: Array[float] = []
 var bullets: Array[float] = []
 for mode: String in ["easy", "medium", "hard"]:
  game.show_difficulty_menu()
  game.panel.find_child(mode.capitalize()+"Button", true, false).pressed.emit()
  game.player.set_physics_process(false)
  check(game.state == "playing" and game.run_difficulty == mode and game.run_chances_left == 3, "mode starts with three arena lives: "+mode)
  waves.append(game.wave_total)
  times.append(game.time_left)
  game.spawn_enemy()
  var enemy = game.enemies.get_child(-1)
  enemy.set_physics_process(false)
  hp.append(enemy.health)
  speeds.append(enemy.speed)
  game.shoot(game.player.position, Vector2.RIGHT, 1, true)
  bullets.append(game.bullets.get_child(-1).velocity.length())
  if mode == "easy":
   check(not game.contracts.enabled and game.contracts.kind.is_empty(), "easy has no contract")
   game.contracts.enabled = true
   game.contracts.kind = "bosses"
   game.contracts.target = 1
   game.contracts.record("boss")
   check(game.run_space_reward == 0 and game.contracts.progress == 0, "easy cannot earn SpaceCoin even if contract enabled")
  game.score = 10000
  var before: int = game.progression.coins
  game.finish(false, "Difficulty test")
  var expected: int = {"easy":25,"medium":100,"hard":150}[mode]
  check(game.run_reward == expected and game.progression.coins == before+expected, "permanent Coins multiplier: "+mode)
  game.settle_run()
  check(game.progression.coins == before+expected, "settlement cannot pay twice")
  game.restart_current_run()
  check(game.run_difficulty == mode, "restart preserves mode: "+mode)
  game.score = 0
 check(waves[0] < waves[1] and waves[1] < waves[2], "higher modes increase wave sizes")
 check(hp[0] < hp[1] and hp[1] < hp[2] and speeds[0] < speeds[1] and speeds[1] < speeds[2], "higher modes increase enemy health and speed")
 check(times[0] > times[1] and times[1] > times[2] and bullets[0] < bullets[1] and bullets[1] < bullets[2], "higher modes tighten time and speed up hostile bullets")
 game.start_run(false, 0, "hard")
 game.score = 10000
 var previous: int = game.progression.coins
 game.start_run(false, 0, "easy")
 check(game.progression.coins == previous+150, "switching modes settles previous run with its original multiplier")
 game.start_run(true, 0, "hard")
 check(game.run_difficulty == "medium" and not game.contracts.enabled, "practice uses baseline difficulty and no contracts")
 game.score = 10000
 game.settle_run()
 check(game.run_reward == 0, "practice has no reward")
 game.queue_free()
 await process_frame
 print("DIFFICULTY RESULT: %d failures" % failures)
 quit(1 if failures else 0)
