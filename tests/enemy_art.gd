extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, detail: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+detail)
	if not ok: failures += 1
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run()
	game.player.set_physics_process(false)
	game.room = 8
	game.start_room()
	game.spawn_enemy()
	var mob = game.enemies.get_child(-1)
	mob.set_physics_process(false)
	mob.jupiter_role = 1
	mob.update_visual()
	check(mob.jupiter_visual.visible and mob.jupiter_visual.animation == &"idle", "Jupiter mob uses authored idle sprite")
	mob.shot_cd = 0
	mob.tick_jupiter_mob(.01,Vector2.RIGHT)
	mob.update_visual()
	check(mob.jupiter_visual.animation == &"attack" and mob.jupiter_visual.frame == 0, "Jupiter opens during attack windup")
	mob.tick_jupiter_mob(.8,Vector2.RIGHT)
	mob.update_visual()
	check(mob.jupiter_visual.frame == 1 and game.bullets.get_child_count() > 0, "release sprite coincides with projectiles")
	mob.attack_visual_time = 0
	mob.update_visual()
	check(mob.jupiter_visual.animation == &"idle", "Jupiter returns to closed idle after firing")
	game.room = 12
	game.start_room()
	game.spawn_enemy(true)
	var boss = game.boss_ref
	boss.set_physics_process(false)
	boss.update_visual()
	check(boss.final_visual.visible and boss.final_visual.sprite_frames.get_frame_count(&"walk") == 17, "final enemy uses all seventeen authored frames")
	boss.age = 2.1
	boss._physics_process(.01)
	boss.update_visual()
	check(boss.final_dashing and absf(boss.final_visual.rotation) > .01 and boss.rotation == 0, "dash rotates visual without rotating actor or warning geometry")
	var angle: float = boss.final_rotation
	game.state = "paused"
	boss._physics_process(1)
	boss.update_visual()
	check(boss.final_rotation == angle and not boss.final_visual.is_playing(), "pause freezes final boss animation and rotation")
	game.state = "playing"
	boss.age = 0
	boss.final_spin_time = 0
	boss._physics_process(.5)
	check(is_zero_approx(boss.final_rotation), "boss settles upright between actions")
	boss.super_attack_index = 0
	boss.fire_super_attack()
	check(boss.final_spin_time > 0, "radial attack starts a short spin")
	boss.final_spin_time = 0
	boss.super_attack_index = 1
	boss.fire_super_attack()
	check(boss.final_spin_time == 0, "aimed attack retains normal pose")
	if "--preview" in OS.get_cmdline_user_args():
		var preview_mob = load("res://scenes/actors/enemy.tscn").instantiate()
		preview_mob.game = game
		preview_mob.kind = 2
		preview_mob.jupiter_role = 1
		preview_mob.position = game.player.position+Vector2(-100,0)
		game.enemies.add_child(preview_mob)
		preview_mob.set_physics_process(false)
		preview_mob.attack_visual_time = .3
		preview_mob.update_visual()
		boss.position = game.player.position+Vector2(150,0)
		boss.final_rotation = PI/4
		boss.update_visual()
		game.player.immunity = 999
		for i in 4: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tmp/final-sprite-preview.png")
	game.queue_free()
	await process_frame
	quit(failures)
