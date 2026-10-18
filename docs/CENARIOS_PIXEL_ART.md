Versão atual: veja REVISAO_DE_ARTE.md. O atlas ativo é planet_terrain_atlas-v2.png; as imagens sem v2 documentam a primeira versão.

# Cenários em pixel art

Atlas criado com imagegen usando os sprites do astronauta e dos mobs fornecidos como referência visual. O PNG está em assets/environment/planet_terrain_atlas.png. Os sprites originais do time foram preservados.

Cada linha do atlas pertence a um ambiente: Marte, Netuno, Júpiter e Nexo. As quatro colunas são piso, rocha maciça, conjunto de rochas e segmento de paredão.

- Marte: solo ferruginoso e rochas de basalto vermelho, com sombras roxas que combinam com os mobs marcianos.
- Netuno: terreno azul escuro, pedras índigo e gelo ciano. A ambientação é uma região rochosa gelada fictícia associada ao planeta.
- Júpiter: ilhas rochosas escuras com veios âmbar e tons da tempestade joviana, em vez de um solo literal de planeta gasoso.
- Nexo: pedra violeta e pequenos cristais alienígenas, reunindo a linguagem das áreas anteriores.

As antigas caixas são formações rochosas, alternando duas variantes. Barreiras compridas recebem várias pedras em vez de uma imagem esticada. Os paredões ficam fora da área transitável; as caixas conservam seus retângulos de colisão e navegação, preenchidos pela massa de pedra. Todos os mapas usam o mesmo sistema e continuam editáveis pelas posições e tamanhos dos nós Obstacles.

O piso é escurecido na renderização para destacar o astronauta, os inimigos, itens e avisos de ataques. Filtro nearest preserva os contornos pixelados. A grade de linhas, moldura tecnológica e marcadores decorativos antigos foram retirados.

Integração: scripts/planet_terrain.gd, scripts/arena_decor.gd, scripts/pixel_cover.gd e scripts/arena_layout.gd. Para trocar as imagens, mantenha o atlas quadrado dividido em quatro linhas e quatro colunas. O código adapta os recortes ao tamanho da imagem.

Validação: tests/terrain_art.gd verifica os treze mapas, obstáculos e rotas. As prévias estão em docs/preview-terrain-0.png até preview-terrain-3.png. O prompt de geração está em assets/environment/GENERATION_PROMPT.md. Foi usado o gerador integrado, sem API/CLI externo.

## Chefe de Netuno — 0.1.5

O chefe das arenas 5–7 usa os três frames originais em assets/mobs_netuno/mob_neturno2, animação walk de 8 FPS e escala inteira 3×. Espelha para o jogador, pausa junto com o combate e mostra feedback de dano. O desenho genérico do corpo foi removido desses chefes, mantendo escudo, vida, colisão e ataques existentes. Recurso: assets/mobs_netuno/mob_neturno2/boss_frames.tres; nó: NeptuneBossVisual em scenes/actors/enemy.tscn.
