extends Node

# One objective and at most one SpaceCoin for the entire run.
const KINDS := ["bosses", "superbosses", "survivor"]
const GOALS := {"bosses": 6, "superbosses": 2, "survivor": 4}
const LABELS := {"bosses": "DERROTE CHEFES", "superbosses": "DERROTE SUPERCHEFES", "survivor": "CHEFES SEM MORRER"}
var game: Node2D
var enabled := true
var kind := ""
var progress := 0
var target := 0
var reward := 1
var completed := false
var expired := false

func reset_run() -> void:
	kind = ""
	progress = 0
	target = 0
	reward = 1
	completed = false
	expired = false
	if enabled:
		kind = KINDS[game.rng.randi_range(0, KINDS.size() - 1)]
		target = GOALS[kind]

func start_room() -> void:
	# Arena transitions preserve the objective, its progress and its paid state.
	pass

func record(event: String) -> void:
	if not enabled or game.practice_mode or game.run_difficulty == "easy" or completed or game.run_space_reward > 0 or game.state != "playing" or kind.is_empty():
		return
	if kind == "survivor" and event == "death":
		progress = 0
	elif (kind in ["bosses", "survivor"] and event == "boss") or (kind == "superbosses" and event == "superboss"):
		progress = mini(target, progress + 1)
	else:
		return
	if progress >= target:
		var paid: int = game.progression.award_space_coins(1, not game.smoke_mode)
		if paid <= 0:
			return
		completed = true
		game.run_space_reward += paid
		game.fx.floating(game.player.position + Vector2(-80, -45), "+1 SPACECOIN", Color("71e4c5"))
		game.play_sfx("purchase")

func status_text() -> String:
	if kind.is_empty():
		return ""
	if completed:
		return "CONTRATO CUMPRIDO / +1 SPACECOIN / LIMITE DA RUN"
	return "CONTRATO • %s %d/%d / +1 SPACECOIN" % [LABELS.get(kind, "CHEFES"), progress, target]
