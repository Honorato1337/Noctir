extends Node2D

const Economy = preload("res://scripts/economy.gd")

const ITEMS = {
	"medkit": {"name": "Kit médico", "short": "+", "color": Color("81edac")},
	"bomb": {"name": "Bomba orbital", "short": "B", "color": Color("ffb676")},
	"shield": {"name": "Escudo", "short": "E", "color": Color("78d6ff")},
	"overdrive": {"name": "Sobrecarga", "short": "S", "color": Color("dda2ff")},
	"mine": {"name": "Mina orbital", "short": "M", "color": Color("ffbd70")},
	"turret": {"name": "Torreta", "short": "T", "color": Color("91eaff")},
	"beacon": {"name": "Baliza de contenção", "short": "C", "color": Color("91ffc4")}
}
const BOMB_STEP := 120.0
const BOMB_RADIUS := 360.0
const BOMB_TARGET_CAP := 12
const BOMB_BASE_DAMAGE := 12.0
var bomb_pulses: Array[Dictionary] = []

const ITEM_DROP_CHANCE := 0.025
const ICONS = {
	"medkit": preload("res://assets/icons/medkit.svg"),
	"bomb": preload("res://assets/icons/bomb.svg"),
	"shield": preload("res://assets/icons/shield.svg"),
	"overdrive": preload("res://assets/icons/overdrive.svg"),
	"mine": preload("res://assets/icons/mine.svg"),
	"turret": preload("res://assets/icons/turret.svg"),
	"beacon": preload("res://assets/icons/beacon.svg")
}
var game: Node2D
var coins := 0
var slots: Array[String] = ["", ""]
var drops: Array[Dictionary] = []
var clock := 0.0

func reset_run() -> void:
	coins = 0
	slots = ["", ""]
	drops.clear()
	bomb_pulses.clear()
	queue_redraw()

func enemy_died(at: Vector2, boss: bool) -> void:
	if boss or game.rng.randf() < Economy.COIN_CHANCE:
		var value: int = 12 + game.room if boss else Economy.coin_value(game.rng)
		if boss and (game.room + 1) % game.ARENAS_PER_PLANET == 0:
			value += 12
		drops.append({"pos": at, "type": "coin", "value": value, "age": 0.0, "boss": boss})
	if game.rng.randf() < ITEM_DROP_CHANCE:
		var kinds := ["medkit", "bomb", "shield", "overdrive"]
		drop_item(at + Vector2(12, 0), kinds[game.rng.randi_range(0, kinds.size() - 1)])
	if game.rng.randf() < .012:
		var devices := ["mine", "turret", "beacon"]
		drop_item(at + Vector2(-12, 0), devices[game.rng.randi_range(0, 2)])
	queue_redraw()

func drop_item(at: Vector2, kind: String) -> void:
	drops.append({"pos": at, "type": kind, "value": 0})
	queue_redraw()

func add_item(kind: String) -> bool:
	if game.deployables.DATA.has(kind):
		return game.deployables.add_item(kind)
	if not ITEMS.has(kind):
		return false
	for index in 2:
		if slots[index].is_empty():
			slots[index] = kind
			return true
	return false

func use_slot(index: int) -> bool:
	if game.state not in ["playing", "cleared", "exit"] or index < 0 or index >= 2 or slots[index].is_empty():
		return false
	var kind: String = slots[index]
	if kind == "medkit" and game.player.health >= game.player.max_health:
		game.message = "Vida cheia: kit preservado."
		game.message_time = 2
		return false
	slots[index] = ""
	game.play_sfx("heal" if kind == "medkit" else kind)
	match kind:
		"medkit": game.player.health = mini(game.player.max_health, game.player.health + 3 + game.progression.prestige_cycles)
		"shield": game.player.immunity = maxf(game.player.immunity, 5.0)
		"overdrive": game.player.overdrive_time = 9.0
		"bomb":
			detonate_bomb()
			game.flash = 0.5
			game.fx.explosion(game.player.position, Color("ffb676"), 120)
	game.fx.explosion(game.player.position, ITEMS[kind].color, 36)
	game.message = ITEMS[kind].name + " ativado!"
	game.message_time = 2
	return true

func bomb_factor(distance: float) -> float:
	if distance > BOMB_RADIUS: return 0.0
	if distance <= BOMB_STEP: return 1.0
	return 0.5 if distance <= BOMB_STEP*2 else 0.25

func detonate_bomb() -> void:
	var origin: Vector2 = game.player.position
	var targets: Array[Dictionary] = []
	for enemy in game.enemies.get_children():
		if enemy.is_queued_for_deletion() or enemy.health <= 0: continue
		var distance: float = origin.distance_to(enemy.position)
		if distance <= BOMB_RADIUS: targets.append({"enemy":enemy,"distance":distance})
	targets.sort_custom(func(a,b): return a.distance < b.distance)
	for index in mini(BOMB_TARGET_CAP,targets.size()):
		var target: Dictionary = targets[index]
		target.enemy.hurt(BOMB_BASE_DAMAGE * game.player.shot_damage() * bomb_factor(target.distance))
	for bullet in game.bullets.get_children():
		if bullet.hostile and not bullet.is_queued_for_deletion() and origin.distance_to(bullet.position) <= BOMB_RADIUS:
			bullet.queue_free()
	if bomb_pulses.size() >= 3: bomb_pulses.pop_front()
	bomb_pulses.append({"pos":origin,"life":0.45})
	queue_redraw()

func collect(index: int, allow_bonus: bool = true) -> bool:
	var drop: Dictionary = drops[index]
	if drop.type == "coin":
		var quick: bool = allow_bonus and float(drop.get("age", 0.0)) <= Economy.QUICK_WINDOW and game.state == "playing"
		var value: int = int(drop.value) + (1 if quick else 0)
		coins += value
		game.play_sfx("coin_bonus" if quick or int(drop.value) >= 5 else "coin", drop.pos)
		game.fx.sparks(drop.pos, Color("ffdf72"), 5, 70)
		if quick:
			game.contracts.record("quick")
			game.fx.floating(drop.pos, "+%d RÁPIDO" % value, Color("71e4c5"))
	elif not add_item(drop.type):
		return false
	else:
		game.play_sfx("item_pickup", drop.pos)
		game.fx.floating(drop.pos, ITEMS[drop.type].name, ITEMS[drop.type].color)
	drops.remove_at(index)
	return true

func collect_remaining() -> void:
	for index in range(drops.size() - 1, -1, -1):
		# Salvage only what has not expired; no quick-pickup bonus in the shop.
		collect(index, false)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.player):
		return
	if game.state not in ["playing", "cleared", "exit"]:
		return
	for i in range(bomb_pulses.size()-1,-1,-1):
		bomb_pulses[i].life -= delta
		if bomb_pulses[i].life <= 0: bomb_pulses.remove_at(i)
	clock += delta
	if Input.is_action_just_pressed("slot_one"):
		if not swap_nearby(0): use_slot(0)
	if Input.is_action_just_pressed("slot_two"):
		if not swap_nearby(1): use_slot(1)
	if game.state in ["cleared", "exit"] and Input.is_action_just_pressed("slot_three"):
		swap_device_nearby()
	for index in range(drops.size() - 1, -1, -1):
		var drop: Dictionary = drops[index]
		if drop.type == "coin" and game.state == "playing":
			drop.age = float(drop.get("age", 0.0)) + delta
			if not drop.get("boss", false) and drop.age >= Economy.COIN_LIFETIME:
				drops.remove_at(index)
				continue
		var distance: float = drop.pos.distance_to(game.player.position)
		var radius: float = (Economy.MAGNET_RADIUS if drop.type == "coin" else 24.0) + game.player.pickup_bonus
		var available: bool = drop.type == "coin" or (game.deployables.inventory.is_empty() if game.deployables.DATA.has(drop.type) else slots.has(""))
		if available and distance < radius:
			drop.pos = drop.pos.move_toward(game.player.position, delta * 360)
		if distance < 24:
			collect(index)
	queue_redraw()

func _draw() -> void:
	for pulse in bomb_pulses:
		for ring in 3:
			draw_arc(pulse.pos,BOMB_STEP*(ring+1),0,TAU,64,Color(1,.65,.3,float(pulse.life)*(0.9-ring*.2)),2)
	for drop in drops:
		var at: Vector2 = drop.pos + Vector2(0, sin(clock * 5 + drop.pos.x) * 2)
		if drop.type == "coin":
			var age: float = drop.get("age", 0.0)
			if game.state == "playing" and not drop.get("boss", false) and age > Economy.COIN_LIFETIME - 2 and int(clock * 10) % 2 == 0:
				continue
			if game.state == "playing" and age <= Economy.QUICK_WINDOW:
				draw_rect(Rect2(at - Vector2(11, 11), Vector2(22, 22)), Color("71e4c5"), false, 1)
			if int(drop.value) >= 5:
				draw_rect(Rect2(at - Vector2(9, 9), Vector2(18, 18)), Color("ffc85c"), false, 2)
			draw_rect(Rect2(at - Vector2(6, 6), Vector2(12, 12)), Color("8b5e35"))
			draw_rect(Rect2(at - Vector2(4, 6), Vector2(8, 10)), Color("ffe292"))
			draw_line(at - Vector2(0, 3), at + Vector2(0, 2), Color("d9a854"), 2)
		else:
			var color: Color = ITEMS[drop.type].color
			draw_rect(Rect2(at - Vector2(18, 18), Vector2(36, 36)), Color(0, 0, 0, 0.85))
			draw_rect(Rect2(at - Vector2(18, 18), Vector2(36, 36)), Color(color, 0.65), false, 2)
			draw_texture_rect(ICONS[drop.type], Rect2(at - Vector2(16, 16), Vector2(32, 32)), false)

func nearby_drop(device: bool = false) -> int:
	if game.state not in ["cleared", "exit"]: return -1
	var nearest := 52.0
	var found := -1
	for index in drops.size():
		var drop: Dictionary = drops[index]
		if drop.type == "coin" or game.deployables.DATA.has(drop.type) != device: continue
		var distance: float = game.player.position.distance_to(drop.pos)
		if distance < nearest:
			nearest = distance
			found = index
	return found

func swap_nearby(slot: int) -> bool:
	if slot < 0 or slot >= slots.size(): return false
	var index := nearby_drop()
	if index < 0: return false
	if slots[slot].is_empty(): return collect(index, false)
	var kind: String = drops[index].type
	drops[index].type = slots[slot]
	drops[index].pos = game.player.position + Vector2(0,30)
	slots[slot] = kind
	game.play_sfx("item_pickup",game.player.position)
	queue_redraw()
	return true

func swap_device_nearby() -> bool:
	var index := nearby_drop(true)
	if index < 0: return false
	if game.deployables.inventory.is_empty(): return collect(index,false)
	var kind: String = drops[index].type
	drops[index].type = game.deployables.inventory
	drops[index].pos = game.player.position + Vector2(0,30)
	game.deployables.inventory = kind
	game.play_sfx("item_pickup",game.player.position)
	queue_redraw()
	return true

func discard_remaining() -> Dictionary:
	var lost := {"coins":0,"items":0}
	for drop in drops:
		if drop.type == "coin": lost.coins += int(drop.value)
		else: lost.items += 1
	drops.clear()
	queue_redraw()
	return lost
