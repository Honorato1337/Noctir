extends SceneTree

const Economy = preload("res://scripts/economy.gd")
const Planets = preload("res://scripts/planets.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, detail: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + detail)
	if not ok:
		failures += 1

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.start_run()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.loot.set_physics_process(false)
	var loot = game.loot
	var at := Vector2(180, 180)
	game.player.position = Vector2(800, 550)
	loot.drops.assign([{"pos": at, "type": "coin", "value": 2, "age": 1.0}])
	loot.collect(0)
	check(loot.coins == 3, "quick collection grants one extra coin")
	loot.drops.assign([{"pos": at, "type": "coin", "value": 2, "age": 3.0}])
	loot.collect(0)
	check(loot.coins == 5, "late collection grants only base value")
	loot.drops.assign([{"pos": at, "type": "coin", "value": 5, "age": Economy.COIN_LIFETIME - 0.1}, {"pos": at, "type": "coin", "value": 8, "age": Economy.COIN_LIFETIME - 0.1, "boss": true}])
	loot._physics_process(0.2)
	check(loot.drops.size() == 1 and loot.drops[0].boss, "ordinary coins expire but boss payout is protected")
	loot.collect_remaining()
	check(loot.coins == 13, "end-of-wave salvage never pays the quick bonus")
	loot.drops.assign([{"pos": at, "type": "coin", "value": 1, "age": 0.0}])
	game.state = "paused"
	loot._physics_process(20)
	check(loot.drops[0].age == 0.0, "paused screens freeze coin expiry")
	game.state = "playing"
	game.rng.seed = 721
	game.open_shop()
	loot.coins = 500
	game.refresh_shop()
	game.buy_upgrade(0)
	var purchased: Dictionary = game.shop_stock[0].duplicate()
	var before: int = loot.coins
	check(game.reroll_shop() and loot.coins == before - 12, "first reroll deducts the displayed price")
	check(game.shop_purchased[0] and game.shop_stock[0] == purchased, "reroll preserves installed offers and cannot resell them")
	before = loot.coins
	check(game.reroll_shop() and loot.coins == before - 20 and not game.reroll_shop(), "second reroll costs more and the two-reroll limit is enforced")
	loot.slots.assign(["", ""])
	before = loot.coins
	check(game.buy_supply("bomb") and not game.buy_supply("bomb") and loot.coins == before - 20, "supply stock is limited without charging rejected repeat purchases")
	loot.coins = 0
	check(not game.buy_upgrade(1) and loot.coins == 0, "insufficient funds cannot produce negative balance")
	var first_rng := RandomNumberGenerator.new()
	var repeat_rng := RandomNumberGenerator.new()
	first_rng.seed = 42
	repeat_rng.seed = 42
	var installed: Array[String] = ["damage", "damage"]
	var empty: Array[String] = []
	var first := Economy.offer(Planets.UPGRADES[4], 0, empty, first_rng)
	var repeated := Economy.offer(Planets.UPGRADES[4], 0, installed, repeat_rng)
	check(repeated.cost > first.cost * 1.7, "stacking the same improvement raises its next purchase price")
	# 200 independent runs per arena, including all optional boss summons.
	# Even this generous upper-bound income should not routinely clear the shop.
	var scenarios := 0
	var all_affordable := 0
	var bargains := 0
	for room in 12:
		var total_income := 0
		var cheapest_affordable := 0
		for seed_index in 200:
			game.room = room
			game.rng.seed = 10000 + room * 1000 + seed_index
			loot.reset_run()
			var kills := 36 + room * 6 + 14 + room * 2 + 12 + room
			if (room + 1) % 4 == 0:
				kills += 34
			for kill_index in kills:
				loot.enemy_died(at, false)
			loot.enemy_died(at, true)
			var base_income := 0
			var coin_count := 0
			for drop: Dictionary in loot.drops:
				if drop.type == "coin":
					base_income += int(drop.value)
					coin_count += 1
			# A competent collector picks up ~60% promptly and salvages the rest.
			var income := base_income + int(coin_count * 0.6)
			total_income += income
			var sum_prices := 0
			var cheapest := 99999
			for i in 3:
				var stock := Economy.offer(Planets.UPGRADES[i], room, empty, game.rng)
				sum_prices += int(stock.cost)
				cheapest = mini(cheapest, stock.cost)
				bargains += 1 if stock.bargain else 0
			all_affordable += 1 if income >= sum_prices else 0
			cheapest_affordable += 1 if income >= cheapest else 0
			scenarios += 1
		print("BALANCE arena %02d: mean income %.1f; can buy cheapest %d/200" % [room + 1, total_income / 200.0, cheapest_affordable])
	check(Economy.contract_reward(0) == 1 and Economy.contract_reward(11) == 1, "contracts use one special coin rather than subsidizing arena purchases")
	check(all_affordable < scenarios * 0.2, "fewer than 20%% of generous-income scenarios can buy all three modules (%d/%d)" % [all_affordable, scenarios])
	check(bargains > 600 and bargains < 1100, "discounts remain occasional in 7200 offers (%d)" % bargains)
	print("ECONOMY RESULT: %d failures" % failures)
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)

