from pathlib import Path

p=Path('scripts/enemy.gd');s=p.read_text(encoding='utf-8').replace('extends Node2D','extends Node2D\n\nconst Art = preload("res://scripts/planet_art.gd")',1).replace('@export var use_placeholder_graphics := true','@export var use_planet_sprites := true\n@onready var visual: Sprite2D = $Visual')
pos=s.index('func _physics_process(')
s=s[:pos]+'''func _ready() -> void:
	update_visual()

func update_visual() -> void:
	if not is_instance_valid(visual):
		return
	visual.visible = use_planet_sprites
	visual.texture = Art.BOSSES[kind] if boss else Art.MINIONS[kind]
	var display_size := 110.0 if boss else 80.0
	visual.scale = Vector2.ONE * display_size / 619.0
	visual.position = Vector2(0, roundf(sin(age * (5 if boss else 9)) * 1.5))
	if is_instance_valid(game) and is_instance_valid(game.player):
		visual.flip_h = game.player.position.x < position.x
	visual.modulate = Color(2.2, 2.2, 2.2) if hit_flash > 0 else Color.WHITE

'''+s[pos:]
s=s.replace('\tqueue_redraw()\n\nfunc hurt', '\tupdate_visual()\n\tqueue_redraw()\n\nfunc hurt')
start=s.index('func _draw()')
s=s[:start]+'''func _draw() -> void:
	if not is_instance_valid(game):
		return
	# Low, stepped shadow leaves the creature silhouette readable in crowds.
	var width := radius * 0.9
	var shadow := PackedVector2Array([Vector2(-width, 6), Vector2(-width + 4, 2), Vector2(width - 4, 2), Vector2(width, 6), Vector2(width, 12), Vector2(width - 4, 16), Vector2(-width + 4, 16), Vector2(-width, 12)])
	draw_colored_polygon(shadow, Color(0.02, 0.015, 0.03, 0.4))
	if kind == 2 and charge_phase >= 1.5 and charge_phase < 2.1:
		draw_line(Vector2.ZERO, charge_dir * 150, Color(1, 0.4, 0.5, 0.6), 2)
	if boss or health < max_health:
		var height := -55.0 if boss else -28.0
		draw_rect(Rect2(-radius, height, radius * 2, 4), Color("181828"))
		draw_rect(Rect2(-radius, height, radius * 2 * maxf(health / max_health, 0), 4), Color("ff7e8d"))
'''
p.write_text(s,encoding='utf-8')

p=Path('scripts/player.gd');s=p.read_text(encoding='utf-8').replace('extends Node2D','extends Node2D\n\nconst Art = preload("res://scripts/planet_art.gd")',1).replace('@export var use_placeholder_graphics := true','@export var use_planet_sprites := true\n@onready var visual: Sprite2D = $Visual\n@onready var echo_visual: Sprite2D = $EchoVisual\nvar echo_aim := Vector2.DOWN')
s=s.replace('\thealth = max_health', '\thealth = max_health\n\tupdate_visual()',1)
s=s.replace('"damage": shot_damage()}', '"damage": shot_damage(), "aim": aim}')
s=s.replace('\t\t\techo_pos = frame.pos','\t\t\techo_pos = frame.pos\n\t\t\techo_aim = frame.get("aim", aim)')
start=s.index('func _draw()')
s=s[:start]+'''func _process(_delta: float) -> void:
	update_visual()

func update_visual() -> void:
	if not is_instance_valid(visual) or not is_instance_valid(game):
		return
	visual.texture = Art.ASTRONAUT[Art.direction_index(aim)]
	var blink: bool = game.state == "playing" and immunity > 0 and immunity <= 1.2 and int(clock * 16) % 2 == 0
	visual.visible = use_planet_sprites and not blink
	var moving := Input.get_vector("left", "right", "up", "down").length_squared() > 0
	visual.position.y = roundf(sin(clock * 14) * 1.5) if moving and game.state == "playing" else 0.0
	echo_visual.visible = use_planet_sprites and not echo_frames.is_empty()
	echo_visual.position = echo_pos - position
	echo_visual.texture = Art.ASTRONAUT[Art.direction_index(echo_aim)]

func pixel_ring(radius: float, color: Color) -> void:
	for i in 32:
		var at := (Vector2.RIGHT.rotated(TAU * i / 32.0) * radius).snapped(Vector2(2, 2))
		draw_rect(Rect2(at - Vector2(1, 1), Vector2(3, 3)), color)

func _draw() -> void:
	if not is_instance_valid(game):
		return
	draw_rect(Rect2(-10, 8, 20, 8), Color(0.02, 0.015, 0.03, 0.4))
	if immunity > 1.5:
		pixel_ring(26, Color("78d6ff"))
	if overdrive_time > 0:
		pixel_ring(22, Color("dda2ff"))
	if dash_time > 0:
		draw_line(-dash_dir * 18, -dash_dir * 40, Color("69e5ff"), 6)
'''
p.write_text(s,encoding='utf-8')

p=Path('scripts/game.gd');s=p.read_text(encoding='utf-8').replace('\t\tdraw_rect(Rect2(star.snapped(Vector2(4, 4)), Vector2(2, 2)), Color(0.45, 0.6, 0.8, 0.3))','\t\tif not arena.has_point(star):\n\t\t\tdraw_rect(Rect2(star.snapped(Vector2(4, 4)), Vector2(2, 2)), Color(0.45, 0.6, 0.8, 0.3))');p.write_text(s,encoding='utf-8')

p=Path('scripts/projectile.gd');s=p.read_text(encoding='utf-8').replace('draw_circle(Vector2.ZERO, radius + 3, Color(color, 0.15))','draw_rect(Rect2(Vector2.ONE * (-radius - 2), Vector2.ONE * (radius * 2 + 4)), Color(color, 0.15))').replace('draw_circle(Vector2.ZERO, radius, color)','draw_rect(Rect2(Vector2(-radius, -radius + 2), Vector2(radius * 2, radius * 2 - 4)), color)\n\tdraw_rect(Rect2(Vector2(-radius + 2, -radius), Vector2(radius * 2 - 4, radius * 2)), color)');p.write_text(s,encoding='utf-8')
