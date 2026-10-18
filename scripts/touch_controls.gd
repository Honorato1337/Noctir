extends Control

const ABILITY_ICONS = {"berserk":preload("res://assets/icons/berserk.svg"),"rewind":preload("res://assets/icons/echo.svg")}
const SlotFrame = preload("res://scripts/pixel_slot.gd")
var game: Node2D
var fingers: Dictionary = {}
var left_id := -1
var right_id := -1
var left_offset := Vector2.ZERO
var right_offset := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func left_center() -> Vector2:
	return Vector2(110, size.y - 100)
func right_center() -> Vector2:
	return Vector2(size.x - 120, size.y - 100)
func buttons() -> Dictionary:
	return {"dash": Vector2(size.x - 65, size.y - 240), "rewind": Vector2(size.x - 170, size.y - 245), "berserk": Vector2(size.x - 270, size.y - 235), "interact": Vector2(size.x - 65, size.y - 340), "pause": Vector2(size.x - 38, 116), "slot_one": Vector2(size.x * 0.5 - 95, size.y - 66), "slot_two": Vector2(size.x * 0.5, size.y - 66), "slot_three": Vector2(size.x * 0.5 + 95, size.y - 66)}

func release_all() -> void:
	for action: String in fingers.values():
		if action not in ["move", "aim"]: Input.action_release(action)
	fingers.clear()
	left_id = -1
	right_id = -1
	left_offset = Vector2.ZERO
	right_offset = Vector2.ZERO
	if is_instance_valid(game):
		game.controls.touch_move = Vector2.ZERO
		game.controls.touch_aim = Vector2.ZERO

func _process(_delta: float) -> void:
	visible = is_instance_valid(game) and game.controls.touch_enabled() and game.state in ["playing", "cleared", "exit"]
	if not visible and not fingers.is_empty(): release_all()
	queue_redraw()

func update_stick(index: int, point: Vector2) -> void:
	if index == left_id:
		left_offset = (point-left_center()).limit_length(64)
		game.controls.touch_move = left_offset / 64 if left_offset.length() > 10 else Vector2.ZERO
	if index == right_id:
		right_offset = (point-right_center()).limit_length(64)
		game.controls.touch_aim = right_offset / 64 if right_offset.length() > 10 else Vector2.ZERO

func _input(event: InputEvent) -> void:
	if not is_instance_valid(game) or not game.controls.touch_enabled() or game.state not in ["playing", "cleared", "exit"]: return
	if event is InputEventScreenTouch:
		var point: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		if event.pressed:
			for action: String in buttons():
				if point.distance_to(buttons()[action]) <= 38:
					fingers[event.index] = action
					Input.action_press(action)
					get_viewport().set_input_as_handled()
					return
			if left_id < 0 and point.distance_to(left_center()) < 105:
				left_id = event.index
				fingers[event.index] = "move"
			elif right_id < 0 and point.distance_to(right_center()) < 105:
				right_id = event.index
				fingers[event.index] = "aim"
			update_stick(event.index, point)
		elif fingers.has(event.index):
			var action: String = fingers[event.index]
			fingers.erase(event.index)
			if event.index == left_id:
				left_id = -1
				left_offset = Vector2.ZERO
				game.controls.touch_move = Vector2.ZERO
			elif event.index == right_id:
				right_id = -1
				right_offset = Vector2.ZERO
				game.controls.touch_aim = Vector2.ZERO
			elif not fingers.values().has(action): Input.action_release(action)
		if fingers.has(event.index) or not event.pressed: get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and fingers.has(event.index):
		update_stick(event.index, get_global_transform_with_canvas().affine_inverse() * event.position)
		get_viewport().set_input_as_handled()

func _draw() -> void:
	if not visible or not is_instance_valid(game) or not is_instance_valid(game.player): return
	var color := Color(0.44, 0.9, 0.82, 0.65)
	for center in [left_center(), right_center()]:
		draw_circle(center, 68, Color(0, 0, 0, 0.45))
		draw_arc(center, 68, 0, TAU, 32, color, 3)
	draw_circle(left_center()+left_offset, 23, color)
	draw_circle(right_center()+right_offset, 23, color)
	var labels := {"dash": "DASH", "rewind": "ECO", "berserk": "FÚRIA", "interact": "ROVER", "pause": "II", "slot_one": "1", "slot_two": "2", "slot_three": "3"}
	for action: String in buttons():
		var point: Vector2 = buttons()[action]
		if action in ["slot_one", "slot_two", "slot_three", "rewind"]:
			var charge := 1.0
			if action == "rewind": charge = (1.0-game.echo_cd/game.ENDLESS_ECHO_COOLDOWN) if game.run_mode == "endless" else (1.0 if game.player.rewind_ready else 0.0)
			SlotFrame.paint(self,Rect2(point-Vector2.ONE*32,Vector2.ONE*64),Color("71e4c5"),charge)
		else:
			draw_circle(point, 36, Color(0, 0, 0, 0.65))
			draw_arc(point, 36, 0, TAU, 24, color, 2)
		var text: String = labels[action]
		if action == "interact" and game.state == "cleared":
			text = "IR"
		elif action == "interact" and game.state == "exit":
			text = "IR" if game.extraction_vehicle() == "rocket" else "ROVER"
		if action == "dash" and is_instance_valid(game.player) and game.player.dash_cd > 0:
			text = "%.1f" % game.player.dash_cd
		elif action == "berserk" and is_instance_valid(game.player):
			text = "%.0fs" % game.player.berserk_time if game.player.berserk_time > 0 else ("USADO" if game.berserk_used else "BERS")
		if action in ABILITY_ICONS:
			draw_texture_rect(ABILITY_ICONS[action],Rect2(point-Vector2(10,29),Vector2(20,20)),false)
			point.y += 7
			if game.run_mode == "endless":
				var cd: float = game.berserk_cd if action == "berserk" else game.echo_cd
				text = "%ds" % ceili(cd) if cd > 0 else ("BERS" if action == "berserk" else "ECO")
				if action == "berserk" and game.player.berserk_time > 0: text = "ATIVO"
		if action in ["slot_one", "slot_two", "slot_three"]:
			var kind: String = game.deployables.inventory if action == "slot_three" else game.loot.slots[0 if action == "slot_one" else 1]
			if game.loot.ICONS.has(kind):
				draw_texture_rect(game.loot.ICONS[kind], Rect2(point - Vector2(16, 26), Vector2(32, 32)), false)
			point.y += 18
		draw_string(game.font, point+Vector2(-game.font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x/2, 7), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
