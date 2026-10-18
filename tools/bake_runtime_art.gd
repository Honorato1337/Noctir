extends SceneTree

const PixelArt = preload("res://scripts/pixel_art_import.gd")
const Vehicles = preload("res://scripts/expedition_vehicles.gd")

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/optimized")
	var sources := [
		["res://assets/effects/particle_atlas-v2.png", Vector2i(64,64), PixelArt.EFFECT_PALETTES, 4, 1],
		["res://assets/environment/planet_terrain_atlas-v2.png", Vector2i(128,128), PixelArt.PLANET_PALETTES, 4, 1],
		["res://assets/environment/floor_tiles-v3.png", Vector2i(64,64), PixelArt.FLOOR_PALETTES, 2, 2]
	]
	for source in sources:
		var output: String = PixelArt.BAKED_TEXTURES[source[0]]
		if FileAccess.file_exists(output): continue
		var texture := PixelArt.texture(source[0], source[1], source[2], source[3], source[4])
		if texture == null or texture.get_image().save_png(output) != OK:
			quit(1)
			return
		print("BAKED: " + output)
	for kind in Vehicles.PATHS:
		var output := "res://assets/optimized/%s.png" % kind
		if FileAccess.file_exists(output): continue
		var texture := Vehicles.centered_texture(Vehicles.PATHS[kind])
		if texture.get_image().save_png(output) != OK:
			quit(1)
			return
		print("BAKED: " + output)
	quit()
