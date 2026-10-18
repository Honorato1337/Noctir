extends Control

func update_game(game: Node2D) -> void:
	# Keep the authored HUD centered while the world expands to fill the window.
	var view_size := get_viewport_rect().size
	var margin := (view_size-Vector2(1152,720))*0.5
	position = margin
	%ScreenFlash.position = -margin
	%ScreenFlash.size = view_size
	var touch: bool = game.controls.touch_enabled()
	$SlotThree.position = Vector2(944, 100) if touch else Vector2(1024, 536)
	%Contract.position = Vector2(230, 595) if touch else Vector2(104, 626)
	for pair: Array in [["SlotOne", "slot_one"], ["SlotTwo", "slot_two"], ["SlotThree", "slot_three"]]:
		get_node(pair[0] + "/Key").text = game.controls.hint(pair[1])
	%Contract.visible = game.contracts.enabled and game.state == "playing"
	%Contract.text = game.contracts.status_text()
	visible = game.state in ["playing", "cleared", "exit", "paused", "shop", "ended"]
	%Planet.text = game.planet().name + " %d/%d · %s" % [game.room + 1, game.total_rooms(), {"easy": "FÁC", "medium": "MÉD", "hard": "DIF"}[game.run_difficulty]]
	%Timer.text = "TESTE" if game.practice_mode else "%02d:%02d" % [int(game.time_left) / 60, int(game.time_left) % 60]
	%Timer.modulate = Color("ff9d87") if game.time_left < 10 else Color.WHITE
	if game.run_mode == "endless":
		%Planet.text = "PLUTÃO · HORDA %d · %s" % [game.survival.wave, game.difficulty().name]
		%Timer.text = "%02d:%02d" % [int(game.elapsed)/60, int(game.elapsed)%60]
		%Timer.modulate = Color.WHITE
	%Score.text = "PONTOS %05d" % game.score
	%Coins.text = "MOEDAS %d" % game.loot.coins
	%SlotOneIcon.texture = game.loot.ICONS.get(game.loot.slots[0], null)
	%SlotTwoIcon.texture = game.loot.ICONS.get(game.loot.slots[1], null)
	%SlotThreeIcon.texture = game.loot.ICONS.get(game.deployables.inventory, null)
	%Message.text = game.message if game.message_time > 0 and game.state == "playing" else ""
	%Counters.text = "%d INIM. (+%d)%s" % [game.enemies.get_child_count(),game.pending," + CHEFE" if game.survival.boss_due else ""] if game.run_mode == "endless" else "%d INIM. (+%d)" % [game.enemies.get_child_count(), game.pending]
	%BossBar.visible = game.state == "playing" and is_instance_valid(game.boss_ref) and not game.boss_ref.is_queued_for_deletion()
	%BossTitle.visible = %BossBar.visible and game.message_time <= 0
	%BossShield.visible = %BossBar.visible and game.boss_ref.shield > 0
	if %BossBar.visible:
		%BossBar.max_value = game.boss_ref.max_health
		%BossBar.value = game.boss_ref.health
		%BossShield.max_value = maxf(1, game.boss_ref.max_shield)
		%BossShield.value = game.boss_ref.shield
		%BossTitle.text = "%s • %s" % [game.boss_ref.display_name(), "ESCUDO %d" % ceili(game.boss_ref.shield) if game.boss_ref.shield > 0 else "FASE %d" % game.boss_ref.super_phase]
	%Cleanup.visible = game.state == "cleared"
	%Cleanup.position = Vector2(296,164) if touch else Vector2(296,446)
	%CleanupShopButton.disabled = game.state != "cleared" or game.player.position.distance_to(game.portal) >= game.EXTRACTION_RANGE
	%CleanupShopButton.text = ("EMBARCAR" if touch else "[%s] EMBARCAR" % game.controls.hint("interact")) if not %CleanupShopButton.disabled else "SIGA A SETA ATÉ O " + game.extraction_name()
	$Cleanup/Box/Title.text = "EXTRAÇÃO / %02ds" % ceili(game.collection_left)
	%CleanupHint.text = "O LOOT NO CHÃO FICA PARA TRÁS"
	if game.loot.nearby_drop() >= 0:
		%CleanupHint.text = "[%s / %s] ESCOLHER SLOT DO ITEM" % ["1" if touch else game.controls.hint("slot_one"),"2" if touch else game.controls.hint("slot_two")]
	elif game.loot.nearby_drop(true) >= 0:
		%CleanupHint.text = "[%s] TROCAR EQUIPAMENTO" % ("3" if touch else game.controls.hint("slot_three"))
	%Extract.visible = game.state == "exit"
	%Extract.position = Vector2(296, 164) if touch else Vector2(296, 508)
	if %Extract.visible:
		var near_rover: bool = game.player.position.distance_to(game.portal) < game.EXTRACTION_RANGE
		%ExtractHeader.text = game.extraction_name() + " PRONTO / EMBARQUE" if near_rover else "EXTRAÇÃO DISPONÍVEL"
		var touch_hint := "TOQUE EM IR" if game.extraction_vehicle() == "rocket" else "TOQUE EM ROVER"
		%ExtractHint.text = ((touch_hint if touch else "[%s] EMBARCAR" % game.controls.hint("interact")) + " / PRÓXIMO DESTINO") if near_rover else "SIGA A SETA ATÉ O " + game.extraction_name()
	%MiniTutorial.visible = game.room == 0 and game.state in ["playing", "exit"] and not touch and (game.run_mode != "endless" or game.elapsed < 10)
	$MiniTutorial/Instructions.text = game.controls.tutorial()
	%ScreenFlash.visible = (game.state == "playing" and game.flash > 0) or game.state == "cleared"
	%ScreenFlash.color = Color(1,0.08,0.12,game.extraction_pulse()) if game.state == "cleared" else Color(0.3, 0.9, 0.9, minf(game.flash * 0.4, 0.25))
	%Chances.visible = game.state in ["playing", "cleared", "exit", "paused"]
	%Chances.text = "RUN %d/3 CHANCES" % game.run_chances_left
	%BerserkCard.position = Vector2(24,view_size.y-(124 if %MiniTutorial.visible else 88))-margin
	%BerserkCard.visible = game.state in ["playing", "paused"] and game.can_use_berserk() and not touch
	%DashCard.visible = game.state in ["playing", "paused"] and not touch
	if is_instance_valid(game.player):
		%Echo.modulate = Color.WHITE
		var berserk_active: bool = game.player.berserk_time > 0
		var berserk_wait: bool = game.berserk_cd > 0 if game.run_mode == "endless" else game.berserk_used
		%BerserkStatus.text = "%ds" % ceili(game.player.berserk_time) if berserk_active else ("%ds" % ceili(game.berserk_cd) if game.run_mode == "endless" and berserk_wait else ("—" if berserk_wait else ""))
		$BerserkCard/Key.text = game.controls.hint("berserk")
		$BerserkCard/BerserkIcon.modulate = Color(1,1,1,0.35) if berserk_wait and not berserk_active else Color.WHITE
		%BerserkCard.tooltip_text = "BERSERK / " + ("ATIVO" if berserk_active else ("Recarregando" if berserk_wait else "PRONTO"))
		var remaining: float = maxf(0, game.player.dash_cd)
		%DashStatus.text = "[%s] DASH PRONTO" % game.controls.hint("dash") if remaining <= 0 else "[%s] DASH %.1fs" % [game.controls.hint("dash"), remaining]
		%DashStatus.modulate = Color("71e4c5") if remaining <= 0 else Color("b6c4d6")
		%DashCooldown.value = 1.0 - clampf(remaining / game.player.dash_recharge, 0, 1)
		%Health.active = game.state == "playing"
		%Health.set_health(game.player.health, game.player.max_health)
		%Echo.text = "[%s] ECO " % game.controls.hint("rewind") + ("PRONTO" if game.player.rewind_ready else "USADO")

		if game.run_mode == "endless":
			%Echo.text = "[%s] ECO %s" % [game.controls.hint("rewind"),"%ds" % ceili(game.echo_cd) if game.echo_cd > 0 else "PRONTO"]
			%Echo.modulate = Color("b6c4d6") if game.echo_cd > 0 else Color.WHITE
