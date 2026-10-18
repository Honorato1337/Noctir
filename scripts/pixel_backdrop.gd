@tool
extends ColorRect

@export var accent := Color("70e6d1"):
	set(value):
		accent = value
		queue_redraw()

func _draw() -> void:
	for x in range(0, int(size.x), 32):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(accent, 0.035), 1)
	for y in range(0, int(size.y), 32):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(accent, 0.035), 1)
	for i in 64:
		var at := Vector2(int(fmod(i * 173.0 + 20, maxf(size.x, 1))) / 4 * 4, int(fmod(i * 97.0 + 12, maxf(size.y, 1))) / 4 * 4)
		draw_rect(Rect2(at, Vector2(4, 4)), Color(accent, 0.20))
	for y in range(0, int(size.y), 8):
		draw_rect(Rect2(0, y, size.x, 2), Color(0, 0, 0, 0.09))
	for corner in [Vector2(32, 32), Vector2(size.x - 32, 32), Vector2(32, size.y - 32), size - Vector2(32, 32)]:
		draw_rect(Rect2(corner - Vector2(8, 2), Vector2(16, 4)), accent)
		draw_rect(Rect2(corner - Vector2(2, 8), Vector2(4, 16)), accent)
