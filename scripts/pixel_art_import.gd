@tool
extends RefCounted

# Upload generated sources on the same native pixel grid as the team's sprites.
# Source PNGs stay intact; this is an in-memory nearest-neighbour texture import.
const OUTLINE := Color("12173d")
const VEHICLE_PALETTE := [Color("12173d"),Color("6b74b2"),Color("909edd"),Color("c1d9f2"),Color("53a1ad"),Color("ffffff"),Color("ff695a"),Color("ffaa6e")]
const PLANET_PALETTES := [
	[Color("12173d"),Color("2b1829"),Color("3c1e2d"),Color("4b2535"),Color("721c2f"),Color("b23c40"),Color("ff695a"),Color("ffaa6e")],
	[Color("12173d"),Color("18263b"),Color("23324d"),Color("214253"),Color("3b768f"),Color("53a1ad"),Color("78fae6"),Color("c1d9f2")],
	[Color("12173d"),Color("272031"),Color("3a2736"),Color("553741"),Color("775245"),Color("9c704c"),Color("c59760"),Color("c1d9f2")],
	[Color("12173d"),Color("241d3b"),Color("382851"),Color("4e386a"),Color("6b74b2"),Color("7b6aa5"),Color("909edd"),Color("c1d9f2")]
]
const EFFECT_PALETTES := [
	[Color("12173d"),Color("c1d9f2"),Color("ffffff"),Color("53a1ad")],
	[Color("12173d"),Color("721c2f"),Color("b23c40"),Color("ffaa6e")],
	[Color("12173d"),Color("3b768f"),Color("53a1ad"),Color("78fae6")],
	[Color("12173d"),Color("b23c40"),Color("ff695a"),Color("ffaa6e")]
]
const FLOOR_PALETTES := [
 [Color("2b1829"),Color("351c2a"),Color("3b202c"),Color("46232d"),Color("532936"),Color("291824"),Color("612f3a"),Color("723d42")],
 [Color("18263b"),Color("1c2d43"),Color("20384b"),Color("244356"),Color("2c4e60"),Color("335b6a"),Color("162336"),Color("3b6673")],
 [Color("272031"),Color("312434"),Color("3d2938"),Color("4a303c"),Color("573b43"),Color("66494b"),Color("211b2c"),Color("73534d")],
 [Color("241d3b"),Color("2c2246"),Color("342950"),Color("40315e"),Color("4c396c"),Color("5b4779"),Color("201b33"),Color("6b5687")]
]
static var cache: Dictionary = {}
static func texture(path: String, logical_size: Vector2i, palettes: Array, row_count: int = 1, columns: int = 1) -> Texture2D:
	if cache.has(path): return cache[path]
	if not ResourceLoader.exists(path): return null
	var source: Texture2D = load(path)
	var image := source.get_image()
	image.convert(Image.FORMAT_RGBA8)
	image.resize(logical_size.x,logical_size.y,Image.INTERPOLATE_NEAREST)
	for y in logical_size.y:
		for x in logical_size.x:
			var palette: Array = palettes[mini(palettes.size()-1,(y*row_count/logical_size.y)*columns+x*columns/logical_size.x)]
			var color := image.get_pixel(x,y)
			if color.a < 0.5:
				image.set_pixel(x,y,Color.TRANSPARENT)
				continue
			var nearest: Color = palette[0]
			var best := INF
			for candidate: Color in palette:
				var delta := Vector3(color.r-candidate.r,color.g-candidate.g,color.b-candidate.b)
				var distance := delta.length_squared()
				if distance < best:
					best = distance
					nearest = candidate
			image.set_pixel(x,y,nearest)
	cache[path] = ImageTexture.create_from_image(image)
	return cache[path]
