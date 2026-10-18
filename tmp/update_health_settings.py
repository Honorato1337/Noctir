from pathlib import Path
import re
root = Path(__file__).resolve().parents[1]
path=root/'scenes/ui/hud.tscn'
s=path.read_text(encoding='utf-8')
idx=s.index('[node name="HUD"')
s=s[:idx]+'[ext_resource type="Script" path="res://scripts/heart_meter.gd" id="3_hearts"]\n\n'+s[idx:]
positions={'Planet':(360,22,608,50),'Timer':(632,22,756,50),'Coins':(780,22,936,50),'Echo':(360,56,560,84),'Counters':(568,56,764,84),'Score':(776,56,936,84)}
for name,(left,top,right,bottom) in positions.items():
    pat=r'(\[node name="'+name+r'"[^\n]*\]\n)(.*?)(?=\n\[node|\Z)'
    def move(m):
        body=m[2]
        for key,value in [('left',left),('top',top),('right',right),('bottom',bottom)]:
            body=re.sub(r'offset_'+key+r' = [\d.]+', f'offset_{key} = {value}.0',body)
        return m[1]+body
    s=re.sub(pat,move,s,flags=re.S)
pat=r'\[node name="Health"[^\n]*\]\n.*?(?=\n\[node)'
s=re.sub(pat,'''[node name="Health" type="Control" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 76.0
offset_top = 20.0
offset_right = 336.0
offset_bottom = 84.0
mouse_filter = 2
script = ExtResource("3_hearts")
''',s,flags=re.S)
path.write_text(s,encoding='utf-8')

path=root/'scenes/ui/main_menu.tscn'
s=path.read_text(encoding='utf-8')
s=s.replace('text = "ONE MORE ORBIT    /    ONE MORE TIME"','text = "17/10/2026   00:00:00    /    JOGADO 00:00:00"')
start=s.index('[node name="Record"')
end=s.index('[node name=',start+1)
record=s[start:end]
s=s[:start]+s[end:]
record=record.replace('parent="Center/Layout/Content/Mission/Box"','parent="Center/Layout/Content/Astronaut/Box"')
at=s.index('[node name="Protocol"')
s=s[:at]+record+s[at:]
# Share a row so two menu actions do not increase the menu's overall height.
at=s.index('[node name="ControlsButton"')
s=s[:at]+'''[node name="MenuActions" type="HBoxContainer" parent="Center/Layout/Content/Mission/Box"]
layout_mode = 2
theme_override_constants/separation = 12

[node name="SettingsButton" type="Button" parent="Center/Layout/Content/Mission/Box/MenuActions"]
layout_mode = 2
custom_minimum_size = Vector2(0, 58)
size_flags_horizontal = 3
text = "CONFIGURAÇÕES"

'''+s[at:]
s=s.replace('[node name="ControlsButton" type="Button" parent="Center/Layout/Content/Mission/Box"','[node name="ControlsButton" type="Button" parent="Center/Layout/Content/Mission/Box/MenuActions"')
s=re.sub(r'(\[node name="ControlsButton"[^\n]*\]\n)',r'\1size_flags_horizontal = 3\n',s)
path.write_text(s,encoding='utf-8')

# Reuse only the backdrop and editable container shell of the pause screen.
s=(root/'scenes/ui/pause_menu.tscn').read_text(encoding='utf-8')
s=s[:s.index('[node name="Tag"')].replace('name="PauseMenu"','name="SettingsMenu"')
s+='''[node name="Title" type="Label" parent="Center/Card/Box"]
layout_mode = 2
theme_override_font_sizes/font_size = 36
theme_override_colors/font_color = Color(0.44, 0.9, 0.82, 1)
text = "CONFIGURAÇÕES"

[node name="Description" type="Label" parent="Center/Card/Box"]
layout_mode = 2
text = "Ajuste o volume geral do jogo."

[node name="VolumeHeader" type="HBoxContainer" parent="Center/Card/Box"]
layout_mode = 2

[node name="VolumeLabel" type="Label" parent="Center/Card/Box/VolumeHeader"]
layout_mode = 2
size_flags_horizontal = 3
text = "VOLUME GERAL"

[node name="VolumeValue" type="Label" parent="Center/Card/Box/VolumeHeader"]
layout_mode = 2
theme_override_colors/font_color = Color(1, 0.82, 0.45, 1)
text = "80%"

[node name="VolumeSlider" type="HSlider" parent="Center/Card/Box"]
layout_mode = 2
custom_minimum_size = Vector2(0, 48)
min_value = 0.0
max_value = 100.0
step = 1.0
value = 80.0

[node name="MuteButton" type="Button" parent="Center/Card/Box"]
layout_mode = 2
custom_minimum_size = Vector2(0, 56)
toggle_mode = true
text = "MUDO: DESATIVADO"

[node name="TestSoundButton" type="Button" parent="Center/Card/Box"]
layout_mode = 2
custom_minimum_size = Vector2(0, 56)
text = "TESTAR SOM"

[node name="SettingsNotice" type="Label" parent="Center/Card/Box"]
layout_mode = 2
theme_override_colors/font_color = Color(0.55, 0.67, 0.72, 1)
text = "Os ajustes são salvos automaticamente."

[node name="BackButton" type="Button" parent="Center/Card/Box"]
layout_mode = 2
custom_minimum_size = Vector2(0, 56)
theme_type_variation = &"PrimaryButton"
text = "<   VOLTAR AO MENU"

[node name="PreviewSound" type="AudioStreamPlayer" parent="."]
volume_db = -8.0
'''
(root/'scenes/ui/settings_menu.tscn').write_text(s,encoding='utf-8')
print('Updated HUD, main menu and settings scene.')
