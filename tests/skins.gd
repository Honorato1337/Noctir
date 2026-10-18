extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, detail: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+detail)
	if not ok: failures += 1
func shot(name: String) -> void:
	if "--preview" not in OS.get_cmdline_user_args(): return
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/media/"+name+".png")
func run() -> void:
	var Profile = load("res://scripts/progression.gd")
	var profile = Profile.new()
	profile.save_path = "res://tmp/skin-profile.cfg"
	check(not profile.equip_skin("guanapo",false), "skin requires Prestige")
	profile.prestige = 2
	check(profile.equip_skin("guanapo") and profile.prestige == 1, "one Prestige unlocks and equips Guanapo")
	check(profile.equip_skin("guanapo") and profile.prestige == 1, "owned skin never charges twice")
	var loaded = Profile.new()
	loaded.save_path = profile.save_path
	loaded.load_profile()
	check(loaded.selected_skin == "guanapo" and "guanapo" in loaded.owned_skins, "owned and equipped skin survive save/load")
	var failing = Profile.new()
	failing.prestige = 2
	failing.save_path = "res://missing-skin-test-directory/profile.cfg"
	check(not failing.equip_skin("guanapo") and failing.prestige == 2 and failing.selected_skin == "astronaut" and "guanapo" not in failing.owned_skins, "failed save rolls back currency and ownership")
	var old := ConfigFile.new()
	old.set_value("wallet","coins",123)
	old.save("res://tmp/skin-old-profile.cfg")
	var migrated = Profile.new()
	migrated.save_path = "res://tmp/skin-old-profile.cfg"
	migrated.load_profile()
	check(migrated.selected_skin == "astronaut" and migrated.coins == 123, "old profiles keep progress and default appearance")
	var game = load("res://scenes/main.tscn").instantiate()
	game.smoke_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.progression = loaded
	game.show_permanent_shop()
	game.set_permanent_tab("skins")
	check(game.panel.find_child("GuanapoSkinButton",true,false).text == "EQUIPADA", "skin shop reflects selected appearance")
	await shot("12-guanapo-loja")
	game.show_menu()
	check(game.panel.find_child("AstronautSprite",true,false).sprite_frames == Profile.Skins.DATA.guanapo.frames, "menu portrait uses selected skin")
	game.start_run()
	game.player.set_physics_process(false)
	game.player.position = game.arena.get_center()
	game.configure_camera()
	check(game.player.skin_id == "guanapo" and game.player.visual.sprite_frames.get_frame_count(&"walk") == 4, "run uses all four original animation frames")
	game.controls.touch_move = Vector2.LEFT
	game.player.update_animation()
	check(game.player.visual.flip_h, "moving left mirrors Guanapo")
	for i in 60:
		game.player.history.append({"pos":game.player.position-Vector2(170,0),"health":game.player.health,"t":i/60.0,"shots":[],"damage":1.0,"visual_frame":3,"flip_h":true})
	game.player.rewind()
	game.player.position += Vector2(200,60)
	game.controls.touch_move = Vector2.RIGHT
	game.player.update_animation()
	check(not game.player.visual.flip_h and game.player.echo_visual.flip_h, "Echo preserves recorded left-facing while current skin faces right")
	check(game.player.echo_visual.texture == Profile.Skins.DATA.guanapo.frames.get_frame_texture(&"walk",3), "Echo uses Guanapo frames")
	game.player.immunity = 999
	game.flash = 0
	game.message_time = 0
	game.elapsed = 20
	await shot("13-guanapo-eco")
	check(game.progression.equip_skin("astronaut",false), "default astronaut can be equipped again")
	game.start_run()
	check(game.player.skin_id == "astronaut", "new runs respect default appearance after switching back")
	game.controls.touch_move = Vector2.ZERO
	game.controls.touch_aim = Vector2.ZERO
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://tmp/skin-profile.cfg"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://tmp/skin-old-profile.cfg"))
	quit(failures)
