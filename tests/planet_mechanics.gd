extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok:
		failures += 1

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.start_run()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.encounters.set_physics_process(false)
	game.contracts.set_physics_process(false)
	var encounter = game.encounters
	for sector in 3:
		game.room = sector * 4 + 3
		game.start_room()
		game.player.position = Vector2(970, 650)
		for offset: Vector2 in [Vector2.ZERO, Vector2(-110, 0), Vector2(0, 120), Vector2(110, 0)]:
			if not game.blocked(Vector2(970, 650) + offset, 18):
				game.player.position = Vector2(970, 650) + offset
				break
		game.player.immunity = 1000
		game.begin_boss()
		var boss = game.boss_ref
		boss.set_physics_process(false)
		boss.super_phase = 3
		encounter.super_attack(boss, 0)
		var types: Array[String] = []
		for field in encounter.fields:
			types.append(field.kind)
		check(types.has(["blast", "cage", "gravity"][sector]), "planet %d has a distinct primary boss mechanic" % sector)
		if sector == 0:
			var budget: int = game.boss_summon_budget
			var pending: int = game.pending
			encounter.super_attack(boss, 1)
			check(game.boss_summon_budget < budget and game.pending > pending and budget - game.boss_summon_budget == game.pending - pending, "Mars swarm consumes a finite reinforcement budget")
			game.player.position = encounter.fields[0].pos
			game.player.immunity = 0
			var health: int = game.player.health
			encounter._physics_process(.5)
			check(game.player.health == health, "bombardment cannot hurt during its warning")
			encounter._physics_process(.6)
			check(game.player.health == health - 1, "marked Mars explosion actually deals damage after warning")
		elif sector == 1:
			var cage: Dictionary = encounter.fields[0]
			cage.age = cage.warning + .01
			var gap: Vector2 = cage.pos + Vector2.RIGHT.rotated(cage.gap) * cage.radius
			var wall: Vector2 = cage.pos + Vector2.RIGHT.rotated(cage.gap + PI) * cage.radius
			check(encounter.player_force(wall).length() > 100 and encounter.player_force(gap).length() == 0, "ice prison restrains at walls and leaves a real escape opening")
			check(types.has("frost"), "Neptune layers frost patches around its prison")
		else:
			var well: Dictionary = encounter.fields[0]
			well.age = well.warning + .01
			var at: Vector2 = well.pos + Vector2(100, 0)
			check(encounter.player_force(at).x < -50, "Jupiter gravity attracts toward its fixed eye")
			check(types.has("storm"), "Jupiter combines attraction with delayed storm explosions")
			for i in 8:
				encounter.add_field("gravity", well.pos, 340, .1, 3, boss, 170)
				encounter.fields[-1].age = .2
			check(encounter.player_force(at).length() <= 170.01, "overlapping gravity cannot exceed the force cap")
		var age: float = encounter.fields[0].age
		game.state = "paused"
		encounter._physics_process(5)
		check(encounter.fields[0].age == age, "planet mechanics freeze during pause")
		game.state = "playing"
		boss.health = boss.max_health * .4
		boss.super_phase = 1
		boss.tick_superboss(.01)
		check(encounter.fields.is_empty(), "boss phase change clears hazards for a breathing interval")
		encounter.super_attack(boss, 0)
		boss.hurt(99999)
		check(encounter.fields.is_empty(), "killing the boss immediately removes its environmental hazards")
		await process_frame
	game.room = 8
	game.start_room()
	for role in 3:
		game.spawn_enemy()
		var mob = game.enemies.get_child(-1)
		mob.set_physics_process(false)
		mob.jupiter_role = role
		mob.shot_cd = 0
		game.clear_container(game.bullets)
		encounter.reset()
		if role == 0:
			mob.age = 2.2
			mob._physics_process(.01)
			check(encounter.fields.size() == 1 and encounter.fields[0].kind == "storm", "Jupiter charger leaves delayed electric mines")
		else:
			mob.tick_jupiter_mob(.01, Vector2.RIGHT)
			check(mob.storm_windup > 0 and game.bullets.get_child_count() == 0, "Jupiter ranged role warns before shooting")
			mob.tick_jupiter_mob(.71, Vector2.RIGHT)
			check(game.bullets.get_child_count() == (5 if role == 1 else 3), "Jupiter ranged role fires its own salvo")
			if role == 2:
				check(encounter.fields.size() == 1 and encounter.fields[0].kind == "gravity", "Jupiter warden deploys a gravitational well")
		mob.queue_free()
		await process_frame
	game.room = 2
	game.start_room()
	game.begin_boss()
	var mars_boss = game.boss_ref
	mars_boss.set_physics_process(false)
	mars_boss.update_visual()
	check(mars_boss.mars_boss_visual.visible and mars_boss.mars_boss_visual.sprite_frames.get_frame_count("walk") == 4, "regular Mars boss uses the supplied four-frame animation")
	game.room = 3
	game.start_room()
	game.begin_boss()
	game.boss_ref.update_visual()
	check(not game.boss_ref.mars_boss_visual.visible, "superboss does not borrow the regular boss art")
	encounter.reset()
	encounter.add_field("gravity", game.player.position + Vector2(100, 0), 340, .1, 3, game.boss_ref, 170)
	encounter.fields[0].age = .2
	var before: Vector2 = game.player.position
	var dash_direction := Vector2.UP if not game.blocked(before + Vector2(0, -10), 13) else Vector2.RIGHT
	game.player.dash_dir = dash_direction
	game.player.dash_time = .15
	game.player._physics_process(.01)
	check(game.player.position.distance_to(before + dash_direction * 8.5) < .1, "dash keeps full movement and ignores gravitational attraction")
	encounter.reset()
	for i in 120:
		encounter.add_field("blast", game.player.position, 30, 1, 2, game.boss_ref)
	check(encounter.fields.size() == encounter.MAX_FIELDS, "environmental hazards respect their total cap")
	encounter.reset()
	game.spawn_enemy()
	var field_mob = game.enemies.get_child(-1)
	for i in 50:
		encounter.add_field("storm", field_mob.position, 30, 1, 2, field_mob)
	check(encounter.fields.size() == encounter.MAX_MOB_FIELDS, "ordinary mobs cannot consume the boss hazard budget")
	encounter.reset()
	var contracts = game.contracts
	contracts.enabled = true
	contracts.reset_run()
	var initial_kind: String = contracts.kind
	var initial_target: int = contracts.target
	check(initial_kind in contracts.KINDS and initial_target >= 2, "run draws a difficult boss contract")
	contracts.record("kill")
	contracts.record("dash")
	contracts.record("quick")
	check(contracts.progress == 0, "ordinary kills, dash and coins cannot earn SpaceCoin")
	contracts.kind = "bosses"
	contracts.target = 6
	contracts.progress = 0
	var coins: int = game.loot.coins
	var space_coins: int = game.progression.space_coins
	for i in 5:
		contracts.record("boss")
		contracts.start_room()
	check(not contracts.completed and contracts.progress == 5, "six bosses required across arena transitions")
	contracts.record("boss")
	contracts.record("boss")
	contracts.start_room()
	check(contracts.completed and game.loot.coins == coins and game.progression.space_coins == space_coins + 1, "contract pays once per run and stays completed in next arena")
	game.run_space_reward = 0
	contracts.reset_run()
	contracts.kind = "survivor"
	contracts.target = 4
	contracts.record("boss")
	game.player.immunity = 0
	game.player.health = 5
	game.player.hurt(1)
	check(contracts.progress == 1, "survival contract permits damage")
	game.player.immunity = 0
	game.player.hurt(999)
	check(contracts.progress == 0, "actual death resets survival boss streak")
	game.continue_after_death()
	contracts.kind = "superbosses"
	contracts.target = 2
	contracts.record("boss")
	check(contracts.progress == 0, "regular bosses do not count as superbosses")
	contracts.record("superboss")
	contracts.start_room()
	check(contracts.progress == 1 and not contracts.completed, "superboss contract spans planets")
	contracts.record("superboss")
	check(contracts.completed and game.run_space_reward == 1, "two superbosses finish difficult contract")
	game.run_space_reward = 0
	contracts.reset_run()
	contracts.kind = "superbosses"
	contracts.target = 2
	for room_index in [3, 7]:
		game.room = room_index
		game.start_room()
		game.begin_boss()
		var actual_boss = game.boss_ref
		actual_boss.set_physics_process(false)
		actual_boss.hurt(100000)
		actual_boss.hurt(100000)
		check(contracts.progress == (1 if room_index == 3 else 2), "actual superboss death counts once even with duplicate hits")
	check(contracts.completed and game.run_space_reward == 1, "real superboss kills award one run reward")
	contracts.completed = false
	contracts.progress = 0
	contracts.record("superboss")
	check(contracts.progress == 0, "run reward guard prevents another payout independently of completion flag")
	game.run_space_reward = 0
	contracts.reset_run()
	game.practice_mode = true
	contracts.record("boss")
	contracts.record("superboss")
	check(contracts.progress == 0, "practice cannot progress contracts")
	game.set_process(false)
	game.get_node("PlanetMusic").stop()
	await create_timer(.2).timeout
	game.queue_free()
	await process_frame
	print("PLANET MECHANICS RESULT: %d failures" % failures)
	quit(1 if failures else 0)
