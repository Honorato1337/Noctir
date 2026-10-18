@tool
extends Node2D

const Art = preload("res://scripts/planet_art.gd")
const TILE_SIZE := 256.0

func _ready() -> void:
	var floor_node := get_parent().get_node_or_null("Floor") as ColorRect
	if is_instance_valid(floor_node):
		floor_node.item_rect_changed.connect(queue_redraw)

func _draw() -> void:
	var floor_node := get_parent().get_node_or_null("Floor") as ColorRect
	if not is_instance_valid(floor_node):
		return
	var rect := floor_node.get_rect()
	var sector: int = clampi(int(get_parent().sector_index), 0, 2)
	var texture: Texture2D = Art.GROUNDS[sector]
	for x in ceili(rect.size.x / TILE_SIZE):
		for y in ceili(rect.size.y / TILE_SIZE):
			var at := rect.position + Vector2(x, y) * TILE_SIZE
			var extent := Vector2(minf(TILE_SIZE, rect.end.x - at.x), minf(TILE_SIZE, rect.end.y - at.y))
			var source := Rect2(Vector2.ZERO, extent / TILE_SIZE * texture.get_size())
			draw_texture_rect_region(texture, Rect2(at, extent), source, Color(0.68, 0.68, 0.68))
