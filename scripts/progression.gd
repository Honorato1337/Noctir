extends RefCounted

const Skins = preload("res://scripts/skin_catalog.gd")
const POINTS_PER_COIN := 100
const PRESTIGE_COST := 1000
const MAX_WALLET := 0x7FFFFFFFFFFFFFFF
const ABILITIES = [
	{"key": "pickup", "name": "CAMPO MAGNÉTICO", "effect": "+40 px de atração de moedas e itens por nível.", "prices": [1, 2, 3, 4, 5]},
	{"key": "berserk", "name": "BERSERK", "effect": "[F] Disparos automáticos em 360° por 6 s. Uma ativação por run.", "prices": [3]}
]
const UPGRADES = [
	{"key": "health", "name": "BLINDAGEM", "effect": "+1 de vida máxima por nível", "prices": [45, 100, 180]},
	{"key": "damage", "name": "NÚCLEO DE PLASMA", "effect": "+5% de dano inicial por nível", "prices": [30, 55, 90, 140, 210]},
	{"key": "rate", "name": "GATILHO REFINADO", "effect": "+4% de cadência inicial por nível", "prices": [35, 75, 135]},
	{"key": "speed", "name": "BOTAS ORBITAIS", "effect": "Movimento com retornos menores", "prices": [25, 60, 110]},
	{"key": "dash", "name": "PROPULSOR AUXILIAR", "effect": "Reduz a recarga sem zerá-la", "prices": [30, 65, 120]},
	{"key": "time", "name": "RESERVA TEMPORAL", "effect": "+2 segundos por arena por nível", "prices": [25, 55, 100]}
]

var owned_skins: Array[String] = ["astronaut"]
var selected_skin := "astronaut"
var coins := 0
var space_coins := 0
var prestige := 0
var prestige_cycles := 0
var remainder := 0
var levels: Dictionary = {}
var abilities: Dictionary = {"pickup": 0, "berserk": 0}
var save_path := "user://progression.cfg"
var last_save_error := OK

func _init() -> void:
	for upgrade: Dictionary in UPGRADES:
		levels[upgrade.key] = 0

func load_profile() -> Error:
	var file := ConfigFile.new()
	var error := file.load(save_path)
	if error != OK:
		return error
	coins = valid_int(file.get_value("wallet", "coins", 0), 0, MAX_WALLET)
	space_coins = valid_int(file.get_value("wallet", "space_coins", 0), 0, MAX_WALLET)
	prestige = valid_int(file.get_value("wallet", "prestige", 0), 0, MAX_WALLET)
	prestige_cycles = maxi(0, file.get_value("wallet", "prestige_cycles", 0)) if typeof(file.get_value("wallet", "prestige_cycles", 0)) == TYPE_INT else 0
	remainder = valid_int(file.get_value("wallet", "remainder", 0), 0, POINTS_PER_COIN - 1)
	for upgrade: Dictionary in UPGRADES:
		levels[upgrade.key] = valid_int(file.get_value("upgrades", upgrade.key, 0), 0, max_level(upgrade.key))
	for ability: Dictionary in ABILITIES:
		abilities[ability.key] = valid_int(file.get_value("abilities", ability.key, 0), 0, ability.prices.size())
	owned_skins = ["astronaut"]
	var stored: Variant = file.get_value("cosmetics","owned",PackedStringArray())
	if stored is Array or stored is PackedStringArray:
		for key in stored:
			if key is String and Skins.DATA.has(key) and key not in owned_skins: owned_skins.append(key)
	var chosen: Variant = file.get_value("cosmetics","selected","astronaut")
	selected_skin = chosen if chosen is String and chosen in owned_skins else "astronaut"
	return OK

func valid_int(value: Variant, minimum: int, maximum: int) -> int:
	return clampi(value, minimum, maximum) if typeof(value) == TYPE_INT else minimum

func save_profile() -> Error:
	var file := ConfigFile.new()
	file.set_value("cosmetics","owned",PackedStringArray(owned_skins))
	file.set_value("cosmetics","selected",selected_skin)
	file.set_value("wallet", "coins", coins)
	file.set_value("wallet", "space_coins", space_coins)
	file.set_value("wallet", "prestige", prestige)
	file.set_value("wallet", "prestige_cycles", prestige_cycles)
	file.set_value("wallet", "remainder", remainder)
	for key: String in levels:
		file.set_value("upgrades", key, levels[key])
	for key: String in abilities:
		file.set_value("abilities", key, abilities[key])
	# Replace the old profile only after the complete new file has been written.
	last_save_error = file.save(save_path + ".tmp")
	if last_save_error == OK:
		last_save_error = DirAccess.rename_absolute(ProjectSettings.globalize_path(save_path + ".tmp"), ProjectSettings.globalize_path(save_path))
	return last_save_error

func equip_skin(key: String, persist: bool = true) -> bool:
	if not Skins.DATA.has(key): return false
	var cost: int = 0 if key in owned_skins else int(Skins.DATA[key].cost)
	if prestige < cost: return false
	var previous_owned := owned_skins.duplicate()
	var previous_selected := selected_skin
	prestige -= cost
	if key not in owned_skins: owned_skins.append(key)
	selected_skin = key
	if persist and save_profile() != OK:
		prestige += cost
		owned_skins = previous_owned
		selected_skin = previous_selected
		return false
	return true

func award_score(points: int, persist: bool = true) -> int:
	var total := maxi(0, points) + remainder
	var reward := total / POINTS_PER_COIN
	remainder = total % POINTS_PER_COIN
	coins += reward
	if persist:
		save_profile()
	return reward

func price(index: int) -> int:
	if index < 0 or index >= UPGRADES.size():
		return -1
	var upgrade: Dictionary = UPGRADES[index]
	var level: int = levels[upgrade.key]
	if level >= max_level(upgrade.key):
		return -1
	return int(upgrade.prices[level]) if level < upgrade.prices.size() else int(upgrade.prices[-1]) + (level - upgrade.prices.size() + 1) * 80

func award_space_coins(amount: int, persist: bool = true) -> int:
	var before := space_coins
	space_coins += mini(maxi(0, amount), MAX_WALLET - space_coins)
	if persist:
		save_profile()
	return space_coins - before

func maxed_attributes() -> int:
	var total := 0
	for upgrade: Dictionary in UPGRADES:
		if int(levels[upgrade.key]) == max_level(upgrade.key):
			total += 1
	return total

func can_prestige() -> bool:
	return coins >= PRESTIGE_COST and maxed_attributes() == UPGRADES.size()

func reset_for_prestige(persist: bool = true) -> bool:
	if not can_prestige():
		return false
	var previous_levels := levels.duplicate()
	coins -= PRESTIGE_COST
	prestige += 1
	prestige_cycles += 1
	for key: String in levels:
		levels[key] = 0
	if persist and save_profile() != OK:
		coins += PRESTIGE_COST
		prestige -= 1
		prestige_cycles -= 1
		levels = previous_levels
		return false
	return true

func buy(index: int, persist: bool = true) -> bool:
	var cost := price(index)
	if cost < 0 or coins < cost:
		return false
	var key: String = UPGRADES[index].key
	coins -= cost
	levels[key] += 1
	if persist and save_profile() != OK:
		coins += cost
		levels[key] -= 1
		return false
	return true

func apply_to(player: Node2D) -> void:
	player.set_skin(selected_skin)
	# Called only on a fresh player instance; temporary run modules stay separate.
	player.max_health += int(levels.health) + prestige_cycles
	player.health = player.max_health
	player.damage *= 1.0 + int(levels.damage) * 0.05 + prestige_cycles * 0.10
	player.interval /= 1.0 + int(levels.rate) * 0.04
	player.speed *= movement_factor(int(levels.speed))
	player.dash_recharge *= dash_factor(int(levels.dash))
	player.pickup_bonus = int(abilities.pickup) * 40.0

func ability_price(index: int) -> int:
	if index < 0 or index >= ABILITIES.size():
		return -1
	var ability: Dictionary = ABILITIES[index]
	var level: int = abilities[ability.key]
	return -1 if level >= ability.prices.size() else int(ability.prices[level])

func buy_ability(index: int, persist: bool = true) -> bool:
	var cost := ability_price(index)
	if cost < 0 or space_coins < cost:
		return false
	var key: String = ABILITIES[index].key
	space_coins -= cost
	abilities[key] += 1
	if persist and save_profile() != OK:
		space_coins += cost
		abilities[key] -= 1
		return false
	return true

func bonus_text(key: String) -> String:
	var level: int = levels[key]
	match key:
		"health": return "Bônus atual: +%d de vida" % level
		"damage": return "Bônus atual: +%d%% de dano" % (level * 5)
		"rate": return "Bônus atual: +%d%% de cadência" % (level * 4)
		"speed": return "Bônus atual: +%d%% de movimento" % roundi((movement_factor(level) - 1) * 100)
		"dash": return "Bônus atual: -%d%% de recarga" % roundi((1 - dash_factor(level)) * 100)
		"time": return "Bônus atual: +%ds por arena" % (level * 2)
	return ""

func max_level(key: String) -> int:
	for upgrade: Dictionary in UPGRADES:
		if upgrade.key == key:
			return upgrade.prices.size() + prestige_cycles
	return 0

func dash_factor(level: int) -> float:
	return (1.0 - mini(level, 3) * .06) / (1.0 + maxi(level - 3, 0) * .06)

func enemy_health_factor() -> float:
	return 1.0 + prestige_cycles * .18

func movement_factor(level: int) -> float:
	var extra := maxi(0, level - 3)
	return 1 + mini(level, 3) * .04 + extra * .04 / (1 + extra * .04)
