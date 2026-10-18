extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, detail: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+detail)
	if not ok: failures += 1
func target(game: Node2D, distance: float) -> Node2D:
	game.spawn_enemy()
	var mob = game.enemies.get_child(-1)
	mob.set_physics_process(false)
	mob.position = game.player.position + Vector2(distance,0)
	mob.health = 100
	mob.shield = 0
	return mob
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run()
	game.player.set_physics_process(false)
	game.loot.set_physics_process(false)
	game.player.damage = 1
	game.clear_container(game.enemies)
	var mobs: Array = []
	for distance in [120.0,120.1,240.0,240.1,360.0,360.1]: mobs.append(target(game,distance))
	mobs[0].boss = true
	game.shoot(game.player.position,Vector2.RIGHT,1,true)
	var nearby = game.bullets.get_child(-1)
	nearby.set_physics_process(false)
	nearby.position = game.player.position+Vector2(100,0)
	game.shoot(game.player.position,Vector2.RIGHT,1,true)
	var distant = game.bullets.get_child(-1)
	distant.set_physics_process(false)
	distant.position = game.player.position+Vector2(400,0)
	game.shoot(game.player.position,Vector2.RIGHT,1,false)
	var friendly = game.bullets.get_child(-1)
	friendly.set_physics_process(false)
	game.loot.slots.assign(["bomb",""])
	check(game.loot.use_slot(0) and game.loot.slots[0].is_empty(),"bomb consumes exactly one inventory item")
	check(mobs[0].health == 88,"inner ring deals twelve damage without doubled boss damage")
	check(mobs[1].health == 94 and mobs[2].health == 94,"middle ring deals half damage at both boundaries")
	check(mobs[3].health == 97 and mobs[4].health == 97,"outer ring deals quarter damage through 360px")
	check(mobs[5].health == 100,"outside radius receives no damage")
	check(nearby.is_queued_for_deletion() and not distant.is_queued_for_deletion() and not friendly.is_queued_for_deletion(),"only nearby hostile bullets are removed")
	game.clear_container(game.enemies)
	mobs.clear()
	# Insert farthest first so the cap must actually sort by distance.
	for i in range(19,-1,-1): mobs.append(target(game,20+i*10))
	var already_dead = target(game,1)
	already_dead.queue_free()
	game.loot.detonate_bomb()
	var hit := 0
	for mob in mobs:
		if mob.health < 100: hit += 1
	check(hit == 12,"crowded explosion damages at most twelve living targets")
	check(mobs[0].health == 100 and mobs[-1].health < 100,"nearest enemies have priority independent of spawn order")
	game.queue_free()
	await process_frame
	quit(failures)
