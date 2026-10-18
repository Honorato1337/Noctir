extends RefCounted
const PixelArt = preload("res://scripts/pixel_art_import.gd")
const PATH := "res://assets/effects/particle_atlas-v2.png"
static var atlas: Texture2D
static func texture() -> Texture2D:
	if atlas == null and ResourceLoader.exists(PATH): atlas = PixelArt.texture(PATH,Vector2i(64,64),PixelArt.EFFECT_PALETTES,4)
	return atlas
static func region(kind: int, frame: int) -> Rect2:
	var source := texture()
	var step: float = source.get_width() / 4.0 if source != null else 256.0
	return Rect2(clampi(frame, 0, 3) * step, clampi(kind, 0, 3) * step, step, step)
static func draw_particle(canvas: CanvasItem, at: Vector2, size: Vector2, kind: int, frame: int, color: Color = Color.WHITE) -> void:
	var source := texture()
	if source != null:
		canvas.draw_texture_rect_region(source, Rect2((at - size * 0.5).snapped(Vector2.ONE*2), size), region(kind, frame), color)
