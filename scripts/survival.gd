extends RefCounted
# Active-combat time drives scaling; menus and death prompts cannot advance waves.
var game: Node2D
var tier := 0
var wave := 0
var wave_total := 0
var boss_number := 0
var boss_due := false
var spawn_left := 0.2
var pressure := 1.0

func reset(owner_game: Node2D) -> void:
	game = owner_game
	tier = 0
	wave = 0
	wave_total = 0
	boss_number = 0
	boss_due = false
	spawn_left = 0.2

func start_wave() -> void:
	wave += 1
	tier = wave - 1
	pressure = {"easy":0.75,"medium":1.0,"hard":1.4}[game.run_difficulty]
	wave_total = ceili((24 + tier*12 + tier*tier*2)*pressure)
	game.pending = wave_total
	game.phase_kills = 0
	boss_due = wave % 3 == 0
	game.boss_ref = null
	game.boss_summon_budget = 12 + mini(48,tier*2)
	spawn_left = 0.2
	game.message = "HORDA %d / %d INIMIGOS%s" % [wave,wave_total," + CHEFE" if boss_due else ""]
	game.message_time = 4
	game.player.immunity = maxf(game.player.immunity,1.5)

func health_factor() -> float:
	return 1.0 + tier * 0.22 + tier * tier * 0.014

func speed_factor() -> float:
	return minf(1.8, 1.05 + tier * 0.035)

func enemy_kind(is_boss: bool) -> int:
	if is_boss:
		return (boss_number / 3 - 1) % 3 if boss_number % 3 == 0 else (boss_number - 1) % 3
	return game.rng.randi_range(0, mini(2, tier))

func spawn_position(radius: float) -> Vector2:
	for attempt in 48:
		var point: Vector2 = game.player.position + Vector2.from_angle(game.rng.randf()*TAU)*game.rng.randf_range(520, 780)
		if game.arena.grow(-radius-12).has_point(point) and not game.blocked(point, radius+8):
			return point
	for point: Vector2 in game.get_node("Arena").spawn_gates():
		if point.distance_to(game.player.position) > 300 and not game.blocked(point,radius): return point
	return game.get_node("Arena/BossSpawn").global_position

func tick(delta: float) -> void:
	while game.loot.drops.size() > 256:
		game.loot.drops.pop_front()
	spawn_left -= delta
	if game.pending > 0 and spawn_left <= 0:
		var batch := mini(ceili((4+tier*0.7)*pressure), mini(game.pending,game.MAX_ACTIVE_ENEMIES-1-game.enemies.get_child_count()))
		for i in maxi(0,batch):
			game.spawn_enemy()
			game.pending -= 1
		spawn_left = maxf(0.25,0.8/(pressure+tier*0.08))
	if boss_due and game.pending == 0 and game.enemies.get_child_count() < game.MAX_ACTIVE_ENEMIES:
		boss_due = false
		boss_number += 1
		game.spawn_enemy(true)
		game.play_sfx("boss_alert")
		game.message = "SUPERCHEFE NA HORDA!" if boss_number%3 == 0 else "CHEFE NA HORDA!"
		game.message_time = 4
	if game.pending == 0 and not boss_due and game.enemies.get_child_count() == 0:
		# Bank the wave's remaining loot before the short shopping interval.
		game.loot.collect_remaining()
		game.open_shop()
		game.shop_left = 10.0
		game.update_shop_clock()
		game.panel.find_child("LeaveButton",true,false).text = "INICIAR HORDA %d" % (wave+1)
