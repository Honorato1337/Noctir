extends SceneTree
const Terrain = preload("res://scripts/planet_terrain.gd")
const DEST := "res://docs/media/"
class JupiterFloor:
	extends Node2D
	func _draw() -> void:
		preload("res://scripts/planet_terrain.gd").draw_floor(self,Rect2(0,0,1536,896),2)

func _initialize() -> void: call_deferred("capture_all")
func shot(name: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(DEST+name+".png")
	assert(result == OK)
	print("CAPTURED "+name)

func capture_all() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1536,896)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	viewport.add_child(JupiterFloor.new())
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	assert(viewport.get_texture().get_image().save_png(DEST+"jupiter-fundo.png") == OK)
	var tile := Terrain.floor_texture().get_image().get_region(Rect2i(0,32,32,32))
	assert(tile.save_png(DEST+"jupiter-tile.png") == OK)
	viewport.queue_free()
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	root.size = Vector2i(1920,1080)
	game.rng.seed = 20261018
	game.preferences.touch_mode = 2 # desktop gallery; no simulated touchscreen
	game.progression = load("res://scripts/progression.gd").new()
	game.progression.abilities.berserk = 1
	await shot("01-menu")
	if "--menu-only" in OS.get_cmdline_user_args():
		game.queue_free()
		await process_frame
		quit()
		return
	for sector in 3:
		game.start_run(false,[2,4,11][sector],"medium")
		game.player.immunity = 999
		var center: Vector2 = game.arena.get_center()
		for shift: Vector2 in [Vector2(-140,80),Vector2(0,140),Vector2(-100,-100),Vector2.ZERO]:
			if not game.blocked(center+shift,24):
				game.player.position = center+shift
				break
		game.configure_camera()
		game.loot.slots.assign(["bomb","shield"])
		if sector == 1 or sector == 2: game.begin_boss()
		for frame in (180 if sector == 2 else 360):
			if frame % 12 == 0:
				var target: Vector2 = game.boss_ref.position if is_instance_valid(game.boss_ref) else game.player.position+Vector2.RIGHT
				game.player.fire(game.player.position,game.player.position.direction_to(target),false)
			await physics_frame
		game.message_time = 0
		await shot(["02-marte","03-netuno","04-jupiter"][sector])
	game.start_run(false,0,"hard","endless")
	game.survival.wave = 5
	game.survival.start_wave()
	game.player.position = game.arena.get_center()+Vector2(150,40)
	game.configure_camera()
	game.player.immunity = 999
	game.loot.slots.assign(["bomb","overdrive"])
	for frame in 660:
		if frame == 400: game.activate_berserk()
		await physics_frame
	game.message_time = 0
	await shot("05-sobrevivencia")
	game.clear_container(game.enemies)
	game.pending = 0
	game.survival.boss_due = false
	game.loot.coins = 96
	game.survival.tick(0.01)
	await shot("06-loja")
	game.queue_free()
	await process_frame
	quit()
