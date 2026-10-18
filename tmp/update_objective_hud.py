from pathlib import Path
import json

def node(name,kind,parent=None,props=''):
 return f'\n[node name="{name}" type="{kind}"'+(f' parent="{parent}"' if parent is not None else '')+f']\n{props}\n'
def rect(l,t,r,b):
 return f'offset_left = {l}.0\noffset_top = {t}.0\noffset_right = {r}.0\noffset_bottom = {b}.0'
def label(name,parent,text,l,t,r,b,extra='',unique=True):
 return node(name,'Label',parent,('unique_name_in_owner = true\n' if unique else '')+rect(l,t,r,b)+'\nmouse_filter = 2\ntheme_override_font_sizes/font_size = 22\ntext = '+json.dumps(text,ensure_ascii=False)+'\n'+extra)
s='[gd_scene load_steps=3 format=3]\n[ext_resource type="Theme" path="res://ui_theme.tres" id="1"]\n[ext_resource type="Script" path="res://scripts/hud.gd" id="2"]\n'
s+=node('HUD','Control',props='layout_mode = 3\nanchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\ngrow_horizontal = 2\ngrow_vertical = 2\nmouse_filter = 2\ntexture_filter = 1\ntheme = ExtResource("1")\nscript = ExtResource("2")')
s+=node('TopBar','ColorRect','.',rect(64,16,1088,88)+'\nmouse_filter = 2\ncolor = Color(0.018, 0.026, 0.045, 0.98)')
s+=label('Planet','.','MARTE • 1/12',76,22,316,50)
s+=label('Timer','.','01:45',340,22,456,50)
s+=label('Health','.','VIDA 5/5',480,22,644,50)
s+=label('Coins','.','MOEDAS 0',672,22,926,50,'theme_override_colors/font_color = Color(1, 0.85, 0.4, 1)')
s+=label('Echo','.','[Q] ECO PRONTO',76,56,316,84,'theme_override_colors/font_color = Color(0.44, 0.9, 0.82, 1)')
s+=label('Counters','.','INIMIGOS 0 (+36)',340,56,644,84)
s+=label('Score','.','PONTOS 00000',672,56,926,84)
for name,x,key in [('SlotOne',944,'1'),('SlotTwo',1020,'2')]:
 s+=node(name,'ColorRect','.',rect(x,20,x+64,84)+'\nmouse_filter = 2\ncolor = Color(0, 0, 0, 1)')
 s+=node(name+'Icon','TextureRect',name,'unique_name_in_owner = true\n'+rect(16,4,48,36)+'\nmouse_filter = 2\ntexture_filter = 1\nexpand_mode = 1\nstretch_mode = 5')
 s+=label('Key',name,key,0,36,64,64,'horizontal_alignment = 1',unique=False)
s+=label('Message','.','',128,112,1024,146,'horizontal_alignment = 1')
s+=label('Extract','.','[E] EXTRAIR',848,430,1080,460)
s+=node('BossBar','ProgressBar','.', 'unique_name_in_owner = true\n'+rect(276,92,876,102)+'\nmouse_filter = 2\nshow_percentage = false\nvalue = 100.0')
Path('scenes/ui/hud.tscn').write_text(s,encoding='utf-8')
