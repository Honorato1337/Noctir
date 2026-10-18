extends SceneTree
var failures := 0
func _initialize() -> void:
 call_deferred("run")
func check(ok: bool, detail: String) -> void:
 print(("PASS: " if ok else "FAIL: ") + detail)
 if not ok: failures += 1
func run() -> void:
 var game = load("res://scenes/main.tscn").instantiate()
 game.smoke_mode = true
 root.add_child(game)
 game.set_physics_process(false)
 game.start_run()
 game.player.set_physics_process(false)
 var weather = game.weather
 weather.set_physics_process(false)
 var delays: Array[float] = []
 for sector in 4:
  game.room = sector*4
  game.start_room()
  delays.append(weather.wait)
  check(not weather.active and weather.wait >= 8 and weather.wait <= 13, "arena schedules weather with opening grace %d" % sector)
  weather._physics_process(weather.wait + 0.01)
  check(weather.active and weather.event == ["sand", "ice", "jupiter", "chaos"][sector] and weather.motes.size() == 180, "correct random event and bounded ambient particles %d" % sector)
  if sector in [0,2,3]:
   var vortex: Dictionary = weather.vortices[0]
   var before: Vector2 = vortex.pos
   game.player.position = before
   game.player.immunity = 0
   var health: int = game.player.health
   weather._physics_process(0.5)
   check(game.player.health == health and vortex.pos == before and weather.player_force(before+Vector2(100,0)) == Vector2.ZERO, "storm warns before movement, pull or damage %d" % sector)
   game.player.position = game.arena.get_center()
   game.player.immunity = 1000
   weather._physics_process(1.55)
   check(vortex.pos != before and weather.player_force(vortex.pos+Vector2(100,0)).length() > 0 and weather.player_force(vortex.pos+Vector2(100,0)).length() <= 150, "moving storm has bounded attraction %d" % sector)
   game.player.position = vortex.pos
   game.player.immunity = 0
   health = game.player.health
   weather._physics_process(0.01)
   check(game.player.health < health, "storm core hurts player %d" % sector)
  var saved_vortices: Array[Dictionary] = weather.vortices.duplicate(true)
  if sector in [1,2,3]:
   weather.vortices.clear()
   game.player.health = game.player.max_health
   weather.age = weather.warning
   weather.strikes.clear()
   game.player.position = game.arena.get_center()
   var at: Vector2 = game.player.position
   weather.add_strike("ice" if sector == 1 else "lightning", at)
   weather.pulse = 99
   game.player.immunity = 0
   var health: int = game.player.health
   weather._physics_process(0.5)
   check(game.player.health == health, "impact warning does not damage %d" % sector)
   var target: Vector2 = weather.strikes[0].pos
   game.player.position = target+Vector2(150,0)
   weather._physics_process(0.61)
   check(game.player.health == health and weather.strikes[0].pos == target, "moving away dodges fixed impact %d" % sector)
   weather.strikes.clear()
   game.player.position = game.arena.get_center()
   weather.add_strike("ice", game.player.position)
   weather.strikes[0].age = 1.1
   weather._physics_process(0.01)
   check(game.player.health < health, "ice impact actually damages player %d" % sector)
  if sector == 3:
   weather.vortices.assign(saved_vortices)
   game.player.immunity = 1000
   weather.pulse = 0
   weather._physics_process(0.01)
   var kinds: Array[String] = []
   for strike in weather.strikes: kinds.append(strike.kind)
   check(weather.vortices.size() == 2 and kinds.has("ice") and kinds.has("meteor") and kinds.has("lightning"), "final arena combines multiple storms and all impact types")
  var age: float = weather.age
  game.state = "paused"
  weather._physics_process(5)
  check(weather.age == age, "pause freezes weather %d" % sector)
  game.state = "death"
  weather._physics_process(5)
  check(weather.age == age, "death choice freezes weather %d" % sector)
  game.state = "playing"
  for i in 100: weather.add_strike("meteor", game.player.position)
  check(weather.strikes.size() == weather.MAX_STRIKES, "strike count stays bounded %d" % sector)
  weather.age = weather.warning + weather.duration
  weather._physics_process(0.01)
  check(not weather.active and weather.strikes.is_empty() and weather.vortices.is_empty() and weather.wait > 0, "event ends with safe interval %d" % sector)
 check(delays[0] != delays[1] or delays[1] != delays[2], "weather timing varies between maps")
 game.room = 0
 game.start_room()
 weather.start_event()
 game.player.immunity = 0
 game.player.hurt(999)
 game.continue_after_death()
 check(not weather.active and weather.strikes.is_empty() and weather.wait >= 8, "continue clears weather and grants fresh grace period")
 if "--preview" in OS.get_cmdline_user_args():
  for sector in 4:
   game.room = sector*4
   game.start_room()
   game.player.immunity = 1000
   game.player.position = game.arena.get_center()
   game.configure_camera()
   weather.start_event()
   if not weather.vortices.is_empty(): weather.vortices[0].pos = game.player.position+Vector2(170,-80)
   weather.age = weather.warning
   weather.pulse = 0
   weather._physics_process(0.05)
   if sector > 0:
    weather.add_strike("ice" if sector == 1 else "lightning", game.player.position+Vector2(-90,-60))
    weather.strikes[-1].age = 1.15
   weather.queue_redraw()
   for frame in 4: await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://docs/preview-weather-%d.png" % sector)
 game.queue_free()
 await process_frame
 print("ARENA WEATHER RESULT: %d failures" % failures)
 quit(1 if failures else 0)
