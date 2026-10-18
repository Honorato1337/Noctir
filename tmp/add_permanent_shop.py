from pathlib import Path
import json
root = Path(__file__).resolve().parents[1]
def q(text): return json.dumps(text,ensure_ascii=False)
scene = '''[gd_scene format=3]
[ext_resource type="Theme" path="res://ui_theme.tres" id="1"]
[ext_resource type="Script" path="res://scripts/pixel_backdrop.gd" id="2"]
'''
def node(name,kind,parent,props):
    global scene
    scene += f'\n[node name="{name}" type="{kind}"'+(f' parent="{parent}"' if parent is not None else '')+']\n'+props+'\n'
    return name if parent=='.' else (parent+'/'+name if parent else '.')
def label(name,parent,text,size=22,color='0.88, 0.94, 0.96, 1',props=''):
    return node(name,'Label',parent,f'layout_mode = 2\nmouse_filter = 2\ntext = {q(text)}\ntheme_override_font_sizes/font_size = {size}\ntheme_override_colors/font_color = Color({color})\n'+props)
full='anchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\ngrow_horizontal = 2\ngrow_vertical = 2\n'
node('PermanentShop','Control',None,'layout_mode = 3\n'+full+'theme = ExtResource("1")\ntexture_filter = 1')
node('Backdrop','ColorRect','.','layout_mode = 1\n'+full+'mouse_filter = 2\ncolor = Color(0.008, 0.016, 0.03, 1)\nscript = ExtResource("2")')
node('Center','CenterContainer','.','layout_mode = 1\n'+full)
card=node('Card','PanelContainer','Center','layout_mode = 2\ncustom_minimum_size = Vector2(1024, 0)')
box=node('Box','VBoxContainer',card,'layout_mode = 2\ntheme_override_constants/separation = 12')
header=node('Header','HBoxContainer',box,'layout_mode = 2\ntheme_override_constants/separation = 20')
label('Title',header,'LOJA PERMANENTE',32,'0.44, 0.9, 0.82, 1','size_flags_horizontal = 3')
label('PermanentWallet',header,'SALDO   0 COINS',22,'1, 0.82, 0.45, 1')
label('PermanentProgress',box,'100 PONTOS = 1 COIN  /  Progresso acumulado: 0/100 pontos',color='0.55, 0.67, 0.72, 1')
grid=node('Upgrades','GridContainer',box,'layout_mode = 2\ncolumns = 3\ntheme_override_constants/h_separation = 12\ntheme_override_constants/v_separation = 12')
data=[('BLINDAGEM','+1 de vida máxima por nível'),('NÚCLEO DE PLASMA','+5% de dano inicial por nível'),('GATILHO REFINADO','+4% de cadência inicial por nível'),('BOTAS ORBITAIS','+4% de movimento por nível'),('PROPULSOR AUXILIAR','-6% de recarga do dash por nível'),('RESERVA TEMPORAL','+2 segundos por arena por nível')]
for index,(name,effect) in enumerate(data,1):
    # The entire card is a button. Decorative children pass mouse events through.
    button=node(f'PermanentBuy{index}','Button',grid,'layout_mode = 2\ncustom_minimum_size = Vector2(312, 202)\nsize_flags_horizontal = 3\ntext = ""')
    margin=node('Margin','MarginContainer',button,'layout_mode = 1\n'+full+'offset_left = 16.0\noffset_top = 14.0\noffset_right = -16.0\noffset_bottom = -14.0\nmouse_filter = 2')
    v=node('Box','VBoxContainer',margin,'layout_mode = 2\nmouse_filter = 2\ntheme_override_constants/separation = 8')
    label('Name',v,name,24,'0.44, 0.9, 0.82, 1')
    label('Effect',v,effect,props='autowrap_mode = 2\ncustom_minimum_size = Vector2(0, 44)')
    label(f'PermanentLevel{index}',v,'NÍVEL 0/3',color='0.55, 0.67, 0.72, 1',props='autowrap_mode = 2\nsize_flags_vertical = 3')
    label(f'PermanentCost{index}',v,'COMPRAR / 0 COINS',color='1, 0.82, 0.45, 1')
label('PermanentNotice',box,'Bônus permanentes para todas as próximas runs. Moedas da arena são separadas.',color='0.44, 0.9, 0.82, 1',props='autowrap_mode = 2\ncustom_minimum_size = Vector2(0, 28)')
node('BackButton','Button',box,'layout_mode = 2\ncustom_minimum_size = Vector2(0, 56)\ntheme_type_variation = &"PrimaryButton"\ntext = "<   VOLTAR AO MENU"')
(root/'scenes/ui/permanent_shop.tscn').write_text(scene,encoding='utf-8')

path=root/'scenes/ui/main_menu.tscn'
s=path.read_text(encoding='utf-8')
anchor='[node name="ControlsButton"'
at=s.index(anchor)
s=s[:at]+'''[node name="PermanentShopButton" type="Button" parent="Center/Layout/Content/Mission/Box"]
layout_mode = 2
custom_minimum_size = Vector2(0, 58)
text = "LOJA PERMANENTE   /   0 COINS"

'''+s[at:]
path.write_text(s,encoding='utf-8')

path=root/'scenes/ui/result_screen.tscn'
s=path.read_text(encoding='utf-8')
at=s.index('[node name="RestartButton"')
s=s[:at]+'''[node name="RewardValue" type="Label" parent="Center/Card/Box"]
layout_mode = 2
mouse_filter = 2
theme_override_font_sizes/font_size = 22
theme_override_colors/font_color = Color(1, 0.82, 0.45, 1)
text = "+0 COINS PERMANENTES / SALDO 0\\nProgresso para o próximo coin: 0/100 pontos"
autowrap_mode = 2

'''+s[at:]
at=s.index('[node name="MenuButton"')
s=s[:at]+'''[node name="PermanentShopButton" type="Button" parent="Center/Card/Box"]
layout_mode = 2
custom_minimum_size = Vector2(0, 52)
text = "GASTAR COINS NA LOJA PERMANENTE"

'''+s[at:]
path.write_text(s,encoding='utf-8')

# Test fixtures must opt out before _ready loads any real player progress.
for path in (root/'tests').glob('*.gd'):
    s=path.read_text(encoding='utf-8')
    s=s.replace('\troot.add_child(game)\n\tgame.smoke_mode = true','\tgame.smoke_mode = true\n\troot.add_child(game)')
    if path.name=='preview.gd':
        s=s.replace('\troot.add_child(game)','\tgame.smoke_mode = true\n\troot.add_child(game)')
    path.write_text(s,encoding='utf-8')
print('Added permanent shop, menu access, result rewards and isolated test profiles.')
