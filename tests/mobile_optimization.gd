extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, detail: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+detail)
	if not ok: failures += 1
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	game.mobile_profile_override = true
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run()
	game.player.set_physics_process(false)
	check(game.wave_total == 24 and game.mob_limit() == 24,"mobile reduces opening wave by 35 percent and caps active mobs at 24")
	check(root.content_scale_mode == Window.CONTENT_SCALE_MODE_VIEWPORT,"mobile renders at internal viewport resolution")
	for i in 50: game.fx.sparks(game.player.position,Color.WHITE,120)
	check(game.fx.particles.size() > 0 and game.fx.particles.size() <= 16,"mobile per-frame emission budget bounds simultaneous effects")
	check(game.weather.motes.size() == 20,"ambient motes reduced to twenty")
	for i in 50: game.weather.add_strike("meteor",game.player.position)
	check(game.weather.strikes.size() == 18,"weather keeps at most eighteen warned impacts")
	game.clear_container(game.bullets)
	for i in 250: game.shoot(game.player.position,Vector2.RIGHT,1,true)
	check(game.bullets.get_child_count() == 120,"hostile projectile budget enforced")
	for i in 100: game.shoot(game.player.position,Vector2.RIGHT,1,false)
	check(game.bullets.get_child_count() == 160,"friendly shots retain forty reserved slots")
	game.room = 12
	game.start_room()
	for i in 50: game._physics_process(.2)
	check(game.enemies.get_child_count() <= 24,"campaign spawner respects mobile actor budget under pressure")
	game.clear_container(game.enemies)
	game.spawn_enemy(true)
	var boss = game.boss_ref
	boss.set_physics_process(false)
	check(boss.final_visual.scale == Vector2(4,4) and boss.radius == 88,"final boss doubles both artwork and collision radius")
	check(not game.get_node("Arena").route(boss.position,game.player.position,88).is_empty(),"enlarged final boss has a navigable route")
	game.room = 8
	game.start_room()
	game.spawn_enemy()
	var mob = game.enemies.get_child(-1)
	mob.set_physics_process(false)
	check(mob.jupiter_visual.scale == Vector2(1.5,1.5) and mob.radius == 21,"Jupiter mob grows by fifty percent with matching collision")
	for kind in [0,1]:
		mob.kind = kind
		mob.age = 0
		mob.update_visual()
		var before: Vector2 = mob.mars_visual.scale if kind == 0 else mob.neptune_visual.position
		mob.age = .2
		mob.update_visual()
		check((mob.mars_visual.scale if kind == 0 else mob.neptune_visual.position) != before,"existing sprite gains procedural motion for kind "+str(kind))
		game.state = "paused"
		var frozen: Vector2 = mob.mars_visual.scale if kind == 0 else mob.neptune_visual.position
		mob._physics_process(.3)
		mob.update_visual()
		check((mob.mars_visual.scale if kind == 0 else mob.neptune_visual.position) == frozen,"pause freezes procedural movement")
		game.state = "playing"
	game.start_run(false,0,"medium","endless")
	check(game.survival.wave_total == 16,"survival also reduces mobile wave size")
	game.mobile_profile_override = false
	check(game.mob_limit() == 80 and game.projectile_limit(false) == 900,"desktop budgets remain full")
	game.queue_free()
	await process_frame
	quit(failures)
