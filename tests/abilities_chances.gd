extends SceneTree
var failures := 0
func _initialize() -> void:
 call_deferred("run")
func check(ok: bool, detail: String) -> void:
 print(("PASS: " if ok else "FAIL: ") + detail)
 if not ok: failures += 1
func run() -> void:
 var P = load("res://scripts/progression.gd")
 var profile = P.new()
 profile.save_path = "res://tmp/abilities-test.cfg"
 profile.space_coins = 30
 check(profile.buy_ability(0) and profile.space_coins == 29, "magnet charges SpaceCoin")
 check(profile.buy_ability(1) and profile.space_coins == 26, "Berserk unlock charges three")
 var saved = P.new()
 saved.save_path = profile.save_path
 check(saved.load_profile() == OK and saved.abilities == profile.abilities, "skills persist")
 for i in 4: profile.buy_ability(0, false)
 check(profile.abilities.pickup == 5 and not profile.buy_ability(0, false) and not profile.buy_ability(1, false) and not profile.buy_ability(-1, false), "skill caps and invalid purchase")
 profile.save_path = "res://tmp/missing-skills-dir/profile.cfg"
 profile.abilities.pickup = 0
 var balance: int = profile.space_coins
 check(not profile.buy_ability(0) and profile.space_coins == balance and profile.abilities.pickup == 0, "failed save rolls back")
 var game = load("res://scenes/main.tscn").instantiate()
 game.smoke_mode = true
 root.add_child(game)
 game.set_physics_process(false)
 game.show_permanent_shop()
 game.panel.find_child("SkillsTab", true, false).pressed.emit()
 check(game.panel.find_child("Skills", true, false).visible, "skills tab opens")
 game.progression.space_coins = 20
 game.refresh_permanent_shop()
 game.panel.find_child("AbilityBuy1", true, false).pressed.emit()
 game.panel.find_child("AbilityBuy2", true, false).pressed.emit()
 check(game.progression.abilities.pickup == 1 and game.progression.abilities.berserk == 1, "authored ability buttons buy skills")
 if "--preview" in OS.get_cmdline_user_args():
  for frame in 4: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/preview-skills.png")
 game.start_run()
 game.player.set_physics_process(false)
 check(game.player.pickup_bonus == 40 and game.run_chances_left == 3, "skills apply and arena has three lives")
 game.loot.drops.clear()
 var origin: Vector2 = game.player.position + Vector2(100, 0)
 game.loot.drops.append({"pos": origin, "type": "coin", "value": 1, "age": 0.0})
 game.loot._physics_process(0.01)
 check(game.loot.drops[0].pos.x < origin.x, "upgraded magnet attracts coins beyond base radius")
 game.loot.drops.clear()
 origin = game.player.position + Vector2(50, 0)
 game.loot.drop_item(origin, "bomb")
 game.loot._physics_process(0.01)
 check(game.loot.drops[0].pos.x < origin.x, "magnet attracts items beyond base radius")
 game.loot.slots.assign(["bomb", "shield"])
 game.loot.drops[0].pos = origin
 game.loot._physics_process(0.01)
 check(game.loot.drops[0].pos == origin, "full inventory leaves items on ground")
 game.loot.slots.assign(["", ""])
 game.loot.drops.clear()
 check(game.activate_berserk() and not game.activate_berserk(), "Berserk activates once")
 var count: int = game.bullets.get_child_count()
 check(game.player.fire_berserk().size() == 18 and game.bullets.get_child_count() == count + 18, "Berserk fires eighteen directions")
 game.state = "paused"
 var remaining: float = game.player.berserk_time
 game.player._physics_process(1.0)
 check(game.player.berserk_time == remaining, "pause freezes Berserk duration")
 game.state = "playing"
 var timer: float = game.time_left
 game.loot.add_item("bomb")
 game.player.rewind_ready = false
 for death in 2:
  game.player.immunity = 0
  game.player.hurt(999)
  check(game.state == "death", "fatal hit opens continuation screen")
  game.panel.find_child("ContinueButton", true, false).pressed.emit()
  check(game.state == "playing" and game.run_chances_left == 2-death and game.player.health == game.player.max_health and game.player.immunity == 3, "protected respawn %d" % death)
  check(game.time_left == timer and game.loot.slots[0] == "bomb" and not game.player.rewind_ready and not game.activate_berserk(), "respawn preserves progress and used powers")
  game.player.hurt(999)
  check(game.run_chances_left == 2-death, "immunity prevents extra life loss")
 game.player.immunity = 0
 game.player.hurt(999)
 check(game.state == "ended" and game.run_chances_left == 0, "third death ends run")
 game.start_run()
 game.player.set_physics_process(false)
 check(game.activate_berserk(), "new run restores Berserk charge")
 game.start_room()
 check(game.run_chances_left == 3 and not game.activate_berserk(), "next arena preserves run lives and used Berserk")
 game.player.berserk_time = 0
 game.berserk_used = false
 game.progression.abilities.berserk = 0
 check(not game.activate_berserk(), "locked Berserk rejected")
 game.queue_free()
 await process_frame
 DirAccess.remove_absolute(ProjectSettings.globalize_path("res://tmp/abilities-test.cfg"))
 print("ABILITIES RESULT: %d failures" % failures)
 quit(1 if failures else 0)

