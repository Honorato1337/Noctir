from pathlib import Path
import re, json

font_path = 'res://fonts/after_burner_neue/After Burner Neue.ttf'
p = Path('ui_theme.tres')
s = p.read_text(encoding='utf-8')
s = re.sub(r'\[gd_resource[^\]]*\]', '[gd_resource type="Theme" load_steps=6 format=3]', s, count=1)
s = s.replace('\n[sub_resource', f'\n[ext_resource type="FontFile" path="{font_path}" id="1_font"]\n\n[sub_resource', 1)
s = re.sub(r'corner_radius_\w+ = 8', 'corner_radius_top_left = 0', s) # drop duplicate corner entries below
s = re.sub(r'^corner_radius_top_left = 0\n', '', s, flags=re.M)
s = re.sub(r'border_width_(left|top|right|bottom) = 1', r'border_width_\1 = 3', s)
s = s.replace('[resource]\n', '[resource]\ndefault_font = ExtResource("1_font")\n')
s = s.replace('bg_color = Color(0.035, 0.065, 0.12, 0.98)', 'bg_color = Color(0.035, 0.065, 0.12, 1)\nshadow_color = Color(0, 0, 0, 0.65)\nshadow_size = 6\nshadow_offset = Vector2(6, 6)')
p.write_text(s, encoding='utf-8')

# Disable smoothing in the import settings, keeping the provided font intact.
for p in Path('fonts/after_burner_neue').glob('*.ttf.import'):
    s = p.read_text(encoding='utf-8')
    s = re.sub(r'^antialiasing=.*$', 'antialiasing=0', s, flags=re.M)
    s = re.sub(r'^subpixel_positioning=.*$', 'subpixel_positioning=0', s, flags=re.M)
    s = re.sub(r'^oversampling=.*$', 'oversampling=1.0', s, flags=re.M)
    p.write_text(s, encoding='utf-8')

for p in Path('scenes/ui').glob('*.tscn'):
    if p.stem == 'hud':
        continue
    s = p.read_text(encoding='utf-8')
    # All screens inherit the same font; preserve authored title/text changes.
    s = re.sub(r'^\[ext_resource type="FontFile"[^\n]*\n', '', s, flags=re.M)
    s = re.sub(r'^theme_override_fonts/font = .*\n', '', s, flags=re.M)
    s = re.sub(r'\[gd_scene[^\]]*\]', '[gd_scene load_steps=3 format=3]', s, count=1)
    resource = '[ext_resource type="Script" path="res://scripts/pixel_backdrop.gd" id="2_pixel"]\n'
    pos = s.index('[node ')
    s = s[:pos] + resource + '\n' + s[pos:]
    s = s.replace('color = Color(0.02, 0.035, 0.07, 0.96)', 'color = Color(0.02, 0.035, 0.07, 1)\nscript = ExtResource("2_pixel")')
    s = s.replace('Nove arenas.', 'Doze arenas.').replace('theme_override_font_sizes/font_size = 42', 'theme_override_font_sizes/font_size = 36')
    s = s.replace('theme_override_font_sizes/font_size = 18', 'theme_override_font_sizes/font_size = 18')
    if p.stem == 'main_menu':
        s = s.replace('custom_minimum_size = Vector2(660, 0)', 'custom_minimum_size = Vector2(720, 0)')
    p.write_text(s, encoding='utf-8')

def node(name, kind, parent=None, props=''):
    return f'\n[node name="{name}" type="{kind}"' + (f' parent="{parent}"' if parent is not None else '') + f']\n{props}\n'

full = 'layout_mode = 3\nanchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\ngrow_horizontal = 2\ngrow_vertical = 2'
hud = '[gd_scene load_steps=3 format=3]\n[ext_resource type="Theme" path="res://ui_theme.tres" id="1"]\n[ext_resource type="Script" path="res://scripts/hud.gd" id="2"]\n'
hud += node('HUD', 'Control', props=full + '\nmouse_filter = 2\ntheme = ExtResource("1")\nscript = ExtResource("2")')
hud += node('TopBar', 'ColorRect', '.', 'offset_left = 64.0\noffset_top = 16.0\noffset_right = 1088.0\noffset_bottom = 88.0\nmouse_filter = 2\ncolor = Color(0.025, 0.05, 0.09, 0.97)')
hud += node('Accent', 'ColorRect', '.', 'offset_left = 64.0\noffset_top = 85.0\noffset_right = 1088.0\noffset_bottom = 88.0\nmouse_filter = 2\ncolor = Color(0.44, 0.9, 0.82, 1)')
items = [
    ('Brand', 76, 24, 190, 48, 'NOCTIR', 18),
    ('Planet', 200, 26, 490, 48, 'MARTE / 01-12', 14),
    ('Timer', 524, 20, 630, 50, '00:40', 24),
    ('Score', 672, 26, 868, 48, 'PTS 00000', 14),
    ('Record', 886, 26, 1080, 48, 'REC 00000', 14),
    ('Health', 76, 58, 260, 78, 'TRAJE 5/5', 14),
    ('Echo', 274, 58, 490, 78, 'Q ECO PRONTO', 14),
    ('Hazard', 524, 58, 1078, 78, 'CRATERAS / COBERTURA', 12),
    ('Message', 200, 112, 1020, 138, '', 16),
    ('Controls', 64, 680, 670, 702, 'WASD MOVER / SETAS TIRO / ESP DASH / Q ECO', 12),
    ('Counters', 720, 680, 1088, 702, 'HOSTIS 00 / MOD 00', 12),
    ('Extract', 824, 430, 1080, 454, '[E] EXTRACAO', 14),
]
for name, l, t, r, b, text, size in items:
    hud += node(name, 'Label', '.', f'unique_name_in_owner = true\noffset_left = {l}.0\noffset_top = {t}.0\noffset_right = {r}.0\noffset_bottom = {b}.0\nmouse_filter = 2\ntheme_override_font_sizes/font_size = {size}\ntext = {json.dumps(text, ensure_ascii=False)}')
Path('scenes/ui/hud.tscn').write_text(hud, encoding='utf-8')

# Twelve authored layouts, rather than one repeated arena.
layouts = [
    ('arena', 'MARTE / COLONIA FERRUGEM', [(325,270,72,88),(730,410,88,66)], [(530,270),(630,500)]),
    ('mars_quarry', 'MARTE / PEDREIRA', [(320,232,80,80),(320,464,80,80),(752,232,80,80),(752,464,80,80)], []),
    ('mars_hangars', 'MARTE / HANGARES', [(384,224,352,48),(384,496,352,48)], []),
    ('mars_reactor', 'MARTE / REATOR', [(496,304,128,160),(272,224,64,64),(816,480,64,64)], []),
    ('venus_refinery', 'VENUS / REFINARIA', [(336,240,64,176),(752,352,64,176)], [(544,240),(608,528)]),
    ('venus_gardens', 'VENUS / JARDINS SULFURICOS', [(304,224,96,64),(304,480,96,64),(752,224,96,64),(752,480,96,64)], [(512,320),(640,448)]),
    ('venus_channels', 'VENUS / CANAIS', [(384,192,64,144),(384,448,64,144),(704,288,64,176)], [(576,208),(576,560)]),
    ('venus_core', 'VENUS / CAMARA DE PRESSAO', [(448,272,64,64),(640,432,64,64),(640,272,64,64),(448,432,64,64)], [(560,384),(304,528)]),
    ('jupiter_docks', 'JUPITER / DOCAS', [(320,208,64,160),(768,400,64,160)], []),
    ('jupiter_relays', 'JUPITER / RELES', [(288,240,80,80),(496,448,80,80),(704,240,80,80),(880,480,64,64)], []),
    ('jupiter_eye', 'JUPITER / OLHO DO CICLONE', [(448,224,224,48),(448,512,224,48),(320,352,64,64),(768,352,64,64)], []),
    ('jupiter_heart', 'JUPITER / CORACAO DA TEMPESTADE', [(288,192,96,64),(768,192,96,64),(288,512,96,64),(768,512,96,64)], []),
]
for index, (filename, title, covers, hazards) in enumerate(layouts):
    scene = '[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://scripts/arena_layout.gd" id="1"]\n'
    scene += node('Arena', 'Node2D', props=f'script = ExtResource("1")\nlayout_name = "{title}"\nsector_index = {index // 4}')
    scene += node('Floor', 'ColorRect', '.', 'offset_left = 64.0\noffset_top = 104.0\noffset_right = 1088.0\noffset_bottom = 664.0\nmouse_filter = 2\ncolor = Color(0.12, 0.10, 0.15, 1)')
    scene += node('Border', 'Line2D', '.', 'points = PackedVector2Array(64,104,1088,104,1088,664,64,664,64,104)\nwidth = 4.0\ndefault_color = Color(0.6, 0.8, 0.8, 1)')
    scene += node('Obstacles', 'Node2D', '.')
    for i, (x,y,w,h) in enumerate(covers):
        name = ('PillarA' if i == 0 else 'PillarB' if i == 1 else f'Cover{i+1}')
        scene += node(name, 'ColorRect', 'Obstacles', f'offset_left = {x}.0\noffset_top = {y}.0\noffset_right = {x+w}.0\noffset_bottom = {y+h}.0\nmouse_filter = 2\ncolor = Color(0.25, 0.28, 0.32, 1)')
    for name,x,y in [('PlayerSpawn',144,384),('Portal',1040,384),('BossSpawn',944,384)]:
        scene += node(name,'Marker2D','.',f'position = Vector2({x},{y})\ngizmo_extents = 24.0')
    scene += node('SpawnGates','Node2D','.')
    for name,x,y in [('NorthWest',112,152),('NorthEast',1040,152),('SouthWest',112,616),('SouthEast',1040,616)]:
        scene += node(name,'Marker2D','SpawnGates',f'position = Vector2({x},{y})')
    scene += node('Hazards','Node2D','.')
    for i,(x,y) in enumerate(hazards):
        scene += node(f'Acid{i+1}','Marker2D','Hazards',f'position = Vector2({x},{y})\ngizmo_extents = 54.0')
    Path(f'scenes/world/{filename}.tscn').write_text(scene,encoding='utf-8')

p = Path('scripts/game.gd')
s = p.read_text(encoding='utf-8')
s = s.replace('const ARENAS_PER_PLANET := 3', 'const ARENAS_PER_PLANET := 4\n@export var arena_scenes: Array[PackedScene] = [\n' + ',\n'.join(f'\tpreload("res://scenes/world/{item[0]}.tscn")' for item in layouts) + '\n]\n\nfunc total_rooms() -> int:\n\treturn arena_scenes.size()\n')
s = s.replace('var font: Font = ThemeDB.fallback_font', 'var font: Font = preload("res://fonts/after_burner_neue/After Burner Neue.ttf")')
s = s.replace('\t$Arena.apply_to(self)', '''	var next_scene: PackedScene = arena_scenes[room]
	if $Arena.scene_file_path != next_scene.resource_path:
		var old_arena := $Arena
		remove_child(old_arena)
		old_arena.queue_free()
		var next_arena := next_scene.instantiate()
		next_arena.name = "Arena"
		next_arena.z_index = -1
		add_child(next_arena)
	$Arena.apply_to(self)''')
s = s.replace('room == 8', 'room == total_rooms() - 1')
s = s.replace('"\n\nPontos: %d    Recorde: %d    Abates: %d\nArena: %d/9    Tempo: %ds"', '"\n\nPontos: %d    Recorde: %d    Abates: %d\nArena: %d/%d    Tempo: %ds"') if False else s
s = s.replace('Arena: %d/9', 'Arena: %d/%d').replace('kills, room + 1, int(elapsed)', 'kills, room + 1, total_rooms(), int(elapsed)')
s = s.replace('message = planet().name + " / " + planet().subtitle', 'message = $Arena.layout_name')
s = s.replace('pending = 7 + room * 2', 'pending = 7 + mini(room, 8) * 2')
s = s.replace('maxf(0.28, 0.85 - room * 0.055)', 'maxf(0.32, 0.85 - room * 0.045)')
s = s.replace('(room % 3) * 7', '(room % ARENAS_PER_PLANET) * 5').replace('floorf(room / 3.0)', 'floorf(room / float(ARENAS_PER_PLANET))').replace('room % 3 == 2', 'room % ARENAS_PER_PLANET == ARENAS_PER_PLANET - 1')
s = s.replace('visor_style.set_corner_radius_all(4)', 'visor_style.set_corner_radius_all(0)')
s = s.replace('draw_circle(star, 1 if i % 4 else 1.7, Color(0.45, 0.6, 0.8, 0.3))', 'draw_rect(Rect2(star.snapped(Vector2(4, 4)), Vector2(2, 2)), Color(0.45, 0.6, 0.8, 0.3))')
p.write_text(s, encoding='utf-8')
