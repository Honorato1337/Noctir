extends SceneTree
const Terrain = preload("res://scripts/planet_terrain.gd")
const DEST := "res://docs/media/"
class RockPreview:
	extends Node2D
	func _draw() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var terrain = preload("res://scripts/planet_terrain.gd")
		for index in 2:
			var region: Rect2 = terrain.art_region(2,index+1)
			draw_texture_rect_region(terrain.texture(),Rect2(Vector2(24+index*192,16),region.size*4),region)

func _initialize() -> void: call_deferred("capture")
func shot(name: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(DEST+name+".png") == OK)
	print("CAPTURED "+name)
func capture() -> void:
	for column in [1,2,3]:
		var region := Rect2i(Terrain.art_region(2,column))
		var source := Terrain.texture().get_image().get_region(region)
		assert(source.save_png(DEST+"jupiter-rochas/"+["pedra-01","pedra-02","parede"][column-1]+".png") == OK)
	var preview := SubViewport.new()
	preview.size = Vector2i(384,160)
	preview.transparent_bg = true
	preview.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(preview)
	preview.add_child(RockPreview.new())
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	assert(preview.get_texture().get_image().save_png(DEST+"jupiter-rochas/preview.png") == OK)
	preview.queue_free()
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	root.size = Vector2i(1920,1080)
	game.preferences.touch_mode = 2
	game.rng.seed = 20261019
	game.progression = load("res://scripts/progression.gd").new()
	game.progression.abilities.berserk = 1
	game.start_run(false,12,"hard")
	game.set_physics_process(false)
	game.player.position = game.arena.get_center()+Vector2(-110,70)
	game.player.immunity = 999
	game.player.health = 2
	game.loot.slots.assign(["bomb","shield"])
	game.configure_camera()
	game.begin_boss()
	game.boss_ref.position = game.player.position+Vector2(300,-160)
	game.boss_ref.health = game.boss_ref.max_health*.5
	for i in 79:
		game.spawn_enemy()
		var mob = game.enemies.get_child(-1)
		for attempt in 50:
			var point: Vector2 = game.player.position+Vector2.from_angle(game.rng.randf()*TAU)*game.rng.randf_range(200,530)
			if game.arena.grow(-50).has_point(point) and not game.blocked(point,mob.radius+8):
				mob.position = point
				break
	game.pending = 0
	game.time_left = 8
	game.message_time = 0
	game.deployables.inventory = "beacon"
	game.deployables.place()
	game.activate_berserk()
	game.message_time = 0
	for frame in 105:
		await physics_frame
	await shot("08-caos-total")
	game.clear_container(game.enemies)
	game.finish_arena()
	game.pending = 0
	game.player.position = game.portal+Vector2(-190,90)
	if game.blocked(game.player.position,20): game.player.position = game.portal+Vector2(-140,-90)
	game.configure_camera()
	game.collection_left = 3.0
	for i in 20:
		var at: Vector2 = game.player.position+Vector2.from_angle(i*TAU/20)*game.rng.randf_range(80,220)
		if game.arena.has_point(at) and not game.blocked(at,8):
			game.loot.drops.append({"pos":at,"type":"coin","value":3,"age":0.0})
	game.loot.drop_item(game.player.position+Vector2(-95,30),"overdrive")
	await shot("09-extracao-urgente")
	game.queue_free()
	await process_frame
	quit()
