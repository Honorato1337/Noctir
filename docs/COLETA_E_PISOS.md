# Coleta segura, pisos e veículos

Após derrotar todos os inimigos e o chefe da arena, o jogo entra em coleta segura. O cronômetro do combate e os eventos ficam suspensos; um contador separado oferece 30 segundos para coletar e embarcar. Tornados, gelo, meteoros, áreas de ataque, tiros, partículas de combate, tremor de câmera e equipamentos posicionados são removidos; moedas e itens no chão permanecem. As moedas deixam de expirar nessa etapa.

O jogador pode caminhar e recolher o que cabe no inventário. Com os dois slots cheios, aproxime-se de um consumível e aperte 1 ou 2 para escolher qual substituir; o item anterior volta ao chão. Use 3 para trocar o equipamento. As ações respeitam remapeamento de teclado, joystick e toque. Kits médicos ainda podem ser usados para recuperar vida. A pausa retorna à coleta.

Siga a seta e use E ou EMBARCAR próximo ao veículo. Uma pulsação vermelha sinaliza a extração e aumenta nos últimos 10 segundos. Ao zerar o contador, o resgate embarca o jogador automaticamente, sem perder uma chance. A loja abre a bordo, antes da viagem; ao finalizar as compras, a transição começa diretamente. A pausa suspende a contagem. As moedas restantes são recolhidas pelo resgate sem bônus de coleta rápida; itens só entram se houver espaço. Itens sem espaço no inventário devem ser escolhidos durante a coleta; os restantes não seguem para a próxima arena. A próxima arena limpa os drops antigos normalmente.

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
