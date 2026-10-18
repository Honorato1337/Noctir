extends SceneTree
func render(source: String, target: String, pixels: int) -> void:
	var image := Image.new()
	var err := image.load_svg_from_string(FileAccess.get_file_as_string(source),float(pixels)/384.0)
	if err != OK:
		push_error("Cannot render icon "+source)
		quit(1)
		return
	image.save_png(target)
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/branding"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp/icon-formats"))
	render("res://icon.svg","res://assets/branding/icon-384.png",384)
	render("res://icon.svg","res://assets/branding/launcher-192.png",192)
	for name in ["foreground","monochrome"]:
		render("res://assets/branding/adaptive_"+name+".svg","res://assets/branding/adaptive_"+name+".png",432)
	var background := Image.create(432,432,false,Image.FORMAT_RGBA8)
	background.fill(Color("080e20"))
	background.save_png("res://assets/branding/adaptive_background.png")
	for pixels in [16,32,48,64,128,256]:
		render("res://icon.svg","res://tmp/icon-formats/icon-%d.png" % pixels,pixels)
	print("Astronaut head icon formats rendered from SVG")
	quit()
