extends SceneTree
const FPS := 30
const LENGTH := 30.0
class CaptureAudio:
	extends Node
	var music: AudioStreamPlayer
	func _process(_delta: float) -> void:
		music.volume_db = -16
var game: Node2D
var cursor: TextureRect
var route := PackedVector2Array()
var deaths := 0
var damage_taken := 0
var previous_health := 0
var summary := {"eco":false,"berserk":false,"mine":false,"turret":false,"beacon":false,"bomb":false,"shield":false,"overdrive":false,"medkit":false,"original":false,"shotgun":false}
func _initialize() -> void: call_deferred("run")
func supply(kind: String) -> void:
	for i in 2:
		if game.loot.slots[i].is_empty():
			game.loot.add_item(kind)
			summary[kind] = game.loot.use_slot(i)
			return
func device(kind: String) -> void:
	if not game.deployables.inventory.is_empty(): game.deployables.inventory = ""
	game.deployables.add_item(kind)
	summary[kind] = game.deployables.place() or bool(summary[kind])
	game.deployables.inventory = {"mine":"turret","turret":"beacon","beacon":"mine"}[kind]
func run() -> void:
	root.size = Vector2i(1152,720)
	game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.preferences.touch_mode = 2
	game.progression = load("res://scripts/progression.gd").new()
	for upgrade in game.Progression.UPGRADES:
		game.progression.levels[upgrade.key] = game.progression.max_level(upgrade.key)
	game.progression.abilities.pickup = 5
	game.progression.abilities.berserk = 1
	game.progression.owned_weapons.append("shotgun")
	game.progression.selected_weapon = "shotgun"
	game.start_run(false,12,"hard")
	for key in ["spread","spread","spread","rate","rate","rate","damage","damage","damage","health","health","health","speed","time"]: game.apply_upgrade(key)
	game.player.position = game.arena.get_center()+Vector2(0,-40)
	game.player.cooldown = 0
	game.player.immunity = 0
	game.loot.slots.assign(["bomb","overdrive"])
	game.loot.coins = 180
	game.deployables.inventory = "mine"
	game.pending = 400
	game.time_left = 160
	game.begin_boss()
	game.boss_ref.position = game.player.position+Vector2(440,-90)
	game.boss_ref.health *= 2
	game.boss_ref.max_health = game.boss_ref.health
	game.boss_ref.shield *= 2
	game.boss_ref.max_shield = game.boss_ref.shield
	game.configure_camera()
	game.message = "CARGA MÁXIMA / NEXO / DANO ATIVO"
	game.message_time = 4
	game.controls.last_device = "keyboard"
	# Native OS cursors do not enter movie frames; draw the same art in the video.
	var layer := CanvasLayer.new()
	layer.layer = 30
	game.add_child(layer)
	cursor = TextureRect.new()
	cursor.texture = load("res://assets/ui/Mira.png")
	cursor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cursor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cursor.size = Vector2(32,32)
	cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var invert := ShaderMaterial.new()
	invert.shader = load("res://scripts/cursor_invert.gdshader")
	cursor.material = invert
	layer.add_child(cursor)
	for child in game.get_children():
		if child.get_script() == load("res://scripts/game_cursor.gd"):
			child.set_process(false)
			if is_instance_valid(child.pointer): child.pointer.hide()
	# Movie capture includes the normal game mix, without affecting saved volumes.
	var capture_audio := CaptureAudio.new()
	capture_audio.music = game.get_node("PlanetMusic")
	capture_audio.process_priority = 100
	game.add_child(capture_audio)
	game.get_node("GameAudio").enabled = true
	game.get_node("PlanetMusic").volume_db = -16
	game.preferences.muted = false
	game.preferences.volume = 80
	game.preferences.music_volume = 85
	game.preferences.sfx_volume = 75
	game.preferences.apply_audio()
	AudioServer.set_bus_mute(0,false)
	previous_health = game.player.health
	var pause_frames := 0
	for frame in int(LENGTH*FPS):
		var t := float(frame)/FPS
		game.get_node("Camera2D").position = game.player.position
		if game.player.health < previous_health: damage_taken += previous_health-game.player.health
		previous_health = game.player.health
		if game.state == "death":
			pause_frames += 1
			game.controls.touch_move = Vector2.ZERO
			if pause_frames >= 30:
				deaths += 1
				game.continue_after_death()
				pause_frames = 0
		elif game.state == "playing":
			var pos: Vector2 = game.player.position
			var center: Vector2 = game.arena.get_center()
			var destination := center+Vector2(cos(t*.31)*310,sin(t*.31)*210)
			if frame%9 == 0: route = game.get_node("Arena").route(pos,destination,14)
			while not route.is_empty() and pos.distance_to(route[0]) < 25: route.remove_at(0)
			var move: Vector2 = pos.direction_to(route[0]) if not route.is_empty() else pos.direction_to(destination)
			var danger := Vector2.ZERO
			for bullet in game.bullets.get_children():
				if bullet.hostile:
					var offset: Vector2 = pos-bullet.position
					if offset.length_squared() < 85*85: danger += offset.normalized()*.15
			game.controls.touch_move = (move+danger.limit_length(.7)).normalized()
			var target: Node2D
			var nearest := INF
			for enemy in game.enemies.get_children():
				if enemy.is_queued_for_deletion() or enemy.boss and t < 70: continue
				var distance: float = pos.distance_squared_to(enemy.position)
				if distance < nearest: nearest = distance; target = enemy
			if target == null and is_instance_valid(game.boss_ref): target = game.boss_ref
			if t > 75 and is_instance_valid(game.boss_ref) and not game.boss_ref.is_queued_for_deletion(): target = game.boss_ref
			var aim: Vector2 = pos.direction_to(target.position) if is_instance_valid(target) else Vector2.RIGHT
			game.controls.touch_aim = aim
			var pointer: Vector2 = game.get_viewport().get_canvas_transform()*(pos+aim*230)
			pointer = pointer.clamp(Vector2(24,110),Vector2(1128,675))
			cursor.position = pointer-Vector2(16,16)
			Input.warp_mouse(pointer)
			Input.action_release("dash")
			if frame%45 == 0 and game.player.dash_cd <= 0: Input.action_press("dash")
			if frame == 6*FPS: game.player.rewind(); summary.eco = not game.player.echo_frames.is_empty()
			if frame == 8*FPS: summary.bomb = game.loot.use_slot(0)
			if frame == 12*FPS: summary.overdrive = game.loot.use_slot(1)
			if frame == 18*FPS: supply("shield")
			if frame == 20*FPS: summary.berserk = game.activate_berserk()
			if frame == 10*FPS: summary.original = game.player.equip_weapon("original")
			if frame == 18*FPS: summary.shotgun = game.player.equip_weapon("shotgun")
			if frame == 24*FPS: supply("bomb")
			if frame == 27*FPS: supply("medkit")
			if frame in [2*FPS,10*FPS,16*FPS,24*FPS]: device({2:"mine",10:"turret",16:"beacon",24:"mine"}[int(t)])
			if frame in [10*FPS,22*FPS]: game.weather.start_event()
		else:
			game.controls.touch_move = Vector2.ZERO
			game.controls.touch_aim = Vector2.ZERO
			if game.state == "cleared":
				game.controls.touch_move = game.player.position.direction_to(game.portal)
				if game.player.position.distance_to(game.portal) < game.EXTRACTION_RANGE: game.board_after_clear()
			elif game.state == "shop": game.leave_shop()
		await process_frame
		if frame%300 == 0: print("VIDEO "+str(int(t))+"s / HP "+str(game.player.health)+" / mobs "+str(game.enemies.get_child_count()))
	Input.action_release("dash")
	summary["damage_taken"] = damage_taken
	summary["continues"] = deaths
	summary["final_state"] = game.state
	summary["kills"] = game.kills
	summary["seconds"] = LENGTH
	summary["staged"] = "Scripted demonstration: maximum attributes and modules, supplied consumables/devices, extended horde and doubled final boss health; damage and lives remain active. No profile is saved."
	DirAccess.make_dir_recursive_absolute("res://builds/media")
	var report := FileAccess.open("res://builds/media/showcase-report.json",FileAccess.WRITE)
	report.store_string(JSON.stringify(summary,"\t"))
	report.close()
	print("SHOWCASE RESULT "+JSON.stringify(summary))
	quit()
