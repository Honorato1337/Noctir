# Revisão de arte e viagens

A revisão substitui a primeira arte gerada para cenários, partículas e veículos por um conjunto de formas simples, cores chapadas e contornos escuros. As únicas referências da nova geração foram os sprites originais do astronauta, do mob de Marte e do mob de Netuno. A geração usou o imagegen integrado; os prompts estão em assets/vehicles/REVISION_PROMPTS.md.

## Arquivos ativos

- assets/environment/planet_terrain_atlas-v2.png: rochas e paredões dos quatro ambientes. O piso usa o atlas texturizado assets/environment/floor_tiles-v3.png, com terra marciana, gelo azul, faixas minerais de Júpiter e pedra violeta do Nexo. Os prompts desse atlas estão em assets/environment/FLOOR_V3_PROMPT.md.
- assets/effects/particle_atlas-v2.png: faísca, poeira, gelo e impacto, quatro frames por família.
- assets/vehicles/rover-v2.png: dois frames de direção, com alteração dos pneus, suspensão e luz da antena.
- assets/vehicles/rocket-v2.png: dois frames de foguete vertical com chama alternada.

O carregamento no Godot usa células nativas de 32×32 para terreno e veículos e de 16×16 para partículas, nearest-neighbour e paletas curtas. As cores do traje original (12173d, 6b74b2, 909edd, c1d9f2, 53a1ad) orientam os veículos; Marte usa as cores do mob original. Os PNGs de geração ficam preservados; os buffers de textura em memória usam a escala nativa. A primeira versão deixou de ser referenciada pelo jogo.

A animação original de três frames de assets/mobs_netuno/mob_netuno1 agora é usada pelos inimigos comuns de Netuno. Os sprites do time permanecem sem retoques.

## Viagens corrigidas

- Arenas 1→2, 2→3 e 3→4: rover em Marte.
- Arena 4→5: foguete de Marte a Netuno.
- Arenas 5→6, 6→7 e 7→8: rover em Netuno.
- Arena 8→9: foguete de Netuno a Júpiter.
- Arenas 9→10, 10→11 e 11→12: rover em Júpiter.
- Arena 12→13: foguete até o Nexo.
- Após arena 13: foguete de retorno e resultado da expedição.

O veículo no ponto de extração acompanha a rota. A loja, a placa de embarque e a dica da HUD também mostram o nome correto. O rover atravessa o terreno do planeta com pneus animados, rastro de rodas e poeira. O foguete sobe no espaço com chama animada. Cada sequência dura 2,4 segundos e preserva as chances por run, itens, módulos e uso do Berserk.

Validação: tests/art_revision_travel.gd verifica os frames, cores, resolução e a escolha do veículo nas 13 arenas; tests/terrain_art.gd verifica colisões e caminhos. Prévias: docs/preview-revised-rover-travel.png, docs/preview-revised-rocket-travel.png e docs/preview-terrain-0.png até 3.png.

Os veículos foram ampliados: caixa de desenho de 192 px na extração e 256 px durante a viagem, mantendo escala inteira dos pixels. Veja COLETA_E_PISOS.md para a etapa segura após o combate.
