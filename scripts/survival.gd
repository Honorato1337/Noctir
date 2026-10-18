extends RefCounted
# Active-combat time drives scaling; menus and death prompts cannot advance waves.
var game: Node2D
var tier := 0
var boss_number := 0
var boss_left := 60.0
var shop_at := 120.0
var spawn_left := 0.2
var pressure := 1.0

func reset(owner_game: Node2D) -> void:
	game = owner_game
	tier = 0
	boss_number = 0
	boss_left = {"easy":80.0,"medium":60.0,"hard":45.0}.get(game.run_difficulty,60.0)
	shop_at = 120
	spawn_left = 0.2

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
	# Bound abandoned loot as well as enemies during arbitrarily long runs.
	while game.loot.drops.size() > 256:
		game.loot.drops.pop_front()
	pressure = {"easy":0.75,"medium":1.0,"hard":1.4}[game.run_difficulty]
	var next_tier := int(game.elapsed * pressure / 60.0)
	if next_tier != tier:
		tier = next_tier
		game.message = "PRESSÃO %d / INIMIGOS MAIS FORTES" % (tier+1)
		game.message_time = 3
	spawn_left -= delta
	if spawn_left <= 0:
		game.pending = mini(game.pending,24)
		var batch := mini(ceili((3+tier*0.7)*pressure)+mini(game.pending,4), game.MAX_ACTIVE_ENEMIES-3-game.enemies.get_child_count())
		game.pending = maxi(0,game.pending-maxi(0,batch))
		for i in maxi(0,batch): game.spawn_enemy()
		spawn_left = maxf(0.3, 1.2/(pressure+tier*0.08))
	if not is_instance_valid(game.boss_ref) or game.boss_ref.is_queued_for_deletion():
		game.boss_ref = null
		for enemy in game.enemies.get_children():
			if enemy.boss and not enemy.is_queued_for_deletion():
				game.boss_ref = enemy
				break
	boss_left -= delta
	if boss_left <= 0:
		var bosses := 0
		for enemy in game.enemies.get_children():
			if enemy.boss: bosses += 1
		if bosses < 3 and game.enemies.get_child_count() < game.MAX_ACTIVE_ENEMIES:
			boss_number += 1
			game.boss_summon_budget = mini(60,game.boss_summon_budget+12+tier*2)
			game.spawn_enemy(true)
			game.play_sfx("boss_alert")
			game.message = "SUPERCHEFE NA ARENA!" if boss_number%3 == 0 else "CHEFE NA ARENA / AS HORDAS CONTINUAM"
			game.message_time = 4
			boss_left = {"easy":80.0,"medium":60.0,"hard":45.0}[game.run_difficulty]
		else:
			boss_left = 3
	if game.elapsed >= shop_at:
		shop_at += 120
		game.open_shop()
		game.panel.find_child("LeaveButton",true,false).text = "VOLTAR À SOBREVIVÊNCIA"

