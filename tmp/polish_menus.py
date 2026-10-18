from pathlib import Path
import json, shutil

root = Path(__file__).resolve().parents[1]
files = ['ui_theme.tres', 'scripts/game.gd'] + [f'scenes/ui/{n}.tscn' for n in ['main_menu','controls','pause_menu','result_screen','shop_screen']]
for name in files:
    dest = root / 'tmp/ui-before-menu-polish' / name
    if not dest.exists():
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(root / name, dest)

def q(s): return json.dumps(s, ensure_ascii=False)
def style(name, bg, border, margin=16):
    return f'''[sub_resource type="StyleBoxFlat" id="{name}"]
content_margin_left = {margin}.0
content_margin_top = {margin}.0
content_margin_right = {margin}.0
content_margin_bottom = {margin}.0
bg_color = Color({bg})
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color({border})
'''
theme = '[gd_resource type="Theme" format=3]\n\n[ext_resource type="FontFile" path="res://fonts/w95fa/W95F.otf" id="1_font"]\n\n'
for args in [('Normal','0.025, 0.045, 0.065, 1','0.22, 0.32, 0.37, 1'),('Hover','0.06, 0.16, 0.18, 1','0.44, 0.9, 0.82, 1'),('Focus','0, 0, 0, 0','1, 0.82, 0.45, 1'),('Disabled','0.02, 0.03, 0.04, 1','0.12, 0.19, 0.22, 1'),('Card','0.015, 0.025, 0.04, 1','0.16, 0.25, 0.3, 1',24),('Primary','0.44, 0.9, 0.82, 1','0.44, 0.9, 0.82, 1'),('PrimaryHover','0.65, 1, 0.9, 1','0.65, 1, 0.9, 1'),('BossBackground','0.07, 0.11, 0.18, 1','0.07, 0.11, 0.18, 1',0),('BossFill','0.95, 0.35, 0.46, 1','0.95, 0.35, 0.46, 1',0)]:
    theme += style(*args)+'\n'
theme += '''[resource]
default_font = ExtResource("1_font")
default_font_size = 22
Button/styles/normal = SubResource("Normal")
Button/styles/hover = SubResource("Hover")
Button/styles/pressed = SubResource("Hover")
Button/styles/focus = SubResource("Focus")
Button/styles/disabled = SubResource("Disabled")
Button/colors/font_color = Color(0.88, 0.94, 0.96, 1)
Button/colors/font_disabled_color = Color(0.45, 0.55, 0.58, 1)
PrimaryButton/base_type = &"Button"
PrimaryButton/styles/normal = SubResource("Primary")
PrimaryButton/styles/hover = SubResource("PrimaryHover")
PrimaryButton/styles/pressed = SubResource("PrimaryHover")
PrimaryButton/colors/font_color = Color(0.015, 0.05, 0.06, 1)
PrimaryButton/colors/font_hover_color = Color(0.015, 0.05, 0.06, 1)
PrimaryButton/colors/font_pressed_color = Color(0.015, 0.05, 0.06, 1)
PrimaryButton/colors/font_focus_color = Color(0.015, 0.05, 0.06, 1)
Label/colors/font_color = Color(0.88, 0.94, 0.96, 1)
PanelContainer/styles/panel = SubResource("Card")
ProgressBar/styles/background = SubResource("BossBackground")
ProgressBar/styles/fill = SubResource("BossFill")
'''
(root/'ui_theme.tres').write_text(theme,encoding='utf-8')

class Scene:
    def __init__(self,name,extra=''):
        self.s = '[gd_scene format=3]\n\n[ext_resource type="Theme" path="res://ui_theme.tres" id="1"]\n[ext_resource type="Script" path="res://scripts/pixel_backdrop.gd" id="2"]\n'+extra+'\n'
        full='anchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\ngrow_horizontal = 2\ngrow_vertical = 2\n'
        self.node(name,'Control',None,'layout_mode = 3\n'+full+'theme = ExtResource("1")\ntexture_filter = 1')
        self.node('Backdrop','ColorRect','.','layout_mode = 1\n'+full+'mouse_filter = 2\ncolor = Color(0.008, 0.016, 0.03, 1)\nscript = ExtResource("2")')
        self.node('Center','CenterContainer','.','layout_mode = 1\n'+full)
    def node(self,name,kind,parent,props=''):
        self.s += f'\n[node name="{name}" type="{kind}"'+(f' parent="{parent}"' if parent is not None else '')+']\n'+props+'\n'
        return name if parent=='.' else (parent+'/'+name if parent else '.')
    def box(self,name,parent,kind='VBoxContainer',props=''):
        return self.node(name,kind,parent,'layout_mode = 2\ntheme_override_constants/separation = 14\n'+props)
    def card(self,name,parent,width=0):
        return self.node(name,'PanelContainer',parent,f'layout_mode = 2\ncustom_minimum_size = Vector2({width}, 0)')
    def label(self,name,parent,text,size=22,color=None,props=''):
        return self.node(name,'Label',parent,'layout_mode = 2\nmouse_filter = 2\n'+f'theme_override_font_sizes/font_size = {size}\ntext = {q(text)}\n'+(f'theme_override_colors/font_color = Color({color})\n' if color else '')+props)
    def button(self,name,parent,text,primary=False,props=''):
        return self.node(name,'Button',parent,'layout_mode = 2\ncustom_minimum_size = Vector2(0, 58)\n'+f'text = {q(text)}\n'+('theme_type_variation = &"PrimaryButton"\n' if primary else '')+props)
    def save(self,name): (root/f'scenes/ui/{name}.tscn').write_text(self.s,encoding='utf-8')

cyan='0.44, 0.9, 0.82, 1'; muted='0.55, 0.67, 0.72, 1'; gold='1, 0.82, 0.45, 1'
s=Scene('MainMenu','[ext_resource type="FontFile" path="res://fonts/after_burner_neue/After Burner Neue.ttf" id="3"]\n[ext_resource type="SpriteFrames" path="res://asssets/astronauta/astronaut_frames.tres" id="4"]\n')
outer=s.box('Layout','Center',props='custom_minimum_size = Vector2(1024, 0)\ntheme_override_constants/separation = 24')
s.label('Eyebrow',outer,'ONE MORE ORBIT    /    ONE MORE TIME',color=muted)
row=s.box('Content',outer,'HBoxContainer','theme_override_constants/separation = 24')
left=s.card('Mission',row,640); box=s.box('Box',left,props='theme_override_constants/separation = 22')
s.label('Tag',box,'01   /   EXPEDIÇÃO INTERPLANETÁRIA',color=cyan)
s.label('Title',box,'Os meninos do bom',36,cyan,'theme_override_fonts/font = ExtResource("3")')
s.label('Description',box,'Um traje. Doze arenas.\nCinco segundos para mudar tudo.',props='custom_minimum_size = Vector2(560, 72)\nvertical_alignment = 1')
s.button('StartButton',box,'INICIAR EXPEDIÇÃO   >',True)
s.button('ControlsButton',box,'COMO JOGAR')
s.label('Record',box,'RECORDE   000000',color=gold)
right=s.card('Astronaut',row,360); rb=s.box('Box',right)
s.label('Pilot',rb,'PILOTO  /  PRONTO',color=cyan)
hero=s.node('Preview','Control',rb,'layout_mode = 2\ncustom_minimum_size = Vector2(0, 208)\nmouse_filter = 2')
s.node('Platform','ColorRect',hero,'offset_left = 56.0\noffset_top = 172.0\noffset_right = 256.0\noffset_bottom = 180.0\ncolor = Color(0.16, 0.3, 0.34, 1)\nmouse_filter = 2')
s.node('AstronautSprite','AnimatedSprite2D',hero,'position = Vector2(156, 91)\nscale = Vector2(6, 6)\nsprite_frames = ExtResource("4")\nanimation = &"walk"\nautoplay = "walk"')
s.label('Protocol',rb,'PROTOCOLO ECO',color=cyan)
s.label('EchoInfo',rb,'[Q] Volte 5 segundos.\nSeu eco continua atirando.',props='autowrap_mode = 2\ncustom_minimum_size = Vector2(300, 64)')
s.label('InventoryInfo',rb,'[1]  [2]  Dois itens.\nEscolha quando usar.',color=muted)
route=s.box('Route',outer,'HBoxContainer','theme_override_constants/separation = 16')
for name,text,col in [('Mars','01—04   MARTE','0.95, 0.6, 0.44, 1'),('Venus','05—08   VÊNUS',gold),('Jupiter','09—12   JÚPITER','0.7, 0.64, 1, 1')]:
    c=s.card(name,route); s.s += 'size_flags_horizontal = 3\n'
    s.label('Name',c,text,color=col,props='horizontal_alignment = 1')
s.save('main_menu')

s=Scene('ShopScreen')
c=s.card('Card','Center',1024); b=s.box('Box',c,props='theme_override_constants/separation = 10')
head=s.box('Header',b,'HBoxContainer')
s.label('Title',head,'LOJA ORBITAL',32,cyan,'size_flags_horizontal = 3')
s.label('Wallet',head,'MOEDAS   000',color=gold)
s.label('ShopPhase',b,'ARENA CONCLUÍDA  /  Prepare o traje para a próxima horda.',color=muted)
cards=s.box('Modules',b,'HBoxContainer','theme_override_constants/separation = 12')
for i in range(1,4):
    button=s.button(f'Choice{i}',cards,'',props='custom_minimum_size = Vector2(0, 180)\nsize_flags_horizontal = 3\nmouse_default_cursor_shape = 2')
    margin=s.node('Margin','MarginContainer',button,'layout_mode = 1\nanchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\noffset_left = 18.0\noffset_top = 16.0\noffset_right = -18.0\noffset_bottom = -16.0\nmouse_filter = 2')
    v=s.box('Box',margin,props='mouse_filter = 2\ntheme_override_constants/separation = 12')
    s.label(f'ModuleTitle{i}',v,'MÓDULO',26,cyan)
    s.label(f'ModuleDesc{i}',v,'Melhoria permanente\npara esta expedição.',props='size_flags_vertical = 3\nautowrap_mode = 2')
    s.label(f'ModuleCost{i}',v,'22 MOEDAS',color=gold)
s.label('SupplyTitle',b,'SUPRIMENTOS   /   Reparos são imediatos. Itens ocupam um slot.',color=muted)
sup=s.box('Supplies',b,'HBoxContainer','theme_override_constants/separation = 8')
for name,text,icon in [('RepairButton','Reparo +2  /  14','medkit'),('BombButton','Bomba  /  18','bomb'),('ShieldButton','Escudo  /  18','shield'),('OverdriveButton','Sobrecarga  /  18','overdrive')]:
    # Resources can be declared anywhere before node sections.
    ext=f'[ext_resource type="Texture2D" path="res://assets/icons/{icon}.svg" id="{icon}"]\n'
    s.s=s.s.replace('\n[node name="ShopScreen"', '\n'+ext+'\n[node name="ShopScreen"',1)
    s.button(name,sup,text,props=f'size_flags_horizontal = 3\nicon = ExtResource("{icon}")\nicon_max_width = 24\ntheme_override_constants/h_separation = 10')
inv=s.box('Inventory',b,'HBoxContainer','theme_override_constants/separation = 12')
s.label('InventoryTitle',inv,'CARGA  /  [1] e [2]',color=muted,props='custom_minimum_size = Vector2(220, 64)\nvertical_alignment = 1')
for i in (1,2):
    slot=s.node(f'StoreSlot{i}','ColorRect',inv,'layout_mode = 2\ncustom_minimum_size = Vector2(64, 64)\ncolor = Color(0, 0, 0, 1)\nmouse_filter = 2')
    s.node(f'StoreIcon{i}','TextureRect',slot,'offset_left = 12.0\noffset_top = 12.0\noffset_right = 52.0\noffset_bottom = 52.0\nexpand_mode = 1\nstretch_mode = 5\nmouse_filter = 2')
s.label('InventoryHint',inv,'Dois slots disponíveis.\nItens são usados durante o combate.',color=muted,props='size_flags_horizontal = 3\nvertical_alignment = 1')
s.label('Notice',b,'Cada módulo pode ser comprado uma vez nesta parada.',color=cyan,props='custom_minimum_size = Vector2(0, 28)')
s.button('LeaveButton',b,'CONTINUAR PARA A EXTRAÇÃO   >',True)
s.save('shop_screen')

s=Scene('Controls')
c=s.card('Card','Center',960); b=s.box('Box',c,props='theme_override_constants/separation = 20')
s.label('Title',b,'MANUAL DO PILOTO',36,cyan)
s.label('Description',b,'Elimine a horda e o guardião. Compre melhorias. Siga para a extração.',color=muted)
row=s.box('Instructions',b,'HBoxContainer','theme_override_constants/separation = 24')
for name,heading,body in [('Movement','MOVIMENTO E COMBATE','[W A S D]   Mover\n[Mouse]   Mirar e atirar\n[Setas]   Atirar em quatro direções\n[Espaço]   Dash com invulnerabilidade\n[Esc]   Pausar'),('Equipment','EQUIPAMENTO E ECO','[Q]   Voltar 5s e criar um eco\n[1] [2]   Usar os itens dos slots\n[E]   Extrair perto do portal\n\nO eco repete seus tiros.\nUma carga de eco por arena.')]:
    col=s.box(name,row,props='size_flags_horizontal = 3')
    s.label('Heading',col,heading,color=cyan)
    s.label('Keys',col,body,props='theme_override_constants/line_spacing = 10')
s.label('Tip',b,'Moedas são recolhidas ao encerrar a arena. Proteja seus dois slots.',color=gold)
s.button('BackButton',b,'<   VOLTAR AO MENU',True)
s.save('controls')

s=Scene('PauseMenu')
c=s.card('Card','Center',640); b=s.box('Box',c,props='theme_override_constants/separation = 18')
s.label('Tag',b,'SINAL EM ESPERA',color=muted)
s.label('Title',b,'EXPEDIÇÃO PAUSADA',36,cyan)
s.label('Description',b,'O relógio parou. Respire e prepare o próximo movimento.',props='autowrap_mode = 2\ncustom_minimum_size = Vector2(590, 64)')
s.button('ResumeButton',b,'RETOMAR EXPEDIÇÃO   >',True)
s.button('RestartButton',b,'TENTAR NOVAMENTE')
s.button('MenuButton',b,'VOLTAR AO MENU')
s.label('Hint',b,'[ESC]  Retomar',color=muted)
s.save('pause_menu')

s=Scene('ResultScreen')
c=s.card('Card','Center',800); b=s.box('Box',c,props='theme_override_constants/separation = 20')
s.label('Status',b,'RELATÓRIO DA EXPEDIÇÃO',color=muted)
s.label('Title',b,'SÓ MAIS UMA VEZ?',36,cyan)
s.label('Description',b,'A janela de extração fechou.',props='custom_minimum_size = Vector2(750, 56)\nautowrap_mode = 2')
stats=s.box('Stats',b,'HBoxContainer','theme_override_constants/separation = 24')
for n,t in [('Score','PONTOS'),('Best','RECORDE'),('Kills','ABATES'),('Arena','ARENA')]:
    col=s.box(n,stats,props='size_flags_horizontal = 3')
    s.label('Caption',col,t,color=muted)
    s.label(n+'Value',col,'00000',32,gold if n=='Best' else cyan)
s.label('TimeValue',b,'TEMPO DE MISSÃO   00:00',color=muted)
s.button('RestartButton',b,'MAIS UMA TENTATIVA   >',True)
s.button('MenuButton',b,'VOLTAR AO MENU')
s.save('result_screen')
print('Updated theme and five editable menu scenes.')
