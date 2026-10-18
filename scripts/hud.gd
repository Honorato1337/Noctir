extends Control

func update_game(game: Node2D) -> void:
	var touch: bool = game.controls.touch_enabled()
	$SlotThree.position = Vector2(944, 100) if touch else Vector2(1024, 536)
	%Contract.position = Vector2(230, 595) if touch else Vector2(64, 626)
	for pair: Array in [["SlotOne", "slot_one"], ["SlotTwo", "slot_two"], ["SlotThree", "slot_three"]]:
		get_node(pair[0] + "/Key").text = game.controls.hint(pair[1])
	%Contract.visible = game.contracts.enabled and game.state == "playing"
	%Contract.text = game.contracts.status_text()
	visible = game.state in ["playing", "cleared", "exit", "paused", "shop", "ended"]
	%Planet.text = game.planet().name + " %d/%d · %s" % [game.room + 1, game.total_rooms(), {"easy": "FÁC", "medium": "MÉD", "hard": "DIF"}[game.run_difficulty]]
	%Timer.text = "TESTE" if game.practice_mode else "%02d:%02d" % [int(game.time_left) / 60, int(game.time_left) % 60]
	%Timer.modulate = Color("ff9d87") if game.time_left < 10 else Color.WHITE
	%Score.text = "PONTOS %05d" % game.score
	%Coins.text = "MOEDAS %d" % game.loot.coins
	%SlotOneIcon.texture = game.loot.ICONS.get(game.loot.slots[0], null)
	%SlotTwoIcon.texture = game.loot.ICONS.get(game.loot.slots[1], null)
	%SlotThreeIcon.texture = game.loot.ICONS.get(game.deployables.inventory, null)
	%Message.text = game.message if game.message_time > 0 and game.state == "playing" else ""
	%Counters.text = "%d INIM. (+%d)" % [game.enemies.get_child_count(), game.pending]
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
	%CleanupHint.text = "COLETE OS ITENS E ENTRE NO VEÍCULO"
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
	%MiniTutorial.visible = game.room == 0 and game.state in ["playing", "exit"] and not touch
	$MiniTutorial/Instructions.text = game.controls.tutorial()
	%ScreenFlash.visible = (game.state == "playing" and game.flash > 0) or game.state == "cleared"
	%ScreenFlash.color = Color(1,0.08,0.12,game.extraction_pulse()) if game.state == "cleared" else Color(0.3, 0.9, 0.9, minf(game.flash * 0.4, 0.25))
	%Chances.visible = game.state in ["playing", "cleared", "exit", "paused"]
	%Chances.text = "RUN %d/3 CHANCES" % game.run_chances_left
	%BerserkCard.visible = game.state in ["playing", "paused"] and game.can_use_berserk() and not touch
	%DashCard.visible = game.state in ["playing", "paused"] and not touch
	if is_instance_valid(game.player):
		%BerserkStatus.text = "[%s] BERSERK / %.1fs" % [game.controls.hint("berserk"), game.player.berserk_time] if game.player.berserk_time > 0 else ("BERSERK USADO / PRÓXIMA RUN" if game.berserk_used else "[%s] BERSERK / PRONTO" % game.controls.hint("berserk"))
		var remaining: float = maxf(0, game.player.dash_cd)
		%DashStatus.text = "[%s] DASH PRONTO" % game.controls.hint("dash") if remaining <= 0 else "[%s] DASH %.1fs" % [game.controls.hint("dash"), remaining]
		%DashStatus.modulate = Color("71e4c5") if remaining <= 0 else Color("b6c4d6")
		%DashCooldown.value = 1.0 - clampf(remaining / game.player.dash_recharge, 0, 1)
		%Health.active = game.state == "playing"
		%Health.set_health(game.player.health, game.player.max_health)
		%Echo.text = "[%s] ECO " % game.controls.hint("rewind") + ("PRONTO" if game.player.rewind_ready else "USADO")
