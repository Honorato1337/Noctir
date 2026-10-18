extends SceneTree
const FPS := 20
const FRAME_DIR := "res://tmp/mechanics-frames/"
const CLIPS := [
	["01-andando","MOVIMENTO","Astronauta andando",80],
	["02-espingarda","ESPINGARDA","3 projéteis por tiro",80],
	["03-andando-atirando","MOVER + ATIRAR","Movimento e disparos simultâneos",80],
	["04-prisma","PRISMA","Espingarda com +2 projéteis",80],
	["05-dash","DASH","Investida com invulnerabilidade",80],
	["06-eco","ECO TEMPORAL","Rebobina e repete os disparos",120],
	["07-berserk","BERSERK","Rajadas em todas as direções",80],
	["08-arma-original","ARMA ORIGINAL","Tiro simples e cadência rápida",80]]
var game: Node2D
var heading: Label
var caption: Label
func _initialize() -> void: call_deferred("run")
func run() -> void:
	Engine.physics_ticks_per_second = 60
	root.size = Vector2i(640,360)
	root.content_scale_size = Vector2i(640,360)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.get_node("UI/HUD").hide()
	game.preferences.touch_mode = 2
	game.progression = load("res://scripts/progression.gd").new()
	game.progression.abilities.berserk = 1
	var overlay := CanvasLayer.new()
	overlay.layer = 20
	root.add_child(overlay)
	heading = Label.new()
	heading.position = Vector2(18,12)
	heading.add_theme_font_override("font",game.font)
	heading.add_theme_font_size_override("font_size",22)
	heading.add_theme_color_override("font_color",Color("71e4c5"))
	overlay.add_child(heading)
	caption = Label.new()
	caption.position = Vector2(18,329)
	caption.add_theme_font_override("font",game.font)
	caption.add_theme_font_size_override("font_size",18)
	overlay.add_child(caption)
	var manifest: Array[Dictionary] = []
	for spec in CLIPS:
		game.start_run()
		game.controls.last_device = "joypad"
		game.controls.touch_move = Vector2.ZERO
		game.controls.touch_aim = Vector2.ZERO
		game.player.set_process(false)
		game.player.set_physics_process(false)
		game.weather.set_physics_process(false)
		game.loot.set_physics_process(false)
		game.fx.set_process(false)
		game.touch_controls.hide()
		game.touch_controls.set_process(false)
		game.player.position = game.arena.get_center()
		game.player.aim = Vector2.RIGHT
		game.player.immunity = 0
		var center: Vector2 = game.player.position
		game.configure_camera()
		game.get_node("Camera2D").zoom = Vector2(2,2)
		game.get_node("Camera2D").position = center
		game.get_node("Camera2D").reset_smoothing()
		heading.text = spec[1]
		caption.text = spec[2]
		var kind: String = spec[0]
		if kind in ["02-espingarda","04-prisma"]:
			game.player.shotgun_owned = true
			assert(game.player.equip_weapon("shotgun"))
		if kind == "04-prisma": game.apply_upgrade("spread")
		if kind == "07-berserk": game.activate_berserk()
		if kind == "05-dash": game.player.position.x -= 90
		DirAccess.make_dir_recursive_absolute(FRAME_DIR+kind)
		for frame in int(spec[3]):
			var time := float(frame)/FPS
			var moving: bool = kind in ["01-andando","03-andando-atirando","06-eco"]
			var firing: bool = kind in ["02-espingarda","03-andando-atirando","04-prisma","06-eco","08-arma-original"]
			game.controls.touch_move = Vector2(cos(time*TAU/4)*.42,0) if moving else Vector2.ZERO
			game.controls.touch_aim = Vector2.RIGHT if firing else Vector2.ZERO
			if kind == "05-dash":
				game.controls.touch_move = Vector2.ZERO
				game.player.aim = Vector2.RIGHT if frame < 50 else Vector2.LEFT
				if frame in [10,50]:
					game.controls.touch_move = Vector2.RIGHT if frame < 50 else Vector2.LEFT
					Input.action_press("dash")
			if kind == "06-eco" and frame == 70:
				game.player.rewind()
				assert(not game.player.echo_frames.is_empty(),"Echo must replay recorded frames")
			for step in 3:
				game.player._physics_process(1.0/60)
				for bullet in game.bullets.get_children():
					bullet.set_physics_process(false)
					if not bullet.is_queued_for_deletion(): bullet._physics_process(1.0/60)
			Input.action_release("dash")
			game.player._process(1.0/FPS)
			game.fx._process(1.0/FPS)
			await process_frame
			await RenderingServer.frame_post_draw
			assert(root.get_texture().get_image().save_png(FRAME_DIR+kind+"/%04d.png"%frame) == OK)
		manifest.append({"file":kind+".gif","title":spec[1],"caption":spec[2],"frames":spec[3],"fps":FPS,"legacy":false})
		print("CAPTURED "+kind+" / "+str(spec[3])+" frames")
	var out := FileAccess.open("res://docs/media/gifs/manifest.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"size":[640,360],"clips":manifest,"source":"Godot native rendering, staged isolated gameplay","audio":false},"\t"))
	out.close()
	game.queue_free()
	await process_frame
	quit()
