extends RefCounted
const PixelArt = preload("res://scripts/pixel_art_import.gd")
const PATHS := {"rover": "res://assets/vehicles/rover-v2.png", "rocket": "res://assets/vehicles/rocket-v2.png"}
static var images: Dictionary = {}
static var frame_counts: Dictionary = {}
static func texture(kind: String) -> Texture2D:
	if kind == "ship": kind = "rocket"
	if not images.has(kind):
		var path: String = PATHS.get(kind, "")
		if not ResourceLoader.exists(path): return null
		images[kind] = centered_texture(path)
		frame_counts[kind] = 2
	return images[kind]
static func region(kind: String, frame: int) -> Rect2:
	if kind == "ship": kind = "rocket"
	var source := texture(kind)
	if source == null: return Rect2()
	var columns: int = frame_counts[kind]
	var width: float = source.get_width()/float(columns)
	return Rect2(posmod(frame,columns)*width,0,width,source.get_height())
static func draw_vehicle(canvas: CanvasItem, kind: String, center: Vector2, box: Vector2, frame: int = 0) -> void:
	var source := texture(kind)
	if source == null: return
	# Whole frame and integer enlargement keep pixel size and animation alignment.
	var scale := maxf(1,floorf(minf(box.x,box.y)/32.0))
	var size := Vector2.ONE * 32 * scale
	canvas.draw_texture_rect_region(source,Rect2((center-size*0.5).snapped(Vector2.ONE*2),size),region(kind,frame))

static func centered_texture(path: String) -> Texture2D:
	# Source frames have different transparent margins. Align the actual hulls,
	# keeping a shared vertical crop so only the exhaust changes between frames.
	var source: Image = load(path).get_image()
	if source.is_compressed(): source.decompress()
	source.convert(Image.FORMAT_RGBA8)
	for y in source.get_height():
		for x in source.get_width():
			if source.get_pixel(x,y).a < 0.5: source.set_pixel(x,y,Color.TRANSPARENT)
	var width := source.get_width()/2
	var bounds: Array[Rect2i] = []
	var top := source.get_height()
	var bottom := 0
	var widest := 0
	for frame in 2:
		var used := source.get_region(Rect2i(frame*width,0,width,source.get_height())).get_used_rect()
		bounds.append(used)
		top = mini(top,used.position.y)
		bottom = maxi(bottom,used.end.y)
		widest = maxi(widest,used.size.x)
	var scale := minf(30.0/maxi(1,widest),30.0/maxi(1,bottom-top))
	var atlas := Image.create(64,32,false,Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	for frame in 2:
		var area := Rect2i(frame*width+bounds[frame].position.x,top,bounds[frame].size.x,bottom-top)
		var part := source.get_region(area)
		part.resize(maxi(1,roundi(area.size.x*scale)),maxi(1,roundi(area.size.y*scale)),Image.INTERPOLATE_NEAREST)
		atlas.blit_rect(part,Rect2i(Vector2i.ZERO,part.get_size()),Vector2i(frame*32+(32-part.get_width())/2,(32-part.get_height())/2))
	for y in 32:
		for x in 64:
			var color := atlas.get_pixel(x,y)
			if color.a < 0.5: continue
			var nearest: Color = PixelArt.VEHICLE_PALETTE[0]
			var distance := INF
			for candidate: Color in PixelArt.VEHICLE_PALETTE:
				var delta := Vector3(color.r-candidate.r,color.g-candidate.g,color.b-candidate.b)
				if delta.length_squared() < distance:
					distance = delta.length_squared()
					nearest = candidate
			atlas.set_pixel(x,y,nearest)
	return ImageTexture.create_from_image(atlas)
