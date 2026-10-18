extends SceneTree
func _initialize() -> void:
	var source: AudioStreamMP3 = load("res://musica/alarme.mp3").duplicate()
	source.loop = false
	var rate := int(AudioServer.get_mix_rate())
	var playback := source.instantiate_playback()
	playback.start()
	var samples := playback.mix_audio(1.0,ceili(source.get_length()*rate))
	playback.stop()
	var step := maxi(1,rate/100)
	var first := -1
	var last := 0
	for at in range(0,samples.size(),step):
		var energy := 0.0
		var end := mini(at+step,samples.size())
		for i in range(at,end):energy += samples[i].length_squared()*0.5
		if sqrt(energy/maxi(1,end-at)) > 0.001:
			if first < 0:first = at
			last = end
	if first < 0:
		push_error("alarme.mp3 has no audible samples")
		quit(1)
		return
	var overlap := mini(int(rate*.08),(last-first)/4)
	var frames := last-first-overlap
	var data := PackedByteArray()
	data.resize(frames*4)
	for i in frames:
		var sample: Vector2 = samples[first+i]
		if i < overlap:sample = samples[last-overlap+i].lerp(sample,float(i)/maxi(1,overlap-1))
		data.encode_s16(i*4,int(clampf(sample.x,-1,1)*32767))
		data.encode_s16(i*4+2,int(clampf(sample.y,-1,1)*32767))
	var output := AudioStreamWAV.new()
	output.format = AudioStreamWAV.FORMAT_16_BITS
	output.stereo = true
	output.mix_rate = rate
	output.data = data
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://musica/processed"))
	output.save_to_wav("res://musica/processed/alarme.wav")
	print("ALARM PREPARED: original %.3fs, seamless %.3fs" % [source.get_length(),float(frames)/rate])
	quit()
