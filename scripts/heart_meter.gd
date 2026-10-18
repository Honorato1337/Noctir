@tool
extends Control

const PIXELS := ["01100110", "11111111", "11111111", "11111111", "01111110", "00111100", "00011000"]
var current := 5
var maximum := 5
var damage_flash := 0.0
var clock := 0.0
var active := true

func set_health(value: int, capacity: int) -> void:
	value = clampi(value, 0, capacity)
	if value == current and capacity == maximum:
		return
	if value < current:
		damage_flash = 0.45
	current = value
	maximum = maxi(1, capacity)
	queue_redraw()

func _process(delta: float) -> void:
	if active:
		clock += delta
		damage_flash = maxf(0, damage_flash - delta)
	if damage_flash > 0 or current <= 2:
		queue_redraw()

func heart_rects() -> Array[Rect2]:
	if maximum > 42:
		var compact: Array[Rect2] = [Rect2(0, 18, 32, 28)]
		return compact
	var scale_px := 4 if maximum <= 14 else (3 if maximum <= 20 else 2)
	var gap := 4 if scale_px == 4 else 2
	var heart_size := Vector2(8, 7) * scale_px
	var pitch := heart_size + Vector2(gap, gap)
	var columns := maxi(1, int((size.x + gap) / pitch.x))
	var rows := ceili(float(maximum) / columns)
	var top := maxf(0, floorf((size.y - rows * pitch.y + gap) / 2))
	var result: Array[Rect2] = []
	for i in maximum:
		result.append(Rect2(Vector2((i % columns) * pitch.x, top + (i / columns) * pitch.y), heart_size))
	return result

func _draw() -> void:
	if current <= 2 or damage_flash > 0:
		var intensity := 0.2 + (sin(clock * 7) + 1) * 0.15 if current <= 2 else 0.1
		draw_rect(Rect2(Vector2(-6, -2), size + Vector2(12, 4)), Color(0.85, 0.08, 0.16, intensity))
		draw_rect(Rect2(Vector2(-6, -2), size + Vector2(12, 4)), Color("ff7285"), false, 2)
	if maximum > 42:
		draw_string(get_theme_default_font(), Vector2(44, 42), "%d / %d" % [current, maximum], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("ffbdc6"))
	var rects := heart_rects()
	for i in rects.size():
		var rect: Rect2 = rects[i]
		var scale_px: float = rect.size.x / 8
		var color := Color("ff526f") if i < current else Color("38424e")
		if damage_flash > 0 and i < current:
			color = Color("fff0e4")
		for y in PIXELS.size():
			for x in PIXELS[y].length():
				if PIXELS[y][x] == "1":
					draw_rect(Rect2(rect.position + Vector2(x, y) * scale_px, Vector2.ONE * scale_px), color)
		if i < current:
			draw_rect(Rect2(rect.position + Vector2(1, 1) * scale_px, Vector2(2, 1) * scale_px), Color("ffbdc6"))
