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
	game.progression = load("res://scripts/progression.gd").new()
	game.start_run()
	game.player.set_physics_process(false)
	game.clear_container(game.bullets)
	var player = game.player
	check(player.weapon_id == "original" and player.fire(player.position,Vector2.RIGHT,false).size() == 1, "run starts with original single-shot weapon")
	check(is_equal_approx(player.fire_interval(),.18), "original cadence restored")
	game.show_permanent_shop()
	game.set_permanent_tab("equipment")
	game.progression.space_coins = 2
	game.progression.coins = 777
	game.loot.coins = 100
	check(not game.equip_player_weapon("shotgun"), "equipment requires enough SpaceCoin")
	game.progression.space_coins = 3
	game.refresh_permanent_shop()
	if "--preview" in OS.get_cmdline_user_args():
		for i in 4: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tmp/weapon-equipment-purchase.png")
	check(game.equip_player_weapon("shotgun") and game.progression.space_coins == 0, "equipment purchase charges three SpaceCoin")
	check(game.progression.coins == 777 and game.loot.coins == 100, "equipment never spends ordinary coins")
	check(game.equip_player_weapon("original") and game.equip_player_weapon("shotgun") and game.progression.space_coins == 0, "owned weapon re-equips without another charge")
	game.start_run()
	game.player.set_physics_process(false)
	player = game.player
	game.clear_container(game.bullets)
	var shots: Array[Vector2] = player.fire(player.position,Vector2.RIGHT,false)
	check(shots.size() == 3 and game.bullets.get_child_count() == 3, "shotgun emits three pellets")
	check(shots[1].y > 0 and shots[2].y < 0, "pellets fan out on both sides")
	check(player.fire_interval() >= .45, "slower base cadence")
	player._process(.15)
	check(player.weapon_frame() == 3 and player.weapon_sprite.texture.resource_path.contains("gun2"), "authored ten-frame shotgun animation advances")
	check(player.weapon_sprite.flip_h, "left-facing source art is aligned to rightward aim")
	game.state = "paused"
	player._process(1)
	check(player.weapon_frame() == 3, "shot animation freezes on pause")
	game.state = "playing"
	game.apply_upgrade("spread")
	check(player.fire(player.position,Vector2.RIGHT,false).size() == 5, "Prisma adds two pellets")
	game.clear_container(game.bullets)
	player.echo_frames.assign([{"t":0.0,"pos":player.position,"health":5,"shots":shots,"damage":1.0,"weapon_frame":4,"weapon_id":"shotgun"},{"t":100.0,"pos":player.position,"shots":[],"damage":1.0}])
	player._physics_process(.01)
	check(game.bullets.get_child_count() == 3 and player.echo_weapon_frame == 4, "Echo replays three pellets and original weapon frame")
	game.apply_upgrade("rate")
	var shotgun_interval: float = player.fire_interval()
	player.equip_weapon("original")
	check(player.fire_interval() < .18, "switching retains rate upgrades on original gun")
	player.equip_weapon("shotgun")
	check(is_equal_approx(player.fire_interval(),shotgun_interval), "switching retains shotgun rate upgrades")
	game.start_room()
	check(player.weapon_id == "shotgun" and player.shotgun_owned, "purchased equipment persists between arenas")
	game.start_run(false,0,"medium","endless")
	check(game.player.weapon_id == "shotgun" and game.player.shotgun_owned, "new runs retain permanent purchase and selected weapon")
	var survival_size: Vector2 = game.arena.size
	var survival_obstacles: Array = game.obstacles.duplicate()
	var survival_sector: int = game.get_node("Arena").sector_index
	game.run_mode = "campaign"
	game.room = 12
	game.start_room()
	check(game.arena.size == survival_size and game.obstacles == survival_obstacles and game.get_node("Arena").sector_index == survival_sector, "arena 13 matches original survival dimensions, rocks and visual sector")
	check(not game.blocked(game.player.position,20) and not game.get_node("Arena").route(game.player.position,game.portal,46).is_empty(), "final arena has clear spawn and navigable extraction")
	if "--preview" in OS.get_cmdline_user_args():
		game.show_permanent_shop()
		game.set_permanent_tab("equipment")
		for i in 4: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tmp/weapon-equipment-shop.png")
		game.start_run()
		game.player.immunity = 999
		game.player.aim = Vector2.RIGHT
		game.player.fire(game.player.position,Vector2.RIGHT,false)
		for i in 4: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tmp/shotgun-final-arena.png")
	var Profile = load("res://scripts/progression.gd")
	var saved = Profile.new()
	saved.save_path = "res://tmp/weapon-test.cfg"
	saved.space_coins = 5
	check(saved.equip_weapon("shotgun") and saved.space_coins == 2, "permanent equipment saves atomically")
	var loaded = Profile.new()
	loaded.save_path = saved.save_path
	loaded.load_profile()
	check(loaded.selected_weapon == "shotgun" and "shotgun" in loaded.owned_weapons and loaded.space_coins == 2, "ownership and selection survive save/load")
	var failure = Profile.new()
	failure.space_coins = 5
	failure.save_path = "res://missing-weapon-directory/profile.cfg"
	check(not failure.equip_weapon("shotgun") and failure.space_coins == 5 and failure.selected_weapon == "original" and "shotgun" not in failure.owned_weapons, "failed save refunds SpaceCoin and rolls back equipment")
	var legacy := ConfigFile.new()
	legacy.set_value("wallet","coins",123)
	legacy.save("res://tmp/weapon-legacy.cfg")
	var migrated = Profile.new()
	migrated.save_path = "res://tmp/weapon-legacy.cfg"
	migrated.load_profile()
	check(migrated.selected_weapon == "original" and migrated.coins == 123, "older profiles retain progress and original weapon")
	for upgrade in Profile.UPGRADES: loaded.levels[upgrade.key] = loaded.max_level(upgrade.key)
	loaded.coins = 1000
	check(loaded.reset_for_prestige(false) and "shotgun" in loaded.owned_weapons and loaded.selected_weapon == "shotgun", "Prestige preserves equipment")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(saved.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://tmp/weapon-legacy.cfg"))
	game.queue_free()
	await process_frame
	quit(failures)
