@tool
extends Control

@export var accent := Color("71e4c5")
var charge := 1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func set_charge(value: float) -> void:
	value = clampf(value, 0, 1)
	if int(value * 22) == int(charge * 22): return
	charge = value
	queue_redraw()

func _draw() -> void:
	paint(self, Rect2(Vector2.ZERO, size), accent, charge)

static func paint(canvas: CanvasItem, rect: Rect2, tint: Color = Color("71e4c5"), progress: float = 1.0) -> void:
	# Native, cached drawing: a strict two-pixel grid, matching the astronaut palette.
	canvas.draw_set_transform(rect.position.snapped(Vector2.ONE), 0, rect.size / 64.0)
	canvas.draw_rect(Rect2(4,4,56,56), Color("03050a"))
	canvas.draw_rect(Rect2(10,10,44,44), Color("050810"))
	for rail in [Rect2(10,2,44,8), Rect2(10,54,44,8), Rect2(2,10,8,44), Rect2(54,10,8,44)]:
		canvas.draw_rect(rail, Color("12173d"))
	for rail in [Rect2(12,4,40,2), Rect2(12,58,40,2), Rect2(4,12,2,40), Rect2(58,12,2,40)]:
		canvas.draw_rect(rail, Color("6b74b2"))
	for rail in [Rect2(14,6,36,2), Rect2(6,14,2,36), Rect2(56,14,2,36)]:
		canvas.draw_rect(rail, Color(tint,0.9))
	canvas.draw_rect(Rect2(14,56,36 * clampf(progress,0,1),2), tint)
	for corner in [Vector2(0,0), Vector2(52,0), Vector2(0,52), Vector2(52,52)]:
		canvas.draw_rect(Rect2(corner+Vector2(2,0),Vector2(8,12)), Color("03050a"))
		canvas.draw_rect(Rect2(corner+Vector2(0,2),Vector2(12,8)), Color("03050a"))
		canvas.draw_rect(Rect2(corner+Vector2(2,2),Vector2(8,8)), Color("6b74b2"))
		canvas.draw_rect(Rect2(corner+Vector2(2,2),Vector2(6,2)), Color("c1d9f2"))
		canvas.draw_rect(Rect2(corner+Vector2(4,4),Vector2(6,6)), Color("3b768f"))
		canvas.draw_rect(Rect2(corner+Vector2(4,4),Vector2(4,4)), tint)
		canvas.draw_rect(Rect2(corner+Vector2(4,4),Vector2(2,2)), Color("ffffff"))
	canvas.draw_set_transform(Vector2.ZERO)
