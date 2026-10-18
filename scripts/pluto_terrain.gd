extends RefCounted
# Reuse the established pixel shapes with a separate frozen-world palette.
const PixelArt = preload("res://scripts/pixel_art_import.gd")
const ROCK_COLORS := [Color("141e2d"),Color("26313d"),Color("384552"),Color("526373"),Color("728a9a"),Color("96b7c5"),Color("c4e0e4"),Color("eef8ed")]
const FLOOR_COLORS := [Color("1c2936"),Color("243341"),Color("2c3d4a"),Color("354855"),Color("405561"),Color("4c626b"),Color("182430"),Color("5b737a")]
static var rocks: Texture2D
static var floor_tile: Texture2D

static func recolor(image: Image, old: Array, palette: Array) -> Image:
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x,y)
			if color.a < 0.5: continue
			var best := INF
			var pick := 0
			for index in old.size():
				var difference := Vector3(color.r-old[index].r,color.g-old[index].g,color.b-old[index].b).length_squared()
				if difference < best:
					best = difference
					pick = index
			image.set_pixel(x,y,palette[pick])
	return image

static func rock_texture(source: Texture2D) -> Texture2D:
	if rocks == null:
		rocks = ImageTexture.create_from_image(recolor(source.get_image(),PixelArt.PLANET_PALETTES[2],ROCK_COLORS))
	return rocks

static func draw_floor(canvas: CanvasItem, bounds: Rect2, source: Texture2D) -> void:
	if floor_tile == null:
		var image := source.get_image().get_region(Rect2i(32,32,32,32))
		floor_tile = ImageTexture.create_from_image(recolor(image,PixelArt.FLOOR_PALETTES[3],FLOOR_COLORS))
	canvas.draw_rect(bounds,FLOOR_COLORS[0])
	for y in ceili(bounds.size.y/64.0):
		for x in ceili(bounds.size.x/64.0):
			var at := bounds.position+Vector2(x,y)*64
			var size := Vector2(minf(64,bounds.end.x-at.x),minf(64,bounds.end.y-at.y))
			canvas.draw_texture_rect(floor_tile,Rect2(at,size),false,Color(0.8,0.8,0.8,1))
	# Sparse nitrogen ice plates and reddish seams keep the floor readable.
	for y in range(1,int(bounds.size.y/128)-1):
		for x in range(1,int(bounds.size.x/128)-1):
			var hash_value := posmod(x*71+y*43,17)
			var at := bounds.position+Vector2(x,y)*128
			if hash_value < 5:
				var plate := PackedVector2Array()
				for offset: Vector2 in [Vector2(8,32),Vector2(16,32),Vector2(16,24),Vector2(32,24),Vector2(32,16),Vector2(56,16),Vector2(56,24),Vector2(96,24),Vector2(96,32),Vector2(104,32),Vector2(104,48),Vector2(112,48),Vector2(112,72),Vector2(104,72),Vector2(104,88),Vector2(88,88),Vector2(88,96),Vector2(32,96),Vector2(32,88),Vector2(16,88),Vector2(16,72),Vector2(8,72),Vector2(8,32)]:
					plate.append(at+offset)
				canvas.draw_colored_polygon(plate,Color(0.4,0.5,0.52,0.12))
				canvas.draw_polyline(plate,Color(0.42,0.54,0.54,0.28),2)

			elif hash_value == 8:
				canvas.draw_polyline(PackedVector2Array([at,at+Vector2(24,16),at+Vector2(56,16),at+Vector2(64,40)]),Color("665252"),2)
			elif hash_value == 12:
				canvas.draw_rect(Rect2(at+Vector2(20,34),Vector2(4,4)),Color("98b4b9"))
