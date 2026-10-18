# Campanha de 13 arenas

Quatro arenas por planeta, seguidas pelo Nexo final. Cada entrada abaixo é uma cena própria, com coberturas e marcadores editáveis no Godot. Os quatro setores de cada planeta compartilham o comportamento dos inimigos e a paleta, mas têm layouts diferentes.

| Arena | Nome | Cena em `scenes/world` | Layout |
| --- | --- | --- | --- |
| 1 | Marte / Colônia Ferrugem | `arena.tscn` | Duas coberturas assimétricas; introdução |
| 2 | Marte / Pedreira | `mars_quarry.tscn` | Quatro ilhas e corredor central |
| 3 | Marte / Hangares | `mars_hangars.tscn` | Duas barreiras horizontais |
| 4 | Marte / Reator | `mars_reactor.tscn` | Bloco central e duas coberturas menores |
| 5 | Netuno / Posto Boreal | `neptune_outpost.tscn` | Barreiras verticais desencontradas e geada |
| 6 | Netuno / Campos de Geada | `neptune_frostfields.tscn` | Ilhas simétricas e duas zonas de geada centrais |
| 7 | Netuno / Corredores de Vento | `neptune_windways.tscn` | Passagens alternadas e geada nas extremidades |
| 8 | Netuno / Núcleo da Tempestade | `neptune_storm_core.tscn` | Quatro coberturas ao redor da zona de geada central |
| 9 | Júpiter / Docas | `jupiter_docks.tscn` | Duas barreiras verticais e vento |
| 10 | Júpiter / Relés | `jupiter_relays.tscn` | Coberturas em zigue-zague |
| 11 | Júpiter / Olho do Ciclone | `jupiter_eye.tscn` | Quatro coberturas ao redor de uma área aberta |
| 12 | Júpiter / Coração da Tempestade | `jupiter_heart.tscn` | Centro aberto para o Titã com escudo |
| 13 | Nexo / Trono da Convergência | `alien_throne.tscn` | Arena de 1792 × 1088 px, mobs mistos e Deus Alienígena |

## Editar a sequência

Abra `scenes/main.tscn` e selecione a raiz `Noctir`. O campo **Arena Scenes** no Inspector contém a ordem das cenas. O controlador carrega a cena correspondente ao iniciar cada arena. Quatro fases formam cada setor (`ARENAS_PER_PLANET` em `scripts/game.gd`); cada fase tem um chefe e reforços.

Edite o arquivo de cena da fase que deseja alterar. Modificar `arena.tscn` altera apenas a primeira arena. Não renomeie os grupos `Floor`, `Obstacles`, `SpawnGates`, `Hazards` nem os marcadores principais. Os inimigos usam uma grade AStar reconstruída a partir dos pilares ao carregar a arena; não é necessário desenhar uma NavigationRegion2D. Se ampliar a campanha além das 13 fases, ajuste também o agrupamento por planeta e os dados de setores.

## Visual e HUD

A interface herda `ui_theme.tres`, que utiliza `fonts/w95fa/W95F.otf`. Apenas o título principal mantém After Burner Neue. A suavização das fontes foi desativada nas configurações de importação para manter os pixels definidos. Os arquivos originais da fonte, o README e a imagem que a acompanha foram preservados.

Menus usam bordas de 3 px, cantos retos, sombras deslocadas e um fundo quadriculado. As arenas usam detalhes em grade, bordas de 4 px e coberturas com rebites. Isso estiliza a interface e os cenários; os atores ainda têm arte provisória desenhada por código.

A HUD está em `scenes/ui/hud.tscn`: faixa superior de **72 px**, textos em **22 px**, corações, dados essenciais e dois slots de consumíveis. Um terceiro slot preto, acima do dash, mostra o equipamento de chão. A recarga do dash aparece no canto inferior direito. O tutorial fica no rodapé apenas durante a primeira arena.

As primeiras doze arenas têm **1536 × 896 px**, mantendo os sprites em sua escala original. As posições e dimensões das coberturas e dos marcadores foram distribuídas pelo espaço maior. A Camera2D acompanha o jogador com suavização e limites que deixam espaço para a HUD. O CanvasLayer mantém os menus, os corações, o dash e os avisos na tela enquanto o cenário se move.

`scripts/game.gd`, em `configure_camera()`, configura os limites a partir do piso de cada cena e reposiciona a câmera ao entrar em uma fase. O tremor de combate continua sendo aplicado por `scripts/combat_fx.gd`. Edite as dimensões de Floor e os marcadores no editor; evite ampliar o mapa escalando o nó raiz e os sprites juntos.

As prévias ficam em `docs/preview-menu.png`, `docs/preview-arena.png`, `docs/preview-neptune.png`, `docs/preview-boss.png` e no mosaico `docs/preview-arenas.png`.

`docs/preview-neptune-storm.png` mostra a janela ativa de geada. O setor de Netuno tem zonas que avisam antes de causar dano e lentidão, rajadas periódicas, gelo nas coberturas e inimigos com disparos duplos de estilhaços. O comportamento está descrito em [Combate e loja](COMBATE_E_LOJA.md).

## Verificação

O teste em `tests/smoke.gd` percorre as doze fases, confirma as rotas dos pontos de entrada até o jogador, a passagem até o portal, o movimento de um inimigo ao redor de um pilar, a fonte compartilhada, a altura da HUD, os upgrades e os chefes de todas as fases, os drops, os dois slots e a loja. A dificuldade e a duração total ainda precisam ser avaliadas em partidas humanas.


Atualização de combate: cada arena termina em chefe + reforços e depois abre a loja. Detalhes em [Combate e loja](COMBATE_E_LOJA.md).

O botão **Teste** do menu lista cada arena com acesso à horda ou diretamente ao chefe. A opção de invulnerabilidade e a escolha de equipamento só valem para essa sessão de teste. Veja `docs/EXPANSAO_INFINITA.md`.
