extends Node2D

var velocity := Vector2.ZERO
var damage := 1.0
var hostile := false
var frost := false
var echo := false
var life := 2.5
@export var radius := 4.0
@export var use_placeholder_graphics := true
var game: Node2D

func _physics_process(delta: float) -> void:
	if not is_instance_valid(game) or game.state != "playing":
		return
	life -= delta
	position += velocity * delta
	if life <= 0 or not game.arena.has_point(position) or game.blocked(position, radius):
		game.fx.sparks(position, Color("78dfff") if frost else (Color("ff707d") if hostile else Color("ffe5a0")), 3, 65)
		queue_free()
		return
	if hostile:
		if position.distance_squared_to(game.player.position) < (radius + 13) * (radius + 13):
			game.player.hurt(maxi(1, ceili(damage)))
			queue_free()
	else:
		for enemy in game.projectile_targets(position):
			if not is_instance_valid(enemy) or enemy.is_queued_for_deletion(): continue
			var reach: float = radius + enemy.radius + (13 if enemy.shield > 0 else 0)
			if position.distance_squared_to(enemy.position) < reach * reach:
				enemy.hurt(damage)
				queue_free()
				break
	# Shape and color are fixed at spawn; moving the node needs no redraw.

func _draw() -> void:
	if not use_placeholder_graphics:
		return
	var color := Color("ff707d") if hostile else (Color("71eadb") if echo else Color("ffe5a0"))
	if frost:
		color = Color("78dfff")
	draw_circle(Vector2.ZERO, radius + 3, Color(color, 0.15))
	draw_line(-velocity.normalized() * 10, Vector2.ZERO, color, radius * 1.5)
	if frost:
		draw_colored_polygon(PackedVector2Array([Vector2(0, -radius - 2), Vector2(radius, 0), Vector2(0, radius + 2), Vector2(-radius, 0)]), color)
		draw_rect(Rect2(-1, -2, 2, 4), Color("f0fcff"))
	else:
		draw_circle(Vector2.ZERO, radius, color)
