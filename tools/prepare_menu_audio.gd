extends SceneTree
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://musica/processed"))
	for filename in ["soundmenu1", "SoundMenu"]:
		var source: AudioStreamMP3 = load("res://musica/"+filename+".mp3").duplicate()
		source.loop = false
		var rate := int(AudioServer.get_mix_rate())
		var playback := source.instantiate_playback()
		playback.start()
		var samples := playback.mix_audio(1.0,ceili(source.get_length()*rate))
		playback.stop()
		var window := maxi(1,rate/100)
		var first := -1
		var last := 0
		for at in range(0,samples.size(),window):
			var energy := 0.0
			var end := mini(at+window,samples.size())
			for i in range(at,end): energy += samples[i].length_squared()*0.5
			if sqrt(energy/maxi(1,end-at)) > 0.0025:
				if first < 0: first = at
				last = end
		if first < 0:
			push_error("Silent menu source: "+filename)
			quit(1)
			return
		var start := first if filename == "SoundMenu" else 0
		var overlap := mini(int(rate*0.12),(last-start)/4) if filename == "SoundMenu" else 0
		var frames := last-start-overlap
		var data := PackedByteArray()
		data.resize(frames*4)
		for i in frames:
			var sample: Vector2 = samples[start+i]
			if i < overlap:
				# Equal-time circular overlap joins the tail directly into the head.
				sample = samples[last-overlap+i].lerp(sample,float(i)/maxi(1,overlap-1))
			if overlap == 0:
				sample *= minf(1,float(i)/(rate*0.004))*minf(1,float(frames-1-i)/(rate*0.004))
			data.encode_s16(i*4,int(clampf(sample.x,-1,1)*32767))
			data.encode_s16(i*4+2,int(clampf(sample.y,-1,1)*32767))
		var output := AudioStreamWAV.new()
		output.format = AudioStreamWAV.FORMAT_16_BITS
		output.stereo = true
		output.mix_rate = rate
		output.data = data
		output.save_to_wav("res://musica/processed/"+filename+".wav")
		print("PREPARED %s: %.3fs -> %.3fs / overlap %.3fs" % [filename,source.get_length(),float(frames)/rate,float(overlap)/rate])
	quit()
