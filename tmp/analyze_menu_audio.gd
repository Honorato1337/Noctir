extends SceneTree
func _initialize() -> void:
	var report := {}
	for path in ["res://musica/soundmenu1.mp3", "res://musica/SoundMenu.mp3"]:
		var stream: AudioStreamMP3 = load(path).duplicate()
		stream.loop = false
		var playback := stream.instantiate_playback()
		playback.start()
		var rate := int(AudioServer.get_mix_rate())
		var levels := []
		for second in ceili(stream.get_length()):
			var samples := playback.mix_audio(1.0, rate)
			var energy := 0.0
			for sample in samples:
				energy += sample.length_squared() / 2.0
			levels.append(snappedf(sqrt(energy / maxi(1, samples.size())), 0.000001))
		playback.stop()
		report[path] = {"length": stream.get_length(), "rms_by_second": levels}
	print(JSON.stringify(report))
	var file := FileAccess.open("res://tmp/music_analysis.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report))
	quit()
