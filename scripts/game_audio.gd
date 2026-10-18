extends Node

const NAMES := ["shot", "hit", "player_hurt", "enemy_down", "dash", "dash_ready", "echo", "coin", "coin_bonus", "item_pickup", "heal", "bomb", "shield", "overdrive", "ui_click", "purchase", "error", "boss_alert", "stage_clear", "defeat", "victory", "frost_warning"]
var streams: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var last_played: Dictionary = {}
var enabled := true
var game: Node2D
const DEATH_STREAM = preload("res://musica/morte1.mp3")
var death_voice: AudioStreamPlayer
const ALARM_STREAM = preload("res://musica/processed/alarme.wav")
const TRANSPORT_STREAMS = {"rover":preload("res://assets/audio/sfx/rover_engine.wav"),"rocket":preload("res://assets/audio/sfx/rocket_engine.wav")}
var alarm_voice: AudioStreamPlayer
var travel_voice: AudioStreamPlayer

func _ready() -> void:
	alarm_voice = AudioStreamPlayer.new()
	var alarm: AudioStreamWAV = ALARM_STREAM.duplicate()
	alarm.loop_mode = AudioStreamWAV.LOOP_FORWARD
	alarm.loop_begin = 0
	alarm.loop_end = roundi(alarm.get_length()*alarm.mix_rate)
	alarm_voice.stream = alarm
	alarm_voice.bus = &"SFX"
	add_child(alarm_voice)
	travel_voice = AudioStreamPlayer.new()
	travel_voice.bus = &"SFX"
	travel_voice.volume_db = -9
	add_child(travel_voice)
	death_voice = AudioStreamPlayer.new()
	death_voice.stream = DEATH_STREAM.duplicate()
	death_voice.stream.loop = false
	death_voice.bus = &"SFX"
	death_voice.volume_db = -7
	add_child(death_voice)
	for name: String in NAMES:
		streams[name] = load("res://assets/audio/sfx/" + name + ".wav")
	for index in 10:
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -10
		add_child(voice)
		voices.append(voice)

func play_event(event: String, at: Vector2 = Vector2.INF) -> bool:
	if not enabled or not streams.has(event):
		return false
	if at.is_finite() and is_instance_valid(game):
		var center: Vector2 = game.get_node("Camera2D").get_screen_center_position()
		if not Rect2(center - Vector2(768, 552), Vector2(1536, 1104)).has_point(at):
			return false
	var now := Time.get_ticks_msec()
	var spacing := 70 if event in ["shot", "hit", "enemy_down", "coin", "coin_bonus"] else 120
	if now - int(last_played.get(event, -10000)) < spacing:
		return false
	var important := event in ["player_hurt", "boss_alert", "frost_warning", "defeat", "victory"]
	var selected: AudioStreamPlayer
	for index in range(0 if important else 2, 2 if important else voices.size()):
		if not voices[index].playing:
			selected = voices[index]
			break
	if selected == null:
		if not important:
			return false
		selected = voices[0]
	selected.volume_db = -7 if important else (-16 if event in ["shot", "coin", "coin_bonus", "hit", "enemy_down"] else -10)
	selected.bus = &"UI" if event in ["ui_click", "purchase", "error"] else &"SFX"
	selected.stream = streams[event]
	selected.play()
	last_played[event] = now
	return true

func play_death() -> bool:
	if not enabled: return false
	for voice in voices: voice.stop()
	stop_alarm()
	travel_voice.stop()
	death_voice.stop()
	death_voice.play()
	return true

func stop_alarm() -> void:
	alarm_voice.stop()
	alarm_voice.stream_paused = false

func play_transport(kind: String) -> bool:
	travel_voice.stop()
	if not enabled or not TRANSPORT_STREAMS.has(kind): return false
	travel_voice.stream = TRANSPORT_STREAMS[kind]
	travel_voice.pitch_scale = 1.0
	travel_voice.play()
	return true

func _process(_delta: float) -> void:
	sync_state()

func sync_state() -> void:
	if not is_instance_valid(game): return
	if not enabled:
		stop_alarm()
		travel_voice.stop()
		return
	if game.state == "cleared":
		var urgency: float = clampf(1.0-game.collection_left/game.COLLECTION_DURATION,0,1)
		alarm_voice.stream_paused = false
		alarm_voice.pitch_scale = lerpf(0.85,1.65,pow(urgency,1.3))
		alarm_voice.volume_db = lerpf(-20,-6,urgency)
		if not alarm_voice.playing: alarm_voice.play()
	elif game.state == "paused" and game.paused_from == "cleared":
		alarm_voice.stream_paused = true
	else:
		stop_alarm()
	if game.state != "travel": travel_voice.stop()
