extends Node

const DEFAULT_KEYS := {"left": KEY_A, "right": KEY_D, "up": KEY_W, "down": KEY_S, "aim_left": KEY_LEFT, "aim_right": KEY_RIGHT, "aim_up": KEY_UP, "aim_down": KEY_DOWN, "fire": 0, "dash": KEY_SPACE, "rewind": KEY_Q, "interact": KEY_E, "pause": KEY_ESCAPE, "restart": KEY_R, "slot_one": KEY_1, "slot_two": KEY_2, "slot_three": KEY_3, "berserk": KEY_F}
const LABELS := {"left": "Andar: esquerda", "right": "Andar: direita", "up": "Andar: cima", "down": "Andar: baixo", "aim_left": "Tiro: esquerda", "aim_right": "Tiro: direita", "aim_up": "Tiro: cima", "aim_down": "Tiro: baixo", "fire": "Atirar / mouse", "dash": "Dash", "rewind": "Eco", "interact": "Extrair", "pause": "Pausa", "restart": "Reiniciar", "slot_one": "Item 1", "slot_two": "Item 2", "slot_three": "Equipamento", "berserk": "Berserk"}
var game: Node2D
var last_device := "keyboard"
var touch_move := Vector2.ZERO
var touch_aim := Vector2.ZERO

func touch_enabled() -> bool:
	return game.preferences.touch_mode == 1 or (game.preferences.touch_mode == 0 and (OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()))

func key_for(action: String) -> int:
	if game.preferences.keybinds.has(action): return int(game.preferences.keybinds[action])
	if game.preferences.keyboard_preset == 1:
		var swapped := {"left": KEY_LEFT, "right": KEY_RIGHT, "up": KEY_UP, "down": KEY_DOWN, "aim_left": KEY_A, "aim_right": KEY_D, "aim_up": KEY_W, "aim_down": KEY_S}
		if swapped.has(action): return swapped[action]
	return DEFAULT_KEYS.get(action, 0)

func key_text(action: String) -> String:
	var code := key_for(action)
	return OS.get_keycode_string(code) if code > 0 else ("MOUSE" if action == "fire" else "SEM TECLA")

func configure() -> void:
	for action: String in DEFAULT_KEYS:
		if not InputMap.has_action(action): InputMap.add_action(action, 0.22)
		InputMap.action_set_deadzone(action, 0.22)
		InputMap.action_erase_events(action)
		var code := key_for(action)
		if code > 0:
			var key := InputEventKey.new()
			key.physical_keycode = code
			InputMap.action_add_event(action, key)
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("fire", mouse)
	var buttons := {"dash": JOY_BUTTON_A, "rewind": JOY_BUTTON_LEFT_SHOULDER, "interact": JOY_BUTTON_X, "pause": JOY_BUTTON_START, "slot_one": JOY_BUTTON_Y, "slot_two": JOY_BUTTON_B, "slot_three": JOY_BUTTON_RIGHT_SHOULDER}
	for action: String in buttons:
		var button := InputEventJoypadButton.new()
		button.device = -1
		button.button_index = buttons[action]
		InputMap.action_add_event(action, button)
	for spec: Array in [["left", JOY_AXIS_LEFT_X, -1.0], ["right", JOY_AXIS_LEFT_X, 1.0], ["up", JOY_AXIS_LEFT_Y, -1.0], ["down", JOY_AXIS_LEFT_Y, 1.0], ["aim_left", JOY_AXIS_RIGHT_X, -1.0], ["aim_right", JOY_AXIS_RIGHT_X, 1.0], ["aim_up", JOY_AXIS_RIGHT_Y, -1.0], ["aim_down", JOY_AXIS_RIGHT_Y, 1.0], ["fire", JOY_AXIS_TRIGGER_RIGHT, 1.0], ["berserk", JOY_AXIS_TRIGGER_LEFT, 1.0]]:
		var axis := InputEventJoypadMotion.new()
		axis.device = -1
		axis.axis = spec[1]
		axis.axis_value = spec[2]
		InputMap.action_add_event(spec[0], axis)

	# Explicit menu mappings also work when the editor project has no input presets.
	var ui_buttons := {"ui_accept": JOY_BUTTON_A, "ui_cancel": JOY_BUTTON_B, "ui_up": JOY_BUTTON_DPAD_UP, "ui_down": JOY_BUTTON_DPAD_DOWN, "ui_left": JOY_BUTTON_DPAD_LEFT, "ui_right": JOY_BUTTON_DPAD_RIGHT, "ui_focus_next": JOY_BUTTON_RIGHT_SHOULDER, "ui_focus_prev": JOY_BUTTON_LEFT_SHOULDER}
	for action: String in ui_buttons:
		for existing: InputEvent in InputMap.action_get_events(action):
			if existing is InputEventJoypadButton or existing is InputEventJoypadMotion:
				InputMap.action_erase_event(action, existing)
		var button := InputEventJoypadButton.new()
		button.device = -1
		button.button_index = ui_buttons[action]
		InputMap.action_add_event(action, button)
	for spec: Array in [["ui_left", JOY_AXIS_LEFT_X, -1.0], ["ui_right", JOY_AXIS_LEFT_X, 1.0], ["ui_up", JOY_AXIS_LEFT_Y, -1.0], ["ui_down", JOY_AXIS_LEFT_Y, 1.0]]:
		var axis := InputEventJoypadMotion.new()
		axis.device = -1
		axis.axis = spec[1]
		axis.axis_value = spec[2]
		InputMap.action_add_event(spec[0], axis)

func rebind(action: String, code: int) -> void:
	var old := key_for(action)
	for other: String in DEFAULT_KEYS:
		if other != action and key_for(other) == code:
			game.preferences.keybinds[other] = old
	game.preferences.keybinds[action] = code
	configure()

func movement() -> Vector2:
	return touch_move if touch_move.length_squared() > 0 else Input.get_vector("left", "right", "up", "down")

func aiming() -> Vector2:
	return touch_aim if touch_aim.length_squared() > 0 else Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")

func wants_fire() -> bool:
	return Input.is_action_pressed("fire") and (not touch_enabled() or last_device == "joypad")

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.25): last_device = "joypad"
	elif event is InputEventScreenTouch or event is InputEventScreenDrag: last_device = "touch"
	elif event is InputEventKey or (event is InputEventMouseMotion and not touch_enabled()): last_device = "keyboard"

func hint(action: String) -> String:
	if last_device == "joypad":
		return {"dash": "A", "rewind": "LB", "berserk": "LT", "interact": "X", "pause": "START", "slot_one": "Y", "slot_two": "B", "slot_three": "RB"}.get(action, "RT")
	return key_text(action)

func tutorial() -> String:
	if last_device == "joypad":
		return "ANALÓGICO ESQ: ANDAR / DIREITO: MIRAR E ATIRAR / A: DASH\nLB: ECO / LT: BERSERK / Y,B: ITENS / RB: EQUIPAMENTO / X: EXTRAIR / START: PAUSA"
	return "[%s %s %s %s] ANDAR / MOUSE OU TECLAS DE TIRO / [%s] DASH\n[%s] ECO / [%s] BERSERK / [%s,%s] ITENS / [%s] EQUIPAMENTO / [%s] EXTRAIR / [%s] PAUSA" % [key_text("up"), key_text("left"), key_text("down"), key_text("right"), hint("dash"), hint("rewind"), hint("berserk"), hint("slot_one"), hint("slot_two"), hint("slot_three"), hint("interact"), hint("pause")]
