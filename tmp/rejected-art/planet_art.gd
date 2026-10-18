@tool
extends RefCounted

const GROUNDS = [
	preload("res://assets/art/regions/mars_ground.tres"),
	preload("res://assets/art/regions/venus_ground.tres"),
	preload("res://assets/art/regions/jupiter_ground.tres")
]

const MINIONS = [
	preload("res://assets/art/regions/mars_minion.tres"),
	preload("res://assets/art/regions/venus_minion.tres"),
	preload("res://assets/art/regions/jupiter_minion.tres")
]

const ROCKS = [
	preload("res://assets/art/regions/mars_rock.tres"),
	preload("res://assets/art/regions/venus_rock.tres"),
	preload("res://assets/art/regions/jupiter_rock.tres")
]

const BOSSES = [
	preload("res://assets/art/regions/mars_boss.tres"),
	preload("res://assets/art/regions/venus_boss.tres"),
	preload("res://assets/art/regions/jupiter_boss.tres")
]

const ASTRONAUT = [
	preload("res://assets/art/regions/astronaut_down.tres"),
	preload("res://assets/art/regions/astronaut_up.tres"),
	preload("res://assets/art/regions/astronaut_left.tres"),
	preload("res://assets/art/regions/astronaut_right.tres")
]

static func direction_index(direction: Vector2) -> int:
	if absf(direction.x) > absf(direction.y):
		return 2 if direction.x < 0 else 3
	return 1 if direction.y < 0 else 0
