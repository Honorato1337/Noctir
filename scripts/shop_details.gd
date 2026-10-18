extends Control

var details: PanelContainer
var description: Label
var keyboard_navigation := false

func _ready() -> void:
	details = PanelContainer.new()
	details.z_index = 100
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.custom_minimum_size.x = 370
	add_child(details)
	description = Label.new()
	description.custom_minimum_size.x = 330
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 22)
	description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(description)
	details.hide()
	for control in find_children("*", "Control", true, false):
		if control is Button or control.name.begins_with("StoreSlot"):
			control.mouse_entered.connect(show_details.bind(control))
			control.mouse_exited.connect(details.hide)
			control.focus_entered.connect(func():
				if keyboard_navigation:
					show_details(control))
			control.focus_exited.connect(details.hide)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		keyboard_navigation = true
	elif event is InputEventMouseMotion:
		if keyboard_navigation:
			details.hide()
		keyboard_navigation = false

func refresh_details() -> void:
	details.hide()
	for control in find_children("*", "Control", true, false):
		if not control.tooltip_text.is_empty():
			control.set_meta("specifications", control.tooltip_text)
			control.tooltip_text = ""

func show_details(control: Control) -> void:
	# Move native tooltip text into this shared, keyboard-accessible popup.
	if not control.tooltip_text.is_empty():
		control.set_meta("specifications", control.tooltip_text)
		control.tooltip_text = ""
	description.text = control.get_meta("specifications", "")
	if description.text.is_empty():
		details.hide()
		return
	details.reset_size()
	var at := control.get_global_rect().end + Vector2(-control.size.x, 8)
	var bounds := get_viewport_rect().size
	at.x = clampf(at.x, 16, bounds.x - 390)
	at.y = minf(at.y, bounds.y - details.size.y - 16)
	details.global_position = at
	details.show()
