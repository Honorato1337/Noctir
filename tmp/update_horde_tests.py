from pathlib import Path
p=Path('tests/smoke.gd');s=p.read_text(encoding='utf-8').replace('game.pending == 7','game.pending == 36').replace('ends_with("After Burner Neue.ttf")','ends_with("W95F.otf")')
needle='\tgame.start_run()\n\t# Manual'
s=s.replace(needle, '\tcheck(game.panel.find_child("Title", true, false).get_theme_font("font").resource_path.ends_with("After Burner Neue.ttf"), "only main title retains After Burner")\n\tgame.start_run()\n\t# Manual',1)
start=s.index('\t\twhile game.pending > 0:',s.index('var layouts:'))
end=s.index('\tvar unique_layouts := {}',start)
s=s[:start]+'''		while game.pending > 0:
			game.spawn_enemy()
			game.pending -= 1
		for enemy in game.enemies.get_children():
			enemy.set_physics_process(false)
			enemy.hurt(10000)
		await process_frame
		game._physics_process(0.016)
		check(game.boss_spawned and is_instance_valid(game.boss_ref) and game.pending > 0, "every phase ends with boss and minions %d" % (room_index + 1))
		var boss = game.boss_ref
		boss.set_physics_process(false)
		boss.health = boss.max_health * 0.4
		boss.shot_cd = 0
		var before_shots: int = game.bullets.get_child_count()
		boss._physics_process(0.016)
		check(game.bullets.get_child_count() - before_shots == 16 + game.planet_index * 2, "boss second-phase radial attack %d" % (room_index + 1))
		while game.pending > 0:
			game.spawn_enemy()
			game.pending -= 1
		for enemy in game.enemies.get_children():
			enemy.set_physics_process(false)
			enemy.hurt(10000)
		await process_frame
		game._physics_process(0.4)
		check(game.state == "shop" and game.loot.coins > 0, "phase clear collects coins and opens shop %d" % (room_index + 1))
		var balance: int = game.loot.coins
		var price: int = game.shop_stock[0].cost
		check(game.buy_upgrade(0) and game.loot.coins == balance - price, "shop charges exact upgrade price %d" % (room_index + 1))
		check(not game.buy_upgrade(0), "shop cannot buy same stock twice %d" % (room_index + 1))
		game.panel.find_child("LeaveButton", true, false).pressed.emit()
		if room_index < game.total_rooms() - 1:
			check(game.state == "exit", "shop exit unlocks extraction %d" % (room_index + 1))
			game.player.position = game.portal
			Input.action_press("interact")
			game._physics_process(0.016)
			Input.action_release("interact")
			check(game.room == room_index + 1 and game.state == "playing", "portal advances %d" % (room_index + 1))
		else:
			check(game.state == "ended" and game.score > 0, "final shop exit produces victory")
'''+s[end:]
pos=s.index('\t# Validate every actual wave')
s=s[:pos]+'''	# Inventory and economy behavior, independent of random drops.
	game.loot.reset_run()
	check(game.loot.add_item("medkit") and game.loot.add_item("shield") and not game.loot.add_item("bomb"), "inventory enforces exactly two slots")
	game.player.health = game.player.max_health
	check(not game.loot.use_slot(0) and game.loot.slots[0] == "medkit", "full health does not waste medkit")
	game.player.health = 1
	check(game.loot.use_slot(0) and game.player.health == 4 and game.loot.slots[0].is_empty(), "medkit heals three and consumes one slot")
	check(game.loot.use_slot(1) and game.player.immunity >= 5, "shield grants five seconds immunity")
	game.loot.add_item("overdrive")
	check(game.loot.use_slot(0) and game.player.overdrive_time == 9, "overdrive activates temporary firepower")
	game.player.overdrive_time = 0
	game.loot.add_item("bomb")
	game.spawn_enemy()
	var bomb_target = game.enemies.get_child(game.enemies.get_child_count() - 1)
	bomb_target.set_physics_process(false)
	check(game.loot.use_slot(0) and bomb_target.is_queued_for_deletion(), "bomb damages all enemies and consumes slot")
	await process_frame
	game.loot.reset_run()
	game.rng.seed = 45678
	for i in 2000:
		game.loot.enemy_died(Vector2(180, 386), false)
	var coin_drops := 0
	var item_drops := 0
	for drop in game.loot.drops:
		if drop.type == "coin":
			coin_drops += 1
		else:
			item_drops += 1
	check(coin_drops == 2000 and item_drops >= 20 and item_drops <= 90, "seeded sample gives guaranteed coins and rare consumables")
	game.loot.collect_remaining()
	check(game.loot.coins >= 2000 and not game.loot.slots[0].is_empty() and not game.loot.slots[1].is_empty(), "phase cleanup banks coins and fills only available slots")
	check(game.loot.drops.size() == item_drops - 2, "full slots leave extra consumables on ground")
	game.open_shop()
	game.loot.coins = 0
	check(not game.buy_upgrade(0), "insufficient coins reject purchase")
	game.loot.coins = 100
	check(not game.buy_supply("bomb") and game.loot.coins == 100, "full inventory rejects paid item without charging")
	game.loot.slots = ["", ""]
	check(game.buy_supply("bomb") and game.loot.coins == 82, "store consumable fills slot and charges eighteen")
	game.player.health = game.player.max_health
	check(not game.buy_supply("repair") and game.loot.coins == 82, "full health rejects repair without charging")
	game.close_panel()
	game.state = "playing"
	game.fx.particles.clear()
	game.fx.sparks(Vector2.ZERO, Color.WHITE, 5000)
	check(game.fx.particles.size() == game.fx.MAX_PARTICLES, "particles obey density budget")
	game.loot.reset_run()
'''+s[pos:]
s=s.replace('game.chosen_upgrades.is_empty(), "new attempt', 'game.chosen_upgrades.is_empty() and game.loot.coins == 0 and game.loot.slots == ["", ""], "new attempt')
p.write_text(s,encoding='utf-8')
