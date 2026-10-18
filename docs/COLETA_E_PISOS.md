# Coleta segura, pisos e veículos

Após derrotar todos os inimigos e o chefe da arena, o jogo entra em coleta segura. O cronômetro do combate e os eventos ficam suspensos; um contador separado oferece 15 segundos para coletar e embarcar. Tornados, gelo, meteoros, áreas de ataque, tiros, partículas de combate, tremor de câmera e equipamentos posicionados são removidos; moedas e itens no chão permanecem. As moedas deixam de expirar nessa etapa.

O jogador pode caminhar e recolher o que cabe no inventário. Com os dois slots cheios, aproxime-se de um consumível e aperte 1 ou 2 para escolher qual substituir; o item anterior volta ao chão. Use 3 para trocar o equipamento. As ações respeitam remapeamento de teclado, joystick e toque. Kits médicos ainda podem ser usados para recuperar vida. A pausa retorna à coleta.

Siga a seta e use E ou EMBARCAR próximo ao veículo. Uma pulsação vermelha sinaliza a extração e aumenta nos últimos 10 segundos. Ao zerar o contador, o resgate embarca o jogador automaticamente, sem perder uma chance. A loja abre a bordo por até 20 segundos, antes da viagem; ao finalizar as compras ou zerar o contador, a transição começa diretamente. Compras e trocas de ofertas não renovam esse prazo. A loja permanente do menu permanece sem limite. Durante a coleta, a pausa suspende a contagem. Moedas e itens ainda no chão são perdidos ao embarcar, inclusive antes do prazo; apenas o que foi coletado segue na run. A loja mostra o total perdido. Itens sem espaço no inventário devem ser escolhidos durante a coleta; os restantes não seguem para a próxima arena. A próxima arena limpa os drops antigos normalmente.

## Pisos

assets/environment/floor_tiles-v3.png contém quatro texturas: solo vermelho de Marte, gelo escuro de Netuno, faixas minerais de Júpiter e rocha violeta do Nexo. Cada célula é carregada em 32×32, com nearest-neighbour e oito cores escuras. Os sprites originais do time permanecem preservados. Fonte e prompt completo: assets/environment/FLOOR_V3_PROMPT.md.

## Veículos

Rover e foguete usam caixa de desenho de 192 px na arena e 256 px na transição, com escala inteira. A posição da extração mantém margem das paredes para o veículo ampliado. Rover continua sendo usado entre arenas do mesmo planeta; foguete nas trocas de planeta e no retorno final.

## Validação

- tests/safe_collection.gd: limpeza dos ataques, preservação de drops, suspensão do cronômetro e expiração, pausa, trocas de slots e loja manual.
- tests/smoke.gd: progressão completa pelas 13 arenas.
- tests/terrain_art.gd: rochas, colisões, caminhos e prévias dos quatro ambientes.
- tests/art_revision_travel.gd: animações e rotas de rover/foguete.

Prévias em docs/preview-safe-collection.png, preview-larger-rover.png, preview-larger-rocket.png e preview-terrain-0.png até 3.png.

Atualização 0.1.1: morte1.mp3 toca em cada morte com uma voz dedicada no canal Efeitos; a derrota final não sobrepõe o som antigo. Foguete com frames centralizados e decolagem acelerada, iniciando visível. Músicas importadas em PCM; o menu usa corte da cauda quase silenciosa e sobreposição circular de 120 ms. tests/extraction_audio_fixes.gd verifica as emendas, três mortes e animação.

Atualização 0.1.3: sirene progressiva derivada de musica/alarme.mp3, em PCM com emenda circular. Acelera de pitch 0,85 a 1,65 e volume de -20 a -6 dB durante a coleta; pausa junto com o jogo e para no embarque. Motores sintetizados em assets/audio/sfx/rover_engine.wav e rocket_engine.wav, ambos de 2,4 segundos, sincronizados com a viagem. Sirene e motores respeitam o volume Efeitos. Ferramentas: tools/prepare_alarm_audio.gd e tools/generate_transport_audio.py. Validação: tests/urgency_transport.gd.
