extends SceneTree
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://musica/processed"))
	for filename in ["soundmenu1", "SoundMenu"]:
		var source: AudioStreamMP3 = load("res://musica/" + filename + ".mp3").duplicate()
		source.loop = false
		var rate := int(AudioServer.get_mix_rate())
		var playback := source.instantiate_playback()
		playback.start()
		var samples := playback.mix_audio(1.0, ceili(source.get_length() * rate))
		playback.stop()
		var last := samples.size() - 1
		while last > 0 and maxf(absf(samples[last].x), absf(samples[last].y)) < 0.00012:
			last -= 1
		var frames := mini(samples.size(), last + int(rate * 0.01))
		var data := PackedByteArray()
		data.resize(frames * 4)
		for index in frames:
			var fade := minf(1, float(index) / (rate * 0.004)) * minf(1, float(frames - index) / (rate * 0.005))
			data.encode_s16(index * 4, int(clampf(samples[index].x * fade, -1, 1) * 32767))
			data.encode_s16(index * 4 + 2, int(clampf(samples[index].y * fade, -1, 1) * 32767))
		var output := AudioStreamWAV.new()
		output.format = AudioStreamWAV.FORMAT_16_BITS
		output.stereo = true
		output.mix_rate = rate
		output.data = data
		output.save_to_wav("res://musica/processed/" + filename + ".wav")
		print("TRIMMED %s: %.3fs -> %.3fs" % [filename, source.get_length(), float(frames) / rate])
	quit()
