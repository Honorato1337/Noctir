@tool
extends ColorRect

const Terrain = preload("res://scripts/planet_terrain.gd")

func _ready() -> void:
	color = Color.TRANSPARENT
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	resized.connect(queue_redraw)

func _draw() -> void:
	var arena := get_parent().get_parent()
	var sector: int = arena.sector_index
	# Original scene rectangles remain the single source for actor/projectile
	# collision and navigation; the rock mass fills that same footprint.
	Terrain.draw_rock(self, Rect2(Vector2.ZERO, size), sector, get_index())
