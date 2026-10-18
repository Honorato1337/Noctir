extends SceneTree
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
 game.encounters.set_physics_process(false)
 game.loot.set_physics_process(false)
 game.pending = 0
 game.boss_spawned = true
 game.spawn_enemy(true)
 game.spawn_enemy()
 var boss = game.boss_ref
 for enemy in game.enemies.get_children(): enemy.set_physics_process(false)
 game.weather.start_event()
 game.weather.age = game.weather.warning
 game.encounters.add_field("blast",game.player.position,80,1,2,boss)
 game.shoot(game.player.position,Vector2.RIGHT,1,true)
 game.fx.explosion(game.player.position,Color.WHITE,50)
 game.hazards.append(game.player.position)
 game.player.dash_time = 0.2
 game.deployables.place()
 for enemy in game.enemies.get_children(): enemy.hurt(100000)
 await process_frame
 var loot_count: int = game.loot.drops.size()
 game._physics_process(0.01)
 check(game.state == "cleared" and game.room_cleared, "last enemy death opens safe collection instead of shop")
 check(not game.weather.active and game.weather.vortices.is_empty() and game.weather.strikes.is_empty() and game.encounters.fields.is_empty() and game.hazards.is_empty(), "all tornadoes and environmental hazards are cleared")
 check(game.fx.particles.is_empty() and game.fx.labels.is_empty() and game.effects.is_empty() and game.bullets.get_child_count() == 0 and game.deployables.placed.is_empty() and game.player.dash_time == 0, "combat particles, projectiles and deployed effects are cleared")
 check(game.loot.drops.size() == loot_count and loot_count > 0, "victory preserves enemy drops on ground")
 var score: int = game.score
 var time: float = game.time_left
 game._physics_process(10)
 game.weather._physics_process(10)
 check(game.state == "cleared" and game.time_left == time and game.score == score and not game.weather.active and game.collection_left == 5.0, "collection countdown advances while combat timer and hazards stay frozen")
 game.pause_run()
 game.panel.find_child("ResumeButton",true,false).pressed.emit()
 check(game.state == "cleared", "pause returns to collection without skipping shop")
 check(not game.board_after_clear(), "boarding is rejected far from extraction")
 game.loot.drops.clear()
 game.loot.drops.append({"pos":game.player.position+Vector2(120,0),"type":"coin","value":7,"age":13.9})
 game.loot._physics_process(30)
 check(game.loot.drops.size() == 1 and game.loot.drops[0].age == 13.9, "coins stop expiring after victory")
 game.player.position = game.loot.drops[0].pos
 game.loot._physics_process(0.01)
 check(game.loot.drops.is_empty() and game.loot.coins >= 7, "player can collect coins during safe phase")
 game.loot.slots.assign(["bomb","shield"])
 game.loot.drop_item(game.player.position+Vector2(12,0),"overdrive")
 game.loot._physics_process(0.01)
 check(game.loot.drops.size() == 1 and game.loot.slots[1] == "shield", "full slots preserve ground item")
 check(game.loot.swap_nearby(1) and game.loot.slots[1] == "overdrive" and game.loot.drops[0].type == "shield", "safe swap exchanges item without destroying previous one")
 game.loot.drops.clear()
 game.deployables.inventory = "mine"
 game.loot.drop_item(game.player.position+Vector2(12,0),"turret")
 check(game.loot.swap_device_nearby() and game.deployables.inventory == "turret" and game.loot.drops[0].type == "mine", "safe swap exchanges ground equipment")
 game.get_node("UI/HUD").update_game(game)
 check(game.get_node("UI/HUD/Cleanup").visible, "safe collection shows manual shop button")
 await capture("safe-collection")
 game.player.position = game.portal
 game.get_node("UI/HUD").update_game(game)
 game.get_node("UI/HUD/Cleanup/Box/CleanupShopButton").pressed.emit()
 check(game.state == "shop", "player chooses when to enter shop")
 game.leave_shop()
 check(game.state == "travel", "leaving the onboard shop starts travel directly")
 game.close_panel()
 game.state = "exit"
 game.player.position = game.portal-Vector2(90,0)
 game.configure_camera()
 await capture("larger-rover")
 game.room = 3
 game.start_room()
 game.state = "exit"
 game.player.position = game.portal-Vector2(90,0)
 game.configure_camera()
 await capture("larger-rocket")
 game.start_room()
 game.pending = 0
 game.boss_spawned = true
 game.clear_container(game.enemies)
 game.finish_arena()
 game.pause_run()
 var remaining: float = game.collection_left
 game._physics_process(40)
 check(game.collection_left == remaining and game.state == "paused", "pausing suspends collection deadline")
 game.panel.find_child("ResumeButton",true,false).pressed.emit()
 game._physics_process(16)
 check(game.state == "shop" and game.extraction_boarded, "timeout safely boards player and preserves shop")
 game.leave_shop()
 check(game.state == "travel" and game.player.position == game.portal, "automatic extraction follows normal travel path")
 game.queue_free()
 await process_frame
 print("SAFE COLLECTION RESULT: %d failures" % failures)
 quit(1 if failures else 0)
