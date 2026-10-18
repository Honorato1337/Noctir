from pathlib import Path
p = Path('scripts/game.gd')
s = p.read_text(encoding='utf-8')
s = s.replace('preload("res://scripts/player.gd")', 'preload("res://scenes/actors/player.tscn")').replace('preload("res://scripts/enemy.gd")', 'preload("res://scenes/actors/enemy.tscn")').replace('preload("res://scripts/projectile.gd")', 'preload("res://scenes/actors/projectile.tscn")')
s = s.replace('const ARENAS_PER_PLANET', '''const SCREENS = {
	"menu": preload("res://scenes/ui/main_menu.tscn"),
	"controls": preload("res://scenes/ui/controls.tscn"),
	"pause": preload("res://scenes/ui/pause_menu.tscn"),
	"upgrade": preload("res://scenes/ui/upgrade_screen.tscn"),
	"result": preload("res://scenes/ui/result_screen.tscn")
}
const ARENAS_PER_PLANET''')
start = s.index('\tenemies = Node2D.new()')
end = s.index('\tvar save := ConfigFile.new()', start)
s = s[:start] + '''	enemies = $Enemies
	bullets = $Projectiles
	layer = $UI
	# This instance is visible when opening main.tscn in the editor.
	panel = $UI/ScreenHost/MainMenu
''' + s[end:]
s = s.replace('Player.new()', 'Player.instantiate()').replace('Enemy.new()', 'Enemy.instantiate()').replace('Projectile.new()', 'Projectile.instantiate()')
start = s.index('\tobstacles.clear()', s.index('func start_room'))
end = s.index('\tplayer.history.clear()', start)
s = s[:start] + '\t$Arena.apply_to(self)\n' + s[end:]
s = s.replace('make_panel("PAUSA", "Respire. O relógio também parou.")\n\t\t\tadd_button("CONTINUAR", func(): state = previous; close_panel())\n\t\t\tadd_button("RECOMEÇAR", start_run)', '''show_screen("pause")
			bind_button("ResumeButton", func(): state = previous; close_panel())
			bind_button("RestartButton", start_run)
			bind_button("MenuButton", show_menu)''')
s = s.replace('var gates := [Vector2(100, 180), Vector2(1050, 180), Vector2(100, 590), Vector2(1050, 590)]', 'var gates: Array[Vector2] = $Arena.spawn_gates()')
s = s.replace('enemy.position = Vector2(960, 386) if is_boss else gates[0]', 'enemy.position = $Arena/BossSpawn.global_position if is_boss else gates[0]')
s = s.replace('make_panel("ARENA CONCLUÍDA", "Escolha uma melhoria. Ela dura somente nesta tentativa.")', 'show_screen("upgrade")')
s = s.replace('add_button(upgrade.name + "\\n" + upgrade.desc, func(): apply_upgrade(upgrade.key); close_panel(); state = "exit")', '''var button: Button = panel.find_child("Choice%d" % (i + 1), true, false)
		button.text = upgrade.name + "\\n" + upgrade.desc
		button.pressed.connect(func(): apply_upgrade(upgrade.key); close_panel(); state = "exit")''')
start = s.index('\tmake_panel("ÓRBITA COMPLETA"')
end = s.index('func text_at(', start)
s = s[:start] + '''	show_screen("result")
	panel.find_child("Title", true, false).text = "ÓRBITA COMPLETA" if won else "SÓ MAIS UMA VEZ?"
	panel.find_child("Description", true, false).text = reason + "\\n\\nPontos: %d    Recorde: %d    Abates: %d\\nArena: %d/9    Tempo: %ds" % [score, best, kills, room + 1, int(elapsed)]
	bind_button("RestartButton", start_run)
	bind_button("MenuButton", show_menu)

func show_menu() -> void:
	state = "menu"
	show_screen("menu")
	bind_button("StartButton", start_run)
	bind_button("ControlsButton", show_controls)

func show_controls() -> void:
	show_screen("controls")
	bind_button("BackButton", show_menu)

func close_panel() -> void:
	if is_instance_valid(panel):
		panel.get_parent().remove_child(panel)
		panel.queue_free()
	panel = null

func show_screen(screen_name: String) -> void:
	close_panel()
	panel = SCREENS[screen_name].instantiate()
	$UI/ScreenHost.add_child(panel)

func bind_button(node_name: String, action: Callable) -> void:
	var button: Button = panel.find_child(node_name, true, false)
	button.pressed.connect(action)

func _process(_delta: float) -> void:
	$UI/HUD.update_game(self)

''' + s[end:]
s = s.replace('\tdraw_rect(Rect2(0, 0, 1152, 720), Color("080e20"))\n', '')
start = s.index('\tdraw_rect(arena.grow(10)')
end = s.index('\tfor hazard in hazards:', start)
s = s[:start] + s[end:]
start = s.index('\ttext_at(Vector2(64, 47)')
end = s.index('\t\tif state == "exit":', start)
s = s[:start] + '\tif is_instance_valid(player):\n' + s[end:]
s = s.replace('\t\t\ttext_at(Vector2(850, 452), "APROXIME-SE + E", 16, Color("71e4c5"))\n', '')
s = s.replace('\tif message_time > 0 and state == "playing":\n\t\ttext_at(Vector2(200, 170), message, 19, planet().accent)\n', '')
p.write_text(s, encoding='utf-8')

p = Path('scenes/main.tscn')
s = p.read_text(encoding='utf-8').replace('[node name="Arena" parent="." instance=ExtResource("2")]','''[node name="Background" type="ColorRect" parent="."]
z_index = -2
offset_right = 1152.0
offset_bottom = 720.0
mouse_filter = 2
color = Color(0.03, 0.05, 0.1, 1)

[node name="Arena" parent="." instance=ExtResource("2")]
z_index = -1''')
p.write_text(s, encoding='utf-8')

p = Path('tests/smoke.gd')
s = p.read_text(encoding='utf-8').replace('game.panel.get_node("Box").get_child(2).pressed.emit()', 'game.panel.find_child("Choice1", true, false).pressed.emit()')
p.write_text(s, encoding='utf-8')
