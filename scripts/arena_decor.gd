@tool
extends Node2D

const Terrain = preload("res://scripts/planet_terrain.gd")

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var floor_node := get_parent().get_node_or_null("Floor") as ColorRect
	if is_instance_valid(floor_node):
		floor_node.item_rect_changed.connect(queue_redraw)
	var border := get_parent().get_node_or_null("Border")
	if border != null: border.visible = false

func _draw() -> void:
	var floor_node := get_parent().get_node_or_null("Floor") as ColorRect
	if not is_instance_valid(floor_node): return
	var bounds := floor_node.get_rect()
	var sector: int = get_parent().sector_index
	Terrain.draw_floor(self, bounds, sector)
	Terrain.draw_walls(self, bounds, sector)
