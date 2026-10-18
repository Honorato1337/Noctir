extends Node
const ART = preload("res://assets/ui/Mira.png")
var cursor_texture: ImageTexture
func _ready() -> void:
	if OS.has_feature("mobile") or DisplayServer.get_name() == "headless": return
	var pixels := ART.get_image()
	pixels.resize(32,32,Image.INTERPOLATE_NEAREST)
	cursor_texture = ImageTexture.create_from_image(pixels)
	Input.set_custom_mouse_cursor(cursor_texture,Input.CURSOR_ARROW,Vector2(16,16))
	Input.set_custom_mouse_cursor(cursor_texture,Input.CURSOR_CROSS,Vector2(16,16))
	Input.set_custom_mouse_cursor(cursor_texture,Input.CURSOR_POINTING_HAND,Vector2(16,16))
func _exit_tree() -> void:
	if OS.has_feature("mobile") or DisplayServer.get_name() == "headless": return
	for shape in [Input.CURSOR_ARROW,Input.CURSOR_CROSS,Input.CURSOR_POINTING_HAND]: Input.set_custom_mouse_cursor(null,shape)
