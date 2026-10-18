from pathlib import Path

def write(path, text):
    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text, encoding='utf-8')

def node(name, kind, parent=None, props=''):
    parent_text = f' parent="{parent}"' if parent is not None else ''
    return f'\n[node name="{name}" type="{kind}"{parent_text}]\n{props}\n'

full = 'layout_mode = 3\nanchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\ngrow_horizontal = 2\ngrow_vertical = 2'
header = '[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Theme" path="res://ui_theme.tres" id="1"]\n'

theme = '[gd_resource type="Theme" load_steps=5 format=3]\n'
for name, color, border in [('Normal', '0.08, 0.17, 0.25, 1', '0.34, 0.55, 0.58, 1'), ('Hover', '0.16, 0.32, 0.41, 1', '0.44, 0.9, 0.82, 1'), ('Focus', '0, 0, 0, 0', '1, 0.86, 0.58, 1'), ('Card', '0.035, 0.065, 0.12, 0.98', '0.16, 0.28, 0.38, 1')]:
    theme += f'\n[sub_resource type="StyleBoxFlat" id="{name}"]\nbg_color = Color({color})\nborder_color = Color({border})\n'
    for side in ['left', 'top', 'right', 'bottom']:
        theme += f'border_width_{side} = 1\ncontent_margin_{side} = {28.0 if name == "Card" else 12.0}\n'
    for corner in ['top_left', 'top_right', 'bottom_left', 'bottom_right']:
        theme += f'corner_radius_{corner} = 8\n'
theme += '\n[resource]\ndefault_font_size = 18\nLabel/colors/font_color = Color(0.88, 0.92, 0.97, 1)\n'
for kind, style in [('normal', 'Normal'), ('hover', 'Hover'), ('pressed', 'Hover'), ('focus', 'Focus')]:
    theme += f'Button/styles/{kind} = SubResource("{style}")\n'
theme += 'PanelContainer/styles/panel = SubResource("Card")\n'
write('ui_theme.tres', theme)

def label(name, parent, text, size=18, extra=''):
    import json
    return node(name, 'Label', parent, 'layout_mode = 2\n' + f'theme_override_font_sizes/font_size = {size}\ntext = {json.dumps(text, ensure_ascii=False)}\nhorizontal_alignment = 1\n' + extra)

def button(name, text, parent='Center/Card/Box'):
    import json
    return node(name, 'Button', parent, 'layout_mode = 2\ncustom_minimum_size = Vector2(0, 62)\ntext = ' + json.dumps(text, ensure_ascii=False))

screens = [
    ('main_menu', 'MainMenu', 'NOCTIR', 'ONE MORE ORBIT\n\nUm traje. Nove arenas.\nCinco segundos para mudar tudo.', [('StartButton', 'INICIAR EXPEDIÇÃO'), ('ControlsButton', 'COMO JOGAR')]),
    ('controls', 'Controls', 'COMO JOGAR', 'WASD: movimento\nMouse + clique ou setas: disparar\nEspaço: dash com invulnerabilidade\nQ: recuperar até 5 segundos + criar eco\nE: entrar no portal de extração\nEsc: pausar\n\nElimine a horda antes do tempo acabar.\nO eco repete seus tiros. Uma carga por arena.', [('BackButton', 'VOLTAR AO MENU')]),
    ('pause_menu', 'PauseMenu', 'PAUSA', 'Respire. O relógio também parou.', [('ResumeButton', 'CONTINUAR'), ('RestartButton', 'RECOMEÇAR'), ('MenuButton', 'VOLTAR AO MENU')]),
    ('upgrade_screen', 'UpgradeScreen', 'ARENA CONCLUÍDA', 'Escolha uma melhoria para esta tentativa.', [('Choice1', 'PRISMA\n+2 projéteis em leque\nDano por projétil -15%'), ('Choice2', 'TRAJE\n+1 vida máxima\nRecupera 2 de vida'), ('Choice3', 'PLASMA\nDano +35%\nProjéteis maiores')]),
    ('result_screen', 'ResultScreen', 'SÓ MAIS UMA VEZ?', 'Resultado da expedição\n\nPontos: 00000    Recorde: 00000\nArena: 1/9', [('RestartButton', 'TENTAR NOVAMENTE   [R]'), ('MenuButton', 'VOLTAR AO MENU')]),
]
for filename, root_name, title, description, buttons in screens:
    scene = header + node(root_name, 'Control', props=full + '\ntheme = ExtResource("1")')
    scene += node('Backdrop', 'ColorRect', '.', full + '\nmouse_filter = 2\ncolor = Color(0.02, 0.035, 0.07, 0.96)')
    scene += node('Center', 'CenterContainer', '.', full + '\nmouse_filter = 2')
    scene += node('Card', 'PanelContainer', 'Center', 'layout_mode = 2\ncustom_minimum_size = Vector2(660, 0)')
    scene += node('Box', 'VBoxContainer', 'Center/Card', 'layout_mode = 2\ntheme_override_constants/separation = 16')
    scene += label('Title', 'Center/Card/Box', title, 42, 'theme_override_colors/font_color = Color(0.44, 0.9, 0.82, 1)')
    scene += label('Description', 'Center/Card/Box', description, 18, 'autowrap_mode = 2\ncustom_minimum_size = Vector2(600, 0)')
    for name, text in buttons:
        scene += button(name, text)
    if filename == 'main_menu':
        scene += label('Footer', 'Center/Card/Box', 'PROTÓTIPO DA JAM  /  ONE MORE TIME', 13)
    write(f'scenes/ui/{filename}.tscn', scene)

# HUD: controls retain their authored positions; code only changes text/visibility.
hud = '[gd_scene load_steps=3 format=3]\n[ext_resource type="Theme" path="res://ui_theme.tres" id="1"]\n[ext_resource type="Script" path="res://scripts/hud.gd" id="2"]\n'
hud += node('HUD', 'Control', props=full + '\nmouse_filter = 2\ntheme = ExtResource("1")\nscript = ExtResource("2")')
items = [
    ('Brand', 64, 16, 300, 54, 'N O C T I R', 28),
    ('Planet', 64, 58, 410, 87, 'MARTE / ARENA 01', 16),
    ('Timer', 450, 16, 590, 60, '00:40', 32),
    ('Score', 660, 17, 885, 48, 'PONTOS 00000', 20),
    ('Record', 900, 19, 1100, 47, 'RECORDE 00000', 18),
    ('Health', 660, 59, 880, 86, 'TRAJE 5 / 5', 16),
    ('Echo', 900, 59, 1100, 86, 'Q / ECO PRONTO', 16),
    ('Hazard', 64, 92, 1090, 118, 'CRATERAS • use os pilares como cobertura', 15),
    ('Message', 200, 148, 1050, 179, 'MARTE / Colônia Ferrugem', 19),
    ('Controls', 64, 653, 1090, 681, 'WASD mover  /  Mouse ou setas atirar  /  Espaço dash  /  Q eco  /  Esc pausa', 16),
    ('Counters', 64, 682, 1090, 710, 'HOSTIS 00  •  REFORÇOS 07  •  MÓDULOS 00', 14),
    ('Extract', 850, 430, 1080, 461, 'APROXIME-SE + E', 16),
]
import json
for name, l, t, r, b, text, size in items:
    hud += node(name, 'Label', '.', f'unique_name_in_owner = true\noffset_left = {l}.0\noffset_top = {t}.0\noffset_right = {r}.0\noffset_bottom = {b}.0\nmouse_filter = 2\ntheme_override_font_sizes/font_size = {size}\ntext = {json.dumps(text, ensure_ascii=False)}')
write('scenes/ui/hud.tscn', hud)

world = '[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://scripts/arena_layout.gd" id="1"]\n'
world += node('Arena', 'Node2D', props='script = ExtResource("1")')
world += node('Floor', 'ColorRect', '.', 'offset_left = 64.0\noffset_top = 136.0\noffset_right = 1088.0\noffset_bottom = 636.0\nmouse_filter = 2\ncolor = Color(0.16, 0.12, 0.16, 1)')
world += node('Border', 'Line2D', '.', 'points = PackedVector2Array(64, 136, 1088, 136, 1088, 636, 64, 636, 64, 136)\nwidth = 2.0\ndefault_color = Color(0.95, 0.61, 0.44, 0.6)')
world += node('Obstacles', 'Node2D', '.')
for name, l, t, r, b in [('PillarA', 325, 270, 397, 358), ('PillarB', 730, 410, 818, 476)]:
    world += node(name, 'ColorRect', 'Obstacles', f'offset_left = {l}.0\noffset_top = {t}.0\noffset_right = {r}.0\noffset_bottom = {b}.0\nmouse_filter = 2\ncolor = Color(0.4, 0.3, 0.28, 1)')
for name, x, y in [('PlayerSpawn', 166, 386), ('Portal', 1038, 386), ('BossSpawn', 960, 386)]:
    world += node(name, 'Marker2D', '.', f'position = Vector2({x}, {y})\ngizmo_extents = 24.0')
world += node('SpawnGates', 'Node2D', '.')
for name, x, y in [('NorthWest', 100, 180), ('NorthEast', 1050, 180), ('SouthWest', 100, 590), ('SouthEast', 1050, 590)]:
    world += node(name, 'Marker2D', 'SpawnGates', f'position = Vector2({x}, {y})')
world += node('Hazards', 'Node2D', '.')
for name, x, y in [('AcidA', 530, 270), ('AcidB', 630, 500)]:
    world += node(name, 'Marker2D', 'Hazards', f'position = Vector2({x}, {y})\ngizmo_extents = 54.0')
write('scenes/world/arena.tscn', world)

for filename, script in [('player', 'player'), ('enemy', 'enemy'), ('projectile', 'projectile')]:
    actor = f'[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://scripts/{script}.gd" id="1"]\n'
    actor += node(filename.title(), 'Node2D', props='script = ExtResource("1")')
    write(f'scenes/actors/{filename}.tscn', actor)

main = '[gd_scene load_steps=5 format=3]\n'
for idx, kind, path in [('1', 'Script', 'scripts/game.gd'), ('2', 'PackedScene', 'scenes/world/arena.tscn'), ('3', 'PackedScene', 'scenes/ui/hud.tscn'), ('4', 'PackedScene', 'scenes/ui/main_menu.tscn')]:
    main += f'[ext_resource type="{kind}" path="res://{path}" id="{idx}"]\n'
main += node('Noctir', 'Node2D', props='script = ExtResource("1")')
main += '\n[node name="Arena" parent="." instance=ExtResource("2")]\n'
main += node('Enemies', 'Node2D', '.') + node('Projectiles', 'Node2D', '.')
main += node('UI', 'CanvasLayer', '.')
main += '\n[node name="HUD" parent="UI" instance=ExtResource("3")]\n'
main += node('ScreenHost', 'Control', 'UI', full + '\nmouse_filter = 2')
main += '\n[node name="MainMenu" parent="UI/ScreenHost" instance=ExtResource("4")]\n'
write('scenes/main.tscn', main)
