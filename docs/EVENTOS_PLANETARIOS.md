# Eventos planetários

Todas as arenas recebem eventos após uma espera aleatória inicial de 8 a 13 segundos. Há dois segundos de aviso antes do perigo. O evento dura de 12 a 16 segundos, seguido de 13 a 21 segundos de intervalo. A arena final tem eventos de 19 segundos e intervalos menores, de 9 a 15 segundos.

- Marte: tempestade de areia móvel, partículas pelo terreno, atração num raio de 235 px e núcleo de dano de 62 px. O deslocamento rebate nas bordas.
- Netuno: chuva de gelo com marcação fixa no chão, cristais caindo e impacto após 1,1 s. Mover-se para fora da marca evita o dano.
- Júpiter: vórtice vermelho móvel, atração e ventos circulares num raio de 270 px, núcleo perigoso e descargas elétricas marcadas.
- Nexo, arena 13: dois vórtices de areia simultâneos, chuva de gelo, raios e meteoros. Meteoros têm área maior e aviso de 1,35 s.

O primeiro impacto de cada leva mira a posição atual do jogador, sem seguir seus movimentos; os demais se distribuem pelo mapa. No Fácil há menos quedas e intervalos maiores entre levas; no Difícil, mais quedas e intervalos menores. O dano respeita a imunidade e o Prestígio existentes. Dash ignora a atração; todas as forças ambientais combinadas têm limite de 170 px/s.

Pausa e tela de morte congelam o evento. Continuar após morrer limpa o clima atual e concede oito segundos antes de outro evento. A troca de mapa também limpa o clima. Loja e extração não avançam nem causam dano climático.

Limites: 48 impactos ativos, até dois vórtices e 180 partículas ambientais desenhadas sem criar nós. Impactos usam o orçamento de partículas de combate já existente.

Implementação: scripts/arena_weather.gd e nó ArenaWeather em scenes/main.tscn. Testes: tests/arena_weather.gd.
