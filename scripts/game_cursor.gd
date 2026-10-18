extends CanvasLayer

const ART = preload("res://assets/ui/Mira.png")
const INVERT = preload("res://scripts/cursor_invert.gdshader")
var pointer: Sprite2D
var previous_mouse_mode: Input.MouseMode

func _ready() -> void:
 if OS.has_feature("mobile") or DisplayServer.get_name() == "headless": return
 layer = 128
 previous_mouse_mode = Input.mouse_mode
 Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
 pointer = Sprite2D.new()
 pointer.texture = ART
 pointer.scale = Vector2(2, 2)
 pointer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 var invert_material := ShaderMaterial.new()
 invert_material.shader = INVERT
 pointer.material = invert_material
 add_child(pointer)
 _update_pointer()

func _process(_delta: float) -> void:
 _update_pointer()

func _update_pointer() -> void:
 if not is_instance_valid(pointer): return
 var mouse := get_viewport().get_mouse_position()
 pointer.position = mouse
 pointer.visible = DisplayServer.window_is_focused() and get_viewport().get_visible_rect().has_point(mouse)

func _exit_tree() -> void:
 if is_instance_valid(pointer): Input.mouse_mode = previous_mouse_mode
