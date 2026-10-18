@tool
extends Node2D

@export var layout_name := "MARTE / COLONIA FERRUGEM"
@export_range(0, 3) var sector_index := 0
var navigation := AStarGrid2D.new()
var boss_navigation := AStarGrid2D.new()

# Geometry is authored in arena.tscn and shared by visuals and collision.
func apply_to(game: Node2D) -> void:
	game.arena = $Floor.get_global_rect()
	game.obstacles.clear()
	for cover in $Obstacles.get_children():
		game.obstacles.append(cover.get_global_rect())
		cover.color = Color.TRANSPARENT
		cover.queue_redraw()
	game.hazards.clear()
	if game.planet_index == 1:
		for marker in $Hazards.get_children():
			game.hazards.append(marker.global_position)
	game.portal = $Portal.global_position.clamp(game.arena.position + Vector2.ONE*112, game.arena.end - Vector2.ONE*112)
	game.player.position = $PlayerSpawn.global_position
	$Floor.color = game.planet().floor
	$Border.visible = false
	$FloorDetails.queue_redraw()
	$Border.default_color = Color(game.planet().accent, 0.6)
	var rect: Rect2 = $Floor.get_rect()
	$Border.points = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y), rect.position])
	build_navigation(game, navigation, 16)
	build_navigation(game, boss_navigation, 46)

func spawn_gates() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for marker in $SpawnGates.get_children():
		result.append(marker.global_position)
	return result

func build_navigation(game: Node2D, grid: AStarGrid2D, clearance: float) -> void:
	grid.region = Rect2i(0, 0, int(game.arena.size.x / 32), int(game.arena.size.y / 32))
	grid.cell_size = Vector2(32, 32)
	grid.offset = game.arena.position + Vector2(16, 16)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for x in grid.region.size.x:
		for y in grid.region.size.y:
			var cell := Vector2i(x, y)
			var point := grid.get_point_position(cell)
			var solid: bool = not game.arena.grow(-clearance).has_point(point)
			for obstacle in game.obstacles:
				if obstacle.grow(clearance + 8).has_point(point):
					solid = true
			grid.set_point_solid(cell, solid)

func nearest_open(point: Vector2, grid: AStarGrid2D) -> Vector2i:
	var cell := Vector2i(((point - grid.offset) / grid.cell_size).round())
	cell = cell.clamp(grid.region.position, grid.region.end - Vector2i.ONE)
	if not grid.is_point_solid(cell):
		return cell
	var nearest := cell
	var nearest_distance := INF
	for x in grid.region.size.x:
		for y in grid.region.size.y:
			var candidate := Vector2i(x, y)
			var distance := grid.get_point_position(candidate).distance_squared_to(point)
			if distance < nearest_distance and not grid.is_point_solid(candidate):
				nearest = candidate
				nearest_distance = distance
	return nearest

func route(origin: Vector2, target: Vector2, radius: float = 14.0) -> PackedVector2Array:
	var grid := boss_navigation if radius > 20 else navigation
	return grid.get_point_path(nearest_open(origin, grid), nearest_open(target, grid))
