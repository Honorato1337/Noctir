from pathlib import Path
import re
p=Path('ui_theme.tres');s=p.read_text(encoding='utf-8').replace('res://fonts/after_burner_neue/After Burner Neue.ttf','res://fonts/w95fa/W95F.otf');p.write_text(s,encoding='utf-8')
p=Path('scenes/ui/main_menu.tscn');s=p.read_text(encoding='utf-8');s=s.replace('load_steps=3','load_steps=4');pos=s.index('[node ');s=s[:pos]+'[ext_resource type="FontFile" path="res://fonts/after_burner_neue/After Burner Neue.ttf" id="3_title"]\n\n'+s[pos:];s=s.replace('theme_override_font_sizes/font_size = 36','theme_override_fonts/font = ExtResource("3_title")\ntheme_override_font_sizes/font_size = 36',1);p.write_text(s,encoding='utf-8')

p=Path('scenes/main.tscn');s=p.read_text(encoding='utf-8').replace('load_steps=5','load_steps=7');pos=s.index('[node ');s=s[:pos]+'[ext_resource type="Script" path="res://scripts/loot_system.gd" id="5_loot"]\n[ext_resource type="Script" path="res://scripts/combat_fx.gd" id="6_fx"]\n\n'+s[pos:];s+='''
[node name="Loot" type="Node2D" parent="."]
z_index = 2
script = ExtResource("5_loot")

[node name="CombatFX" type="Node2D" parent="."]
z_index = 4
script = ExtResource("6_fx")

[node name="Camera2D" type="Camera2D" parent="."]
position = Vector2(576, 360)
position_smoothing_enabled = false
''';p.write_text(s,encoding='utf-8')

p=Path('scripts/game.gd');s=p.read_text(encoding='utf-8')
s=s.replace('"upgrade": preload(', '"shop": preload("res://scenes/ui/shop_screen.tscn"),\n\t"upgrade": preload(')
s=s.replace('var smoke_mode := false','''var smoke_mode := false
var loot: Node2D
var fx: Node2D
var boss_spawned := false
var boss_ref: Node2D
var boss_summon_cd := 7.0
var boss_summon_budget := 0
var wave_total := 0
var phase_kills := 0
var shop_stock: Array[Dictionary] = []
var shop_purchased: Array[bool] = [false, false, false]
const MAX_ACTIVE_ENEMIES := 80''')
s=s.replace('var font: Font = preload("res://fonts/after_burner_neue/After Burner Neue.ttf")','var font: Font = preload("res://fonts/w95fa/W95F.otf")')
s=s.replace('\tlayer = $UI','\tlayer = $UI\n\tloot = $Loot\n\tloot.game = self\n\tfx = $CombatFX\n\tfx.game = self')
s=s.replace('"restart": [KEY_R]', '"restart": [KEY_R], "slot_one": [KEY_1], "slot_two": [KEY_2]')
s=s.replace('\tchosen_upgrades.clear()','\tchosen_upgrades.clear()\n\tloot.reset_run()')
s=s.replace('\teffects.clear()','\teffects.clear()\n\tloot.drops.clear()\n\tfx.particles.clear()\n\tfx.labels.clear()\n\tfx.shake = 0',1)
start=s.index('\tpending = 7 + mini(room, 8) * 2');end=s.index('\tmessage = $Arena.layout_name',start)
s=s[:start]+'''	wave_total = 36 + room * 6
	pending = wave_total
	phase_kills = 0
	boss_spawned = false
	boss_ref = null
	boss_summon_budget = 12 + room
	boss_summon_cd = 7.0
	spawn_cd = 0.15
	clear_wait = 0
	time_left = 105.0 + room * 6.0 + time_bonus
'''+s[end:]
s=s.replace('\t\t\tstate = "exit" if pending == 0 and enemies.get_child_count() == 0 else "playing"','\t\t\tstate = "exit" if boss_spawned and pending == 0 and enemies.get_child_count() == 0 else "playing"')
start=s.index('\t\tif pending > 0 and spawn_cd <= 0:');end=s.index('\t\tif planet_index == 1',start)
s=s[:start]+'''		if pending > 0 and spawn_cd <= 0:
			var batch := mini(pending, 6 + room / 3)
			batch = mini(batch, MAX_ACTIVE_ENEMIES - enemies.get_child_count())
			for i in maxi(0, batch):
				spawn_enemy()
				pending -= 1
			spawn_cd = maxf(0.28, 0.65 - room * 0.025)
		if not boss_spawned and pending == 0 and phase_kills >= int(wave_total * 0.65):
			begin_boss()
		if boss_spawned and is_instance_valid(boss_ref) and not boss_ref.is_queued_for_deletion():
			boss_summon_cd -= delta
			if boss_summon_cd <= 0 and boss_summon_budget > 0:
				var reinforcement := mini(4 + planet_index, boss_summon_budget)
				pending += reinforcement
				boss_summon_budget -= reinforcement
				boss_summon_cd = 7.0
				fx.floating(boss_ref.position, "REFORÇOS!", Color("ff7e8d"))
'''+s[end:]
s=s.replace('if state == "playing" and pending == 0 and enemies.get_child_count() == 0:', 'if state == "playing" and boss_spawned and pending == 0 and enemies.get_child_count() == 0:')
start=s.index('\t\t\t\tif room == total_rooms() - 1:');end=s.index('\telif state == "exit":',start)
s=s[:start]+ '\t\t\t\topen_shop()\n'+s[end:]
s=s.replace('enemy.speed = float(planet().speed) + (room % ARENAS_PER_PLANET) * 5','enemy.speed = float(planet().speed) + 12 + (room % ARENAS_PER_PLANET) * 6')
s=s.replace('enemy.health = 2.0 + floorf(room / float(ARENAS_PER_PLANET)) + (1 if room % ARENAS_PER_PLANET == ARENAS_PER_PLANET - 1 else 0)','enemy.health = 2.0 + planet_index * 0.65 + floorf(room / 6.0) * 0.5')
s=s.replace('enemy.health = 100', 'enemy.health = 40.0 + room * 12.0').replace('enemy.speed = 43','enemy.speed = 48 + room * 2')
s=s.replace('\tvar gates: Array[Vector2] = $Arena.spawn_gates()', '\tvar gates: Array[Vector2] = $Arena.spawn_gates()')
s=s.replace('\tenemies.add_child(enemy)\n\tburst', '''	# Spread each gate into a small entry band, never on the player or cover.
	if not is_boss:
		for attempt in 12:
			var candidate: Vector2 = enemy.position + Vector2(rng.randf_range(-28, 28), rng.randf_range(-28, 28))
			if arena.grow(-enemy.radius).has_point(candidate) and not blocked(candidate, enemy.radius) and candidate.distance_to(player.position) > 180:
				enemy.position = candidate
				break
	else:
		if blocked(enemy.position, enemy.radius):
			for gate in gates:
				if not blocked(gate, enemy.radius) and arena.grow(-enemy.radius).has_point(gate):
					enemy.position = gate
					break
		boss_ref = enemy
	enemy.shot_cd = rng.randf_range(0.6, 2.0)
	enemies.add_child(enemy)
	burst''')
s=s.replace('direction * (190 if hostile else 610)', 'direction * (225 if hostile else 660)')
s=s.replace('\tbullets.add_child(bullet)', '\tbullets.add_child(bullet)\n\tfx.sparks(bullet.position, Color("ff7e8d") if hostile else Color("ffe5a0"), 2, 55)')
s=s.replace('\teffects.append({"pos": at, "color": color, "life": 0.4})','\teffects.append({"pos": at, "color": color, "life": 0.4})\n\tfx.sparks(at, color, 12, 120)')
start=s.index('func choose_upgrade()');end=s.index('func apply_upgrade(',start)
s=s[:start]+'''func begin_boss() -> void:
	boss_spawned = true
	spawn_enemy(true)
	pending += 14 + room * 2
	time_left += 20
	message = "GUARDIÃO DA ARENA • elimine o chefe e os reforços!"
	message_time = 4
	fx.explosion(boss_ref.position, planet().accent, 90)

func choose_upgrade() -> void:
	# Compatibility entry point for scene previews.
	open_shop()

func open_shop() -> void:
	state = "shop"
	clear_container(bullets)
	player.echo_frames.clear()
	loot.collect_remaining()
	show_screen("shop")
	var options := range(Planets.UPGRADES.size())
	if player.spread >= 3:
		options.erase(0)
	options.shuffle()
	shop_stock.clear()
	shop_purchased = [false, false, false]
	for i in 3:
		var upgrade: Dictionary = Planets.UPGRADES[options[i]]
		shop_stock.append({"key": upgrade.key, "name": upgrade.name, "desc": upgrade.desc, "cost": 22 + room * 3 + i * 5})
		var button: Button = panel.find_child("Choice%d" % (i + 1), true, false)
		button.pressed.connect(buy_upgrade.bind(i))
	bind_button("RepairButton", buy_supply.bind("repair"))
	bind_button("BombButton", buy_supply.bind("bomb"))
	bind_button("ShieldButton", buy_supply.bind("shield"))
	bind_button("OverdriveButton", buy_supply.bind("overdrive"))
	bind_button("LeaveButton", leave_shop)
	refresh_shop()

func shop_notice(text: String) -> void:
	panel.find_child("Notice", true, false).text = text

func refresh_shop() -> void:
	panel.find_child("Wallet", true, false).text = "MOEDAS: %d   |   ITENS: %s / %s" % [loot.coins, slot_name(0), slot_name(1)]
	for i in 3:
		var stock: Dictionary = shop_stock[i]
		var button: Button = panel.find_child("Choice%d" % (i + 1), true, false)
		button.text = ("COMPRADO • " if shop_purchased[i] else "%d moedas • " % stock.cost) + stock.name + "\\n" + stock.desc.replace("\\n", " / ")
		button.disabled = shop_purchased[i]
	panel.find_child("LeaveButton", true, false).text = "CONCLUIR EXPEDIÇÃO" if room == total_rooms() - 1 else "CONTINUAR PARA A EXTRAÇÃO"

func slot_name(index: int) -> String:
	return "vazio" if loot.slots[index].is_empty() else loot.ITEMS[loot.slots[index]].name

func buy_upgrade(index: int) -> bool:
	if state != "shop" or index < 0 or index >= shop_stock.size() or shop_purchased[index]:
		return false
	var stock: Dictionary = shop_stock[index]
	if loot.coins < int(stock.cost):
		shop_notice("Moedas insuficientes.")
		return false
	loot.coins -= int(stock.cost)
	shop_purchased[index] = true
	apply_upgrade(stock.key)
	shop_notice("Módulo instalado: " + stock.name)
	refresh_shop()
	return true

func buy_supply(kind: String) -> bool:
	if state != "shop":
		return false
	var cost := 14 if kind == "repair" else 18
	if loot.coins < cost:
		shop_notice("Moedas insuficientes.")
		return false
	if kind == "repair":
		if player.health >= player.max_health:
			shop_notice("Seu traje já está reparado.")
			return false
		player.health = mini(player.max_health, player.health + 2)
	elif not loot.add_item(kind):
		shop_notice("Os dois slots estão cheios. Use seus itens na próxima arena.")
		return false
	loot.coins -= cost
	shop_notice("Compra concluída.")
	refresh_shop()
	return true

func leave_shop() -> void:
	if state != "shop":
		return
	close_panel()
	if room == total_rooms() - 1:
		finish(true, "Doze guardiões derrotados. A rota está livre!")
	else:
		state = "exit"

'''+s[end:]
p.write_text(s,encoding='utf-8')

# Shop is a normal editable Godot Control scene.
shop=Path('scenes/ui/upgrade_screen.tscn').read_text(encoding='utf-8').replace('name="UpgradeScreen"','name="ShopScreen"').replace('ARENA CONCLUÍDA','LOJA ORBITAL').replace('Escolha uma melhoria para esta tentativa.','Equipe o traje. Guarde moedas para as próximas arenas.').replace('Vector2(660, 0)','Vector2(820, 0)').replace('separation = 16','separation = 8').replace('font_size = 36','font_size = 30').replace('Vector2(0, 62)','Vector2(0, 58)')
shop+='''
[node name="Wallet" type="Label" parent="Center/Card/Box"]
layout_mode = 2
text = "MOEDAS: 0 | ITENS: vazio / vazio"
horizontal_alignment = 1

[node name="Supplies" type="GridContainer" parent="Center/Card/Box"]
layout_mode = 2
columns = 2
theme_override_constants/h_separation = 8
theme_override_constants/v_separation = 8
'''
for name,text in [('RepairButton','14 moedas • Reparar +2 de vida'),('BombButton','18 moedas • Bomba orbital [slot]'),('ShieldButton','18 moedas • Escudo [slot]'),('OverdriveButton','18 moedas • Sobrecarga [slot]')]:
    shop+=f'\n[node name="{name}" type="Button" parent="Center/Card/Box/Supplies"]\nlayout_mode = 2\nsize_flags_horizontal = 3\ncustom_minimum_size = Vector2(0, 44)\ntext = "{text}"\n'
shop+='''
[node name="Notice" type="Label" parent="Center/Card/Box"]
layout_mode = 2
text = "Itens são usados nas teclas 1 e 2. Máximo: dois slots."
horizontal_alignment = 1
theme_override_font_sizes/font_size = 16

[node name="LeaveButton" type="Button" parent="Center/Card/Box"]
layout_mode = 2
custom_minimum_size = Vector2(0, 48)
text = "CONTINUAR PARA A EXTRAÇÃO"
'''
Path('scenes/ui/shop_screen.tscn').write_text(shop,encoding='utf-8')
