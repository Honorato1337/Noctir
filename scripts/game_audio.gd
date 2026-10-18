extends Node

const NAMES := ["shot", "hit", "player_hurt", "enemy_down", "dash", "dash_ready", "echo", "coin", "coin_bonus", "item_pickup", "heal", "bomb", "shield", "overdrive", "ui_click", "purchase", "error", "boss_alert", "stage_clear", "defeat", "victory", "frost_warning"]
var streams: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var last_played: Dictionary = {}
var enabled := true
var game: Node2D
const DEATH_STREAM = preload("res://musica/morte1.mp3")
var death_voice: AudioStreamPlayer

func _ready() -> void:
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
	death_voice.stop()
	death_voice.play()
	return true
