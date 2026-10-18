Versão atual: veja REVISAO_DE_ARTE.md. Rover entre arenas do mesmo planeta; foguete somente entre planetas e no retorno final. A versão ativa dos sprites é v2 e as viagens duram 2,4 s.

# Partículas e extração

Recursos em pixel art gerados com imagegen integrado, usando os cenários e o astronauta como referências de estilo. Sprites originais do time preservados.

- assets/effects/particle_atlas.png: quatro famílias de quatro frames: faísca, poeira, gelo e impacto de plasma. Substituem os quadrados das partículas de combate, areia, gelo, vórtices e quedas do clima. Mantido o limite global de 1.800 partículas e os limites próprios dos eventos.
- assets/vehicles/rover.png: veículo de resgate no ponto de extração. Aparece após sair da loja da arena, com placa, luz de localização e seta até ele. Aproximar-se a menos de 100 px e pressionar a ação de extrair permite embarcar.
- assets/vehicles/ship.png: nave da expedição, usada numa transição de 1,8 s entre arenas e no retorno final. O combate, o cronômetro e os eventos ficam congelados durante o trajeto. A chegada preserva chances da run, itens, módulos e uso de Berserk.

O aviso da HUD tem moldura pixelada verde, título de 28 px e indicação de embarque de 22 px. O comando usa a tecla personalizada, X no joystick ou o botão ROVER no toque. Em celular a placa fica acima da área dos direcionais.

A arena final também exige embarcar no rover e assistir ao retorno orbital antes do resultado de vitória. O botão da loja indica SEGUIR PARA O ROVER.

Integração: scripts/pixel_effects.gd, combat_fx.gd, arena_weather.gd, extraction_rover.gd, expedition_vehicles.gd e travel_screen.gd. A nave usa scenes/ui/travel_screen.tscn; o rover é um nó do main.tscn. O marcador Portal continua sendo usado internamente para posicionar o rover e preservar os caminhos existentes das arenas.

Prompts completos: assets/vehicles/GENERATION_PROMPTS.md. Testes: tests/extraction_vfx.gd e campanha tests/smoke.gd.
