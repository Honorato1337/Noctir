extends RefCounted

# All prices and probabilities are shared by the shop, drops and balance checks.
const COIN_CHANCE := 0.55
const QUICK_WINDOW := 2.5
const COIN_LIFETIME := 14.0
const MAGNET_RADIUS := 80.0
const MODULE_PRICES := {"spread": 40, "rate": 38, "health": 36, "speed": 32, "damage": 44, "time": 30}

static func coin_value(rng: RandomNumberGenerator) -> int:
	var roll := rng.randf()
	return 5 if roll < 0.05 else (2 if roll < 0.25 else 1)

static func offer(upgrade: Dictionary, room: int, installed: Array[String], rng: RandomNumberGenerator) -> Dictionary:
	var bargain := rng.randf() < 0.12
	var factor := 0.65 if bargain else rng.randf_range(0.9, 1.2)
	var base: float = MODULE_PRICES[upgrade.key] + room * 5
	var cost := maxi(1, int(round(base * pow(1.35, installed.count(upgrade.key)) * factor)))
	return {"key": upgrade.key, "name": upgrade.name, "desc": upgrade.desc, "cost": cost, "bargain": bargain}

static func supply_price(kind: String, room: int) -> int:
	return int({"repair": 16, "mine": 28, "turret": 32, "beacon": 30}.get(kind, 20)) + room * 2

static func reroll_price(room: int, used: int) -> int:
	return 12 + room * 2 + used * 8

static func contract_reward(_room: int) -> int:
	return 1
