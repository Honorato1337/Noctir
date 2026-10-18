extends Node2D

const DATA := {
	"mine": {"name": "Mina orbital", "life": 24.0, "color": Color("ffbd70")},
	"turret": {"name": "Torreta", "life": 18.0, "color": Color("91eaff")},
	"beacon": {"name": "Baliza de contenção", "life": 12.0, "color": Color("91ffc4")}
}
const MAX_ACTIVE := 4
var game: Node2D
var inventory := "mine"
var placed: Array[Dictionary] = []
var rings: Array[Dictionary] = []

func reset_run() -> void:
	inventory = "mine"
	clear_room()

func clear_room() -> void:
	placed.clear()
	rings.clear()
	queue_redraw()

func add_item(kind: String) -> bool:
	if not DATA.has(kind) or not inventory.is_empty():
		return false
	inventory = kind
	return true

func place() -> bool:
	if game.state != "playing" or inventory.is_empty():
		return false
	if placed.size() >= MAX_ACTIVE or game.blocked(game.player.position, 18) or not game.arena.grow(-18).has_point(game.player.position):
		game.message = "Afaste-se da cobertura ou aguarde um equipamento expirar."
		game.message_time = 2
		return false
	var kind := inventory
	placed.append({"kind": kind, "pos": game.player.position, "life": DATA[kind].life, "age": 0.0, "cooldown": .65 if kind == "mine" else .15, "damage": game.player.shot_damage(), "aim": Vector2.RIGHT})
	inventory = ""
	game.fx.sparks(game.player.position, DATA[kind].color, 16, 80)
	game.play_sfx("item_pickup", game.player.position)
	queue_redraw()
	return true

func enemy_slowdown(at: Vector2, boss: bool) -> float:
	for device in placed:
		if device.kind == "beacon" and at.distance_to(device.pos) < 185:
			return .8 if boss else .55
	return 1.0

func visible_target(at: Vector2, reach: float) -> Node2D:
	var target: Node2D
	var nearest := reach
	for enemy in game.enemies.get_children():
		if enemy.is_queued_for_deletion():
			continue
		var distance: float = at.distance_to(enemy.position)
		if distance >= nearest:
			continue
		var clear := true
		var direction: Vector2 = at.direction_to(enemy.position)
		for step in range(16, int(distance), 16):
			if game.blocked(at + direction * step, 4):
				clear = false
				break
		if clear:
			target = enemy
			nearest = distance
	return target

func detonate(device: Dictionary) -> void:
	for enemy in game.enemies.get_children():
		if not enemy.is_queued_for_deletion() and enemy.position.distance_to(device.pos) <= 240 + enemy.radius:
			enemy.hurt(device.damage * (32 if enemy.boss else 18))
	game.fx.explosion(device.pos, Color("ffbd70"), 140)
	rings.append({"pos": device.pos, "radius": 240.0, "life": .7, "color": Color("ffbd70")})
	game.play_sfx("bomb", device.pos)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(game) or game.state != "playing":
		return
	if Input.is_action_just_pressed("slot_three"):
		place()
	for index in range(placed.size() - 1, -1, -1):
		var device: Dictionary = placed[index]
		device.age += delta
		device.life -= delta
		device.cooldown -= delta
		if device.life <= 0:
			placed.remove_at(index)
			continue
		if device.cooldown > 0:
			continue
		if device.kind == "mine":
			for enemy in game.enemies.get_children():
				if not enemy.is_queued_for_deletion() and enemy.position.distance_to(device.pos) < 105 + enemy.radius:
					detonate(device)
					placed.remove_at(index)
					break
		elif device.kind == "turret":
			device.cooldown = .3
			var target := visible_target(device.pos, 460)
			if is_instance_valid(target):
				device.aim = device.pos.direction_to(target.position)
				game.shoot(device.pos, device.aim, device.damage * .8 + 1, false)
				game.fx.sparks(device.pos, Color("91eaff"), 3, 50)
		else:
			device.cooldown = 1.2
			for bullet in game.bullets.get_children():
				if bullet.hostile and bullet.position.distance_to(device.pos) < 185:
					bullet.queue_free()
			rings.append({"pos": device.pos, "radius": 185.0, "life": .65, "color": Color("91ffc4")})
	for index in range(rings.size() - 1, -1, -1):
		rings[index].life -= delta
		if rings[index].life <= 0:
			rings.remove_at(index)
	queue_redraw()

func _draw() -> void:
	for device in placed:
		var at: Vector2 = device.pos.snapped(Vector2(2, 2))
		var color: Color = DATA[device.kind].color
		draw_circle(at + Vector2(0, 5), 20, Color(0, 0, 0, .4))
		draw_rect(Rect2(at - Vector2(14, 10), Vector2(28, 20)), Color("152333"))
		draw_rect(Rect2(at - Vector2(14, 10), Vector2(28, 20)), color, false, 3)
		if device.kind == "turret":
			draw_line(at, at + device.aim * 25, color, 7)
		elif device.kind == "mine":
			draw_circle(at, 5, color if fmod(device.age, .4) < .2 else Color("fff1b8"))
			draw_arc(at, 105, 0, TAU, 36, Color(color, .15), 2)
		else:
			draw_line(at + Vector2(0, -6), at + Vector2(0, -27), color, 5)
			draw_arc(at, 185, device.age, device.age + TAU * .9, 40, Color(color, .35), 2)
		draw_rect(Rect2(at + Vector2(-15, 20), Vector2(30 * device.life / DATA[device.kind].life, 3)), color)
	for ring in rings:
		draw_arc(ring.pos, ring.radius * (1 - ring.life / .7), 0, TAU, 56, Color(ring.color, ring.life), 5)
