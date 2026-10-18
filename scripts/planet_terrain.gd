@tool
extends RefCounted

const PixelArt = preload("res://scripts/pixel_art_import.gd")
const ATLAS_PATH := "res://assets/environment/planet_terrain_atlas-v2.png"
const FLOOR_SIZE := 64.0
const WALL_LENGTH := 64.0
const WALL_DEPTH := 48.0
const FLOOR_PATH := "res://assets/environment/floor_tiles-v3.png"
static var floor_atlas: Texture2D
static var atlas: Texture2D

static func texture() -> Texture2D:
	if atlas == null and ResourceLoader.exists(ATLAS_PATH):
		atlas = PixelArt.texture(ATLAS_PATH, Vector2i(128,128), PixelArt.PLANET_PALETTES, 4)
	return atlas

static func cell(sector: int, column: int) -> Rect2:
	var source := texture()
	var size: float = source.get_width() / 4.0 if source != null else 256.0
	return Rect2(column * size, clampi(sector, 0, 3) * size, size, size)

static func floor_texture() -> Texture2D:
	if floor_atlas == null:
		floor_atlas = PixelArt.texture(FLOOR_PATH,Vector2i(64,64),PixelArt.FLOOR_PALETTES,2,2)
	return floor_atlas

static func draw_floor(canvas: CanvasItem, bounds: Rect2, sector: int) -> void:
	canvas.draw_rect(bounds,PixelArt.FLOOR_PALETTES[sector][0])
	var source := floor_texture()
	if source == null: return
	var cell_size := source.get_size()/2
	var region := Rect2(Vector2(sector%2,sector/2)*cell_size,cell_size)
	for y in range(ceili(bounds.size.y/FLOOR_SIZE)):
		for x in range(ceili(bounds.size.x/FLOOR_SIZE)):
			var at := bounds.position+Vector2(x,y)*FLOOR_SIZE
			var size := Vector2(minf(FLOOR_SIZE,bounds.end.x-at.x),minf(FLOOR_SIZE,bounds.end.y-at.y))
			var angle := posmod(x*7+y*11+sector,4)*PI/2 if size == Vector2.ONE*FLOOR_SIZE else 0.0
			canvas.draw_set_transform(at+size*0.5,angle)
			canvas.draw_texture_rect_region(source,Rect2(-size*0.5,size),Rect2(region.position,region.size*size/FLOOR_SIZE),Color(0.8,0.8,0.8,1))
	canvas.draw_set_transform(Vector2.ZERO)

static var crops: Dictionary = {}
static func art_region(sector: int, column: int) -> Rect2:
	var key := sector*4+column
	if not crops.has(key):
		var area := cell(sector,column)
		if column == 2: area.size.x -= 4 # Exclude the neighbouring wall segment.
		var used := texture().get_image().get_region(Rect2i(area)).get_used_rect()
		crops[key] = Rect2(area.position+Vector2(used.position),Vector2(used.size)) if used.has_area() else area
	return crops[key]

static func draw_rock(canvas: CanvasItem, bounds: Rect2, sector: int, variant: int = 0) -> void:
	var source := texture()
	if source == null: return
	# Long cover rectangles become interlocking stones instead of stretching
	# a square boulder into an obelisk. Each piece keeps a near-square ratio.
	var columns := maxi(1, ceili(bounds.size.x / maxf(64, bounds.size.y * 1.25)))
	var rows := maxi(1, ceili(bounds.size.y / maxf(64, bounds.size.x * 1.25)))
	var piece_size := bounds.size / Vector2(columns, rows)
	for y in rows:
		for x in columns:
			var piece := Rect2(bounds.position + Vector2(x, y) * piece_size, piece_size)
			canvas.draw_texture_rect_region(source, piece, art_region(sector, 1 + posmod(variant + x + y, 2)))

static func draw_walls(canvas: CanvasItem, bounds: Rect2, sector: int) -> void:
	var source := texture()
	if source == null: return
	var region := art_region(sector, 3)
	# The atlas wall occupies the central 3/4 of its cell; all walls sit outside
	# the playable rectangle, so the visible inside edge matches arena collision.
	for x in range(ceili(bounds.size.x / WALL_LENGTH)):
		var length := minf(WALL_LENGTH, bounds.size.x - x * WALL_LENGTH)
		var piece := Rect2(region.position, Vector2(region.size.x * length / WALL_LENGTH, region.size.y))
		for y: float in [bounds.position.y - WALL_DEPTH, bounds.end.y]:
			canvas.draw_texture_rect_region(source, Rect2(bounds.position.x + x * WALL_LENGTH, y, length, WALL_DEPTH), piece)
	for y in range(ceili(bounds.size.y / WALL_LENGTH)):
		var length := minf(WALL_LENGTH, bounds.size.y - y * WALL_LENGTH)
		var piece := Rect2(region.position, Vector2(region.size.x * length / WALL_LENGTH, region.size.y))
		for x: float in [bounds.position.x, bounds.end.x + WALL_DEPTH]:
			canvas.draw_set_transform(Vector2(x, bounds.position.y + y * WALL_LENGTH), PI / 2)
			canvas.draw_texture_rect_region(source, Rect2(0, 0, length, WALL_DEPTH), piece)
	canvas.draw_set_transform(Vector2.ZERO)
	for corner: Vector2 in [bounds.position - Vector2.ONE * WALL_DEPTH, Vector2(bounds.end.x, bounds.position.y - WALL_DEPTH), Vector2(bounds.position.x - WALL_DEPTH, bounds.end.y), bounds.end]:
		draw_rock(canvas, Rect2(corner, Vector2.ONE * WALL_DEPTH), sector)
