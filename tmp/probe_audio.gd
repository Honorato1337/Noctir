extends SceneTree
func _initialize() -> void:
	for entry in ClassDB.class_get_method_list("AudioStreamPlayback", true):
		print(entry.name)
	quit()
