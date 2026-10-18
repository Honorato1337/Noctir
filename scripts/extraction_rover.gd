extends Node2D
const Vehicles = preload("res://scripts/expedition_vehicles.gd")
const Vfx = preload("res://scripts/pixel_effects.gd")
var game: Node2D
var clock := 0.0
func _process(delta: float) -> void:
	if not is_instance_valid(game): return
	visible = game.state in ["cleared", "exit"] or (game.state == "paused" and game.room_cleared)
	if game.state in ["cleared", "exit"]: clock += delta
	queue_redraw()
func _draw() -> void:
	if not visible or not is_instance_valid(game): return
	var at: Vector2 = game.portal
	draw_rect(Rect2(at+Vector2(-82, 42), Vector2(164, 14)), Color(0.03, 0.04, 0.08, 0.65))
	Vehicles.draw_vehicle(self, game.extraction_vehicle(), at, Vector2(192, 192), int(clock*5)%2 if game.extraction_vehicle() == "rocket" else 0)
	var mint := Color("71e4c5")
	for side in [-1, 1]:
		var point: Vector2 = at + Vector2(side*106, 46)
		draw_line(point, point+Vector2(-side*16, 0), mint, 3)
		draw_line(point, point+Vector2(0,-14), mint, 3)
	Vfx.draw_particle(self, at+Vector2(8,-96), Vector2.ONE*16, 0, int(clock*8)%4, mint)
	var text: String = game.extraction_name() + " / EXTRAÇÃO"
	var width: float = game.font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	var label := Rect2(at+Vector2(-width*0.5-12, -132), Vector2(width+24, 32))
	draw_rect(label, Color("080e20"))
	draw_rect(Rect2(label.position, Vector2(3,label.size.y)), mint)
	draw_string(game.font, label.position+Vector2(12,23), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, mint)
