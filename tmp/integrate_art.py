from pathlib import Path

for key in ['mars','venus','jupiter','astronaut']:
    # Atlas regions, not modified/cropped copies of the generated PNGs.
    names=['ground','minion','rock','boss'] if key!='astronaut' else ['down','up','left','right']
    for name,(x,y) in zip(names,[(4,4),(631,4),(4,631),(631,631)]):
        text=f'''[gd_resource type="AtlasTexture" load_steps=2 format=3]
[ext_resource type="Texture2D" path="res://assets/art/planet_atlases/{key}_kit.png" id="1"]

[resource]
atlas = ExtResource("1")
region = Rect2({x}, {y}, 619, 619)
filter_clip = true
'''
        Path(f'assets/art/regions/{key}_{name}.tres').write_text(text,encoding='utf-8')

text='@tool\nextends RefCounted\n\n'
for prop,name in [('GROUNDS','ground'),('MINIONS','minion'),('ROCKS','rock'),('BOSSES','boss')]:
    text+=f'const {prop} = [\n'+',\n'.join(f'\tpreload("res://assets/art/regions/{key}_{name}.tres")' for key in ['mars','venus','jupiter'])+'\n]\n\n'
text+='const ASTRONAUT = [\n'+',\n'.join(f'\tpreload("res://assets/art/regions/astronaut_{name}.tres")' for name in ['down','up','left','right'])+'\n]\n\n'
text+='''static func direction_index(direction: Vector2) -> int:
	if absf(direction.x) > absf(direction.y):
		return 2 if direction.x < 0 else 3
	return 1 if direction.y < 0 else 0
'''
Path('scripts/planet_art.gd').write_text(text,encoding='utf-8')

p=Path('scenes/actors/enemy.tscn');s=p.read_text(encoding='utf-8').replace('load_steps=2','load_steps=4');pos=s.index('[node ');s=s[:pos]+'[ext_resource type="Texture2D" path="res://assets/art/regions/mars_minion.tres" id="2_art"]\n[ext_resource type="Material" path="res://assets/art/pixel_material.tres" id="3_material"]\n\n'+s[pos:];s+='''
[node name="Visual" type="Sprite2D" parent="."]
texture_filter = 1
texture = ExtResource("2_art")
material = ExtResource("3_material")
scale = Vector2(0.12924, 0.12924)
''';p.write_text(s,encoding='utf-8')

p=Path('scenes/actors/player.tscn');s=p.read_text(encoding='utf-8').replace('load_steps=2','load_steps=4');pos=s.index('[node ');s=s[:pos]+'[ext_resource type="Texture2D" path="res://assets/art/regions/astronaut_down.tres" id="2_art"]\n[ext_resource type="Material" path="res://assets/art/pixel_material.tres" id="3_material"]\n\n'+s[pos:];s+='''
[node name="Visual" type="Sprite2D" parent="."]
texture_filter = 1
texture = ExtResource("2_art")
material = ExtResource("3_material")
scale = Vector2(0.119548, 0.119548)

[node name="EchoVisual" type="Sprite2D" parent="."]
visible = false
texture_filter = 1
texture = ExtResource("2_art")
material = ExtResource("3_material")
scale = Vector2(0.119548, 0.119548)
modulate = Color(0.25, 1, 0.85, 0.55)
''';p.write_text(s,encoding='utf-8')

# Decor and rock scripts are shared across all twelve authored maps.
for p in Path('scenes/world').glob('*.tscn'):
    s=p.read_text(encoding='utf-8').replace('load_steps=4','load_steps=5')
    pos=s.index('[node ')
    s=s[:pos]+'[ext_resource type="Material" path="res://assets/art/pixel_material.tres" id="4_pixel"]\n\n'+s[pos:]
    s=s.replace('[node name="FloorDetails" type="Node2D" parent="."]','[node name="FloorDetails" type="Node2D" parent="."]\ntexture_filter = 1\nmaterial = ExtResource("4_pixel")')
    # Cover nodes are still editable ColorRects; their script renders natural rock outcrops.
    s=s.replace('script = ExtResource("3_cover")', 'script = ExtResource("3_cover")\ntexture_filter = 1\nmaterial = ExtResource("4_pixel")')
    s=s.replace('color = Color(0.25, 0.28, 0.32, 1)', 'color = Color(0, 0, 0, 0)')
    p.write_text(s,encoding='utf-8')
