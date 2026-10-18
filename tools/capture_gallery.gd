extends SceneTree
const DEST := "res://docs/media/gallery/"
var game: Node2D
var records: Array[Dictionary] = []
func _initialize() -> void: call_deferred("run")
func shot(file: String, caption: String) -> void:
	if game.state == "playing": game.fx._process(.18)
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(DEST+file+".png") == OK)
	records.append({"file":file+".png","caption":caption,"width":1920,"height":1080})
	print("CAPTURED "+file)
func prepare(room: int, endless: bool = false, mobile: bool = false) -> void:
	game.mobile_profile_override = mobile
	game.preferences.touch_mode = 2
	game.start_run(false,room,"hard","endless" if endless else "campaign")
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.loot.set_physics_process(false)
	game.weather.set_physics_process(false)
	game.player.position = game.arena.get_center()
	if game.blocked(game.player.position,24): game.player.position += Vector2(0,140)
	game.player.immunity = 999
	game.player.aim = Vector2.RIGHT
	game.loot.slots.assign(["bomb","shield"])
	game.deployables.inventory = "mine"
	game.time_left = 73
	game.elapsed = 127
	game.configure_camera()
func populate(count: int, mixed: bool = false) -> void:
	for i in count:
		game.spawn_enemy()
		var mob = game.enemies.get_child(-1)
		mob.set_physics_process(false)
		if mixed: mob.kind = i%3
		for attempt in 80:
			var at: Vector2 = game.player.position+Vector2.from_angle(game.rng.randf()*TAU)*game.rng.randf_range(170,570)
			if game.arena.grow(-50).has_point(at) and not game.blocked(at,mob.radius+8):
				mob.position = at
				break
		mob.age = float(i)*.2
		mob.charge_phase = fmod(float(i)*.2,2.7)
		mob.attack_visual_time = .3 if i%3 == 0 else 0
		mob.update_visual()
	game.pending = maxi(0,game.wave_total-count)
func boss_at() -> void:
	game.begin_boss()
	game.boss_ref.set_physics_process(false)
	game.boss_ref.position = game.player.position+Vector2(280,-90)
	game.boss_ref.health = game.boss_ref.max_health*.65
	game.boss_ref.update_visual()
	game.message_time = 0
func shoot_scene(radial: bool = false) -> void:
	if radial:
		for i in 4:
			game.player.clock += .07
			game.player.fire_berserk()
	else:
		game.player.fire(game.player.position,Vector2.RIGHT,false)
		game.player.weapon_animation = .4
	if is_instance_valid(game.boss_ref):
		game.boss_ref.super_aim = game.boss_ref.position.direction_to(game.player.position)
		game.boss_ref.super_gap_angle = 2.4
		game.boss_ref.fire_super_attack()
		if radial:
			for pattern in [1,2]: game.boss_ref.fire_super_layer(pattern,1)
		game.boss_ref.final_rotation = .7 if game.boss_ref.god else 0
		game.boss_ref.update_visual()
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	root.size = Vector2i(1920,1080)
	game.rng.seed = 20261018
	game.preferences.touch_mode = 2
	game.progression = load("res://scripts/progression.gd").new()
	game.progression.abilities.berserk = 1
	await shot("01-menu","Menu principal e astronauta")
	for sector in 3:
		prepare([3,7,11][sector])
		populate(42)
		boss_at()
		shoot_scene()
		await shot(["02-marte","03-netuno","04-jupiter"][sector],["Marte: Mandíbula Ferrugem e Gosmas Rubras","Netuno: Cervo Abissal e Espinhos Boreais","Júpiter: Cubos da Tormenta e Titã de Íons"][sector])
	prepare(0,true)
	game.survival.wave = 8
	game.survival.start_wave()
	populate(65,true)
	game.weather.start_event("rift")
	game.weather._physics_process(2.1)
	game.message_time = 0
	shoot_scene(true)
	await shot("05-sobrevivencia","Horda 9 em Plutão com inimigos de todos os planetas")
	prepare(12)
	populate(76,true)
	boss_at()
	game.boss_ref.super_phase = 3
	game.player.health = 2
	game.time_left = 12
	game.activate_berserk()
	game.message_time = 0
	shoot_scene(true)
	for i in game.bullets.get_child_count():
		var bullet = game.bullets.get_child(i)
		bullet.set_physics_process(false)
		bullet._physics_process(.15+fmod(float(i),5)*.13)
	game.fx.explosion(game.player.position+Vector2(-220,120),Color("ff966e"),60)
	await shot("06-caos-argos","Argos em combate denso: mobs, rajadas, meteoros e Berserk")
	game.clear_container(game.enemies)
	game.pending = 0
	game.finish_arena()
	game.collection_left = 3
	game.player.position = game.portal+Vector2(-180,40)
	game.configure_camera()
	for i in 18:
		var at: Vector2 = game.player.position+Vector2.from_angle(float(i)*TAU/18)*140
		if not game.blocked(at,8): game.loot.drops.append({"pos":at,"type":"coin","value":3,"age":0.0})
	game.loot.queue_redraw()
	await shot("07-extracao","Três segundos para embarcar: itens e moedas em risco")
	game.loot.coins = 93
	game.board_after_clear(true)
	await shot("08-loja","Loja com prazo de 20 segundos e penalidade por atraso")
	prepare(8)
	populate(35)
	game.player.rewind_ready = false
	game.deployables.inventory = "turret"
	shoot_scene()
	await shot("09-eco-e-slots","Molduras pixeladas, consumíveis, equipamento de chão e Eco usado")
	game.preferences.touch_mode = 2
	game.show_menu()
	game.show_settings()
	await shot("10-configuracoes","Configurações de áudio com volumes separados")
	var file := FileAccess.open(DEST+"manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"source":"Godot, versão 0.3.3","staged":true,"note":"Cenários de demonstração no computador com inimigos posicionados por script; arte, HUD e efeitos renderizados pelo jogo.","screenshots":records},"\t"))
	file.close()
	game.queue_free()
	await process_frame
	quit()
