extends RefCounted

var volume := 80.0
var music_volume := 100.0
var sfx_volume := 100.0
var ui_volume := 100.0
var resolution_index := 1
var fullscreen := false
var keyboard_preset := 0
var keybinds: Dictionary = {}
var touch_mode := 0
const RESOLUTIONS := [Vector2i(960, 600), Vector2i(1152, 720), Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]
var muted := false
var played_seconds := 0.0
var save_path := "user://settings.cfg"

func load_settings() -> Error:
	var config := ConfigFile.new()
	var error := config.load(save_path)
	if error != OK:
		return error
	var saved_volume: Variant = config.get_value("audio", "volume", 80.0)
	if (saved_volume is float or saved_volume is int) and is_finite(float(saved_volume)):
		volume = clampf(float(saved_volume), 0, 100)
	var saved_mute: Variant = config.get_value("audio", "muted", false)
	muted = saved_mute if saved_mute is bool else false
	var saved_time: Variant = config.get_value("statistics", "played_seconds", 0.0)
	if (saved_time is float or saved_time is int) and is_finite(float(saved_time)):
		played_seconds = clampf(float(saved_time), 0, 1000000000000)
	for channel: String in ["music", "sfx", "ui"]:
		var value: Variant = config.get_value("audio", channel, 100.0)
		if (value is float or value is int) and is_finite(float(value)):
			set(channel + "_volume", clampf(float(value), 0, 100))
	var resolution: Variant = config.get_value("video", "resolution", 1)
	resolution_index = clampi(resolution, 0, RESOLUTIONS.size()-1) if resolution is int else 1
	var full: Variant = config.get_value("video", "fullscreen", false)
	fullscreen = full if full is bool else false
	var preset: Variant = config.get_value("controls", "preset", 0)
	keyboard_preset = clampi(preset, 0, 1) if preset is int else 0
	var touch: Variant = config.get_value("controls", "touch", 0)
	touch_mode = clampi(touch, 0, 2) if touch is int else 0
	keybinds.clear()
	if config.has_section("keys"):
		for action: String in config.get_section_keys("keys"):
			var code: Variant = config.get_value("keys", action)
			if code is int and code >= 0 and code < (1 << 25):
				keybinds[action] = code
	return OK

func apply_audio() -> void:
	for channel: String in ["Music", "SFX", "UI"]:
		if AudioServer.get_bus_index(channel) < 0:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, channel)
			AudioServer.set_bus_send(index, "Master")
		var value: float = get(channel.to_lower() + "_volume")
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(channel), linear_to_db(maxf(value / 100.0, 0.0001)))
		AudioServer.set_bus_mute(AudioServer.get_bus_index(channel), value <= 0)
	var master := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master, linear_to_db(maxf(volume / 100.0, 0.0001)))
	AudioServer.set_bus_mute(master, muted or volume <= 0)

func save_settings() -> Error:
	var config := ConfigFile.new()
	config.set_value("audio", "volume", volume)
	config.set_value("audio", "muted", muted)
	config.set_value("statistics", "played_seconds", played_seconds)
	for channel: String in ["music", "sfx", "ui"]:
		config.set_value("audio", channel, get(channel + "_volume"))
	config.set_value("video", "resolution", resolution_index)
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("controls", "preset", keyboard_preset)
	config.set_value("controls", "touch", touch_mode)
	for action: String in keybinds:
		config.set_value("keys", action, keybinds[action])
	var error := config.save(save_path + ".tmp")
	if error != OK:
		return error
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(save_path + ".tmp"), ProjectSettings.globalize_path(save_path))

func play_time_text() -> String:
	var seconds := int(played_seconds)
	return "%02d:%02d:%02d" % [seconds / 3600, (seconds / 60) % 60, seconds % 60]

func clock_text() -> String:
	var date := Time.get_datetime_dict_from_system()
	return "%02d/%02d/%04d   %02d:%02d:%02d" % [date.day, date.month, date.year, date.hour, date.minute, date.second]

func test_tone() -> AudioStreamWAV:
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = 44100
	var frames := 11025
	var data := PackedByteArray()
	data.resize(frames * 2)
	for index in frames:
		var time := float(index) / sound.mix_rate
		var envelope := minf(1, time / 0.01) * minf(1, (0.25 - time) / 0.04)
		var wave := sin(TAU * 660 * time) * 0.2 * envelope
		data.encode_s16(index * 2, int(wave * 32767))
	sound.data = data
	return sound

func desktop_video_available() -> bool:
	return not OS.has_feature("mobile") and not OS.has_feature("web") and DisplayServer.get_name() != "headless"

func apply_video() -> void:
	if not desktop_video_available():
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	if not fullscreen:
		var requested: Vector2i = RESOLUTIONS[resolution_index]
		var area := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
		var available := area.size - Vector2i(24, 60)
		var factor := minf(1, minf(float(available.x) / requested.x, float(available.y) / requested.y))
		var size := Vector2i(Vector2(requested) * factor)
		DisplayServer.window_set_size(size)
		DisplayServer.window_set_position(area.position + (area.size - size) / 2)
