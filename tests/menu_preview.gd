extends SceneTree

# Render the authored UI at the game's actual resolution.
func _initialize() -> void:
	call_deferred("capture")

func shot(name: String) -> void:
	for frame in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/preview-" + name + ".png")

func capture() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	await shot("menu")
	game.show_settings()
	await shot("settings")
	game.show_menu()
	game.show_permanent_shop()
	await shot("permanent-shop")
	game.progression.coins = 150
	game.refresh_permanent_shop()
	game.buy_permanent(0)
	await shot("permanent-shop-purchased")
	# Keep gameplay previews at baseline stats.
	game.progression = load("res://scripts/progression.gd").new()
	game.show_controls()
	await shot("controls")
	game.start_run()
	game.player.set_physics_process(false)
	await shot("tutorial")
	game.loot.coins = 87
	game.loot.add_item("bomb")
	game.player.health = 3
	game.open_shop()
	await shot("shop")
	game.buy_upgrade(0)
	game.buy_supply("shield")
	await shot("shop-purchased")
	game.state = "paused"
	game.show_screen("pause")
	await shot("pause")
	game.score = 12560
	game.kills = 163
	game.elapsed = 173
	game.finish(false, "A janela de extração fechou. Priorize os alvos distantes.")
	await shot("result")
	game.queue_free()
	await process_frame
	quit()
