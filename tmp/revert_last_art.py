from pathlib import Path
import re

p=Path('scripts/enemy.gd');s=p.read_text(encoding='utf-8')
s=s.replace('\nconst Art = preload("res://scripts/planet_art.gd")\n','')
s=s.replace('@export var use_planet_sprites := true\n@onready var visual: Sprite2D = $Visual','@export var use_placeholder_graphics := true')
start=s.index('func _ready()');end=s.index('func _physics_process(',start)
s=s[:start]+s[end:]
s=s.replace('\tupdate_visual()\n','')
s=s[:s.index('func _draw()')]+'''func _draw() -> void:
	if not use_placeholder_graphics or not is_instance_valid(game):
		return
	var color: Color = Color.WHITE if hit_flash > 0 else game.planet().enemy
	draw_circle(Vector2(0, 8), radius + 2, Color(0, 0, 0, 0.25))
	if kind == 0:
		for i in 6:
			var point := Vector2.RIGHT.rotated(TAU * i / 6) * radius
			draw_line(point * 0.7, point * 1.5 + Vector2(0, sin(age * 10 + i) * 3), color, 3)
		draw_circle(Vector2.ZERO, radius, color)
	elif kind == 1:
		var points := PackedVector2Array([Vector2(0, -radius - 4), Vector2(radius, 0), Vector2(0, radius + 4), Vector2(-radius, 0)])
		draw_colored_polygon(points, color)
	else:
		draw_rect(Rect2(Vector2(-radius, -radius), Vector2.ONE * radius * 2), color)
		if charge_phase >= 1.5 and charge_phase < 2.1:
			draw_line(Vector2.ZERO, charge_dir * 150, Color(1, 0.4, 0.5, 0.5), 2)
	draw_circle(Vector2(0, -2), radius * 0.43, Color("202338"))
	draw_circle(Vector2(3, -4), radius * 0.17, Color("fff1b8"))
	if boss or health < max_health:
		draw_rect(Rect2(-radius, -radius - 13, radius * 2, 4), Color("181828"))
		draw_rect(Rect2(-radius, -radius - 13, radius * 2 * maxf(health / max_health, 0), 4), Color("ff7e8d"))
'''
p.write_text(s,encoding='utf-8')

p=Path('scripts/player.gd');s=p.read_text(encoding='utf-8').replace('\nconst Art = preload("res://scripts/planet_art.gd")\n','')
s=s.replace('@export var use_planet_sprites := true\n@onready var visual: Sprite2D = $Visual\n@onready var echo_visual: Sprite2D = $EchoVisual\nvar echo_aim := Vector2.DOWN','@export var use_placeholder_graphics := true')
s=s.replace('\tupdate_visual()\n','').replace(', "aim": aim}', '}').replace('\t\t\techo_aim = frame.get("aim", aim)\n','')
s=s[:s.index('func _process(')]+'''func _draw() -> void:
	if not use_placeholder_graphics or not is_instance_valid(game):
		return
	if not echo_frames.is_empty():
		draw_astro(echo_pos - position, Color("63dbd3"), true)
	if immunity > 1.5:
		draw_arc(Vector2.ZERO, 26, 0, TAU, 24, Color("78d6ff"), 3)
	if overdrive_time > 0:
		draw_arc(Vector2.ZERO, 22, clock * 5, clock * 5 + PI * 1.5, 16, Color("dda2ff"), 3)
	if game.state == "playing" and immunity > 0 and immunity <= 1.2 and int(clock * 16) % 2 == 0:
		return
	draw_astro(Vector2.ZERO, Color("edf5f7"), false)
	draw_line(aim * 12, aim * 27, Color("ffe5a0"), 6)
	if dash_time > 0:
		draw_line(-dash_dir * 18, -dash_dir * 40, Color("69e5ff"), 7)

func draw_astro(at: Vector2, color: Color, ghost: bool) -> void:
	if ghost:
		color.a = 0.5
	draw_circle(at + Vector2(0, 10), 15, Color(0, 0, 0, 0.24))
	draw_rect(Rect2(at + Vector2(-14, -4), Vector2(7, 18)), Color("7c8ca6"))
	draw_rect(Rect2(at + Vector2(-9, 0), Vector2(18, 18)), color)
	draw_circle(at + Vector2(0, -6), 13, color)
	draw_style_box(game.visor_style, Rect2(at + Vector2(-9, -12), Vector2(19, 11)))
	draw_line(at + Vector2(-5, 16), at + Vector2(-5, 22), color, 6)
	draw_line(at + Vector2(5, 16), at + Vector2(5, 22), color, 6)
'''
p.write_text(s,encoding='utf-8')

Path('scripts/arena_decor.gd').write_text('''@tool
extends Node2D

func _ready() -> void:
	var floor_node := get_parent().get_node_or_null("Floor") as ColorRect
	if is_instance_valid(floor_node):
		floor_node.item_rect_changed.connect(queue_redraw)

func _draw() -> void:
	var floor_node := get_parent().get_node_or_null("Floor") as ColorRect
	if not is_instance_valid(floor_node):
		return
	var rect := floor_node.get_rect()
	var sector: int = get_parent().sector_index
	var color: Color = [Color("f39b70"), Color("e4d077"), Color("b0a3ff")][sector]
	for x in range(int(rect.position.x) + 16, int(rect.end.x), 32):
		for y in range(int(rect.position.y) + 16, int(rect.end.y), 32):
			draw_rect(Rect2(x, y, 2, 2), Color(color, 0.12))
	for y in range(int(rect.position.y) + 64, int(rect.end.y), 64):
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color(color, 0.045), 2)
	for x in range(int(rect.position.x) + 64, int(rect.end.x), 64):
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color(color, 0.045), 2)
	for corner in [rect.position + Vector2(8, 8), Vector2(rect.end.x - 32, rect.position.y + 8), Vector2(rect.position.x + 8, rect.end.y - 16), rect.end - Vector2(32, 16)]:
		draw_rect(Rect2(corner, Vector2(24, 8)), color)
	for i in 8:
		var at := rect.position + Vector2(80 + i * 120, 12)
		draw_rect(Rect2(at, Vector2(16, 4)), Color(color, 0.5))
		draw_rect(Rect2(Vector2(at.x, rect.end.y - 16), Vector2(16, 4)), Color(color, 0.5))
''',encoding='utf-8')
Path('scripts/pixel_cover.gd').write_text('''@tool
extends ColorRect

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("080e20"), false, 4)
	draw_rect(Rect2(4, 4, size.x - 8, 4), Color(1, 1, 1, 0.25))
	draw_rect(Rect2(4, size.y - 8, size.x - 8, 4), Color(0, 0, 0, 0.4))
	for at in [Vector2(8, 12), Vector2(size.x - 12, 12), Vector2(8, size.y - 16), size - Vector2(12, 16)]:
		draw_rect(Rect2(at, Vector2(4, 4)), Color(1, 1, 1, 0.3))
''',encoding='utf-8')

for name in ['player','enemy']:
 Path(f'scenes/actors/{name}.tscn').write_text(f'[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://scripts/{name}.gd" id="1"]\n\n[node name="{name.title()}" type="Node2D"]\nscript = ExtResource("1")\n',encoding='utf-8')

for p in Path('scenes/world').glob('*.tscn'):
 s=p.read_text(encoding='utf-8').replace('load_steps=6','load_steps=4')
 s=re.sub(r'^\[ext_resource type="Material"[^\n]*\n','',s,flags=re.M)
 s=re.sub(r'^material = ExtResource\("[45]_[^\"]+"\)\n','',s,flags=re.M)
 s=re.sub(r'^texture_filter = 1\n','',s,flags=re.M)
 s=s.replace('color = Color(0, 0, 0, 0)','color = Color(0.25, 0.28, 0.32, 1)')
 p.write_text(s,encoding='utf-8')
p=Path('scripts/arena_layout.gd');s=p.read_text(encoding='utf-8').replace('\tsector_index = game.planet_index\n','').replace('\t\tcover.color = Color.TRANSPARENT\n\t\tcover.queue_redraw()','\t\tcover.color = Color(game.planet().accent, 0.28)').replace('\t$FloorDetails.queue_redraw()\n','').replace('$Border.default_color = Color(0.05, 0.04, 0.07, 0.8)','$Border.default_color = Color(game.planet().accent, 0.6)');p.write_text(s,encoding='utf-8')
p=Path('scripts/projectile.gd');s=p.read_text(encoding='utf-8').replace('draw_rect(Rect2(Vector2.ONE * (-radius - 2), Vector2.ONE * (radius * 2 + 4)), Color(color, 0.15))','draw_circle(Vector2.ZERO, radius + 3, Color(color, 0.15))').replace('draw_rect(Rect2(Vector2(-radius, -radius + 2), Vector2(radius * 2, radius * 2 - 4)), color)\n\tdraw_rect(Rect2(Vector2(-radius + 2, -radius), Vector2(radius * 2 - 4, radius * 2)), color)','draw_circle(Vector2.ZERO, radius, color)');p.write_text(s,encoding='utf-8')
p=Path('scripts/game.gd');s=p.read_text(encoding='utf-8').replace('\t\tif not arena.has_point(star):\n\t\t\tdraw_rect(Rect2(star.snapped(Vector2(4, 4)), Vector2(2, 2)), Color(0.45, 0.6, 0.8, 0.3))','\t\tdraw_rect(Rect2(star.snapped(Vector2(4, 4)), Vector2(2, 2)), Color(0.45, 0.6, 0.8, 0.3))');p.write_text(s,encoding='utf-8')
p=Path('scripts/planets.gd');s=p.read_text(encoding='utf-8').replace('Jupiter uses a fictional floating mineral crust.','Gas giants use platforms.').replace('"subtitle": "Crosta Olho da Tempestade"','"subtitle": "Plataforma Olho da Tempestade"');p.write_text(s,encoding='utf-8')

p=Path('tests/smoke.gd');s=p.read_text(encoding='utf-8');start=s.index('\tgame.player.aim = Vector2.UP');end=s.index('\tcheck(game.blocked(',start);s=s[:start]+s[end:]
s=s.replace('\t\tvar sample_enemy = game.enemies.get_child(0)\n','')
s='\n'.join(line for line in s.split('\n') if 'planet-specific minion sprite' not in line and 'boss uses its own planet sprite' not in line)
p.write_text(s,encoding='utf-8')
