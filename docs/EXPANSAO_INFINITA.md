# Ciclos, equipamentos de chão e arena 13

## Prestígio repetível

O requisito continua sendo 1.000 Coins permanentes e os seis atributos no máximo. Cada reset zera os níveis comprados, concede 1 Prestígio e aumenta em 1 o máximo de cada atributo. O número de ciclos é salvo separado da carteira de Prestígio, que poderá ser gasta em skins sem reduzir a dificuldade acumulada.

Não existe um teto de ciclos configurado. A vida dos inimigos cresce 18% por ciclo e o dano aumenta a cada quatro ciclos. O piloto recebe uma base de +1 vida e +10% de dano inicial por ciclo. Movimento, velocidade de inimigos e recarga usam retornos decrescentes para manter o jogo controlável. Vida, dano e novos limites continuam crescendo. Recursos simultâneos de combate permanecem limitados para não acumular objetos indefinidamente.

## Dash

O jogador avança a 850 px/s por 0,24 s: aproximadamente 204 px, contra 112 px anteriormente. A invulnerabilidade cobre o dash e uma pequena margem. A movimentação é dividida em passos de até 12 px para não atravessar pilares. Dash ignora atração gravitacional e lentidão ambiental enquanto está ativo.

## Terceiro slot: tecla 3

O terceiro slot aceita somente equipamentos colocados no chão. Os slots 1 e 2 continuam aceitando os consumíveis originais. A run começa com uma mina para apresentar a função; os próximos equipamentos aparecem em drops independentes de 1,2% ou são comprados na loja orbital com moedas da run. A carteira SpaceCoin permanece reservada para o futuro catálogo permanente.

| Equipamento | Função | Duração | Preço básico |
| --- | --- | --- | --- |
| Mina orbital | Arma em 0,65 s; detecta inimigo a 105 px e explode com raio de 240 px. Dano 18× poder da arma, 32× contra chefes | 24 s ou até detonar | 28 |
| Torreta | Busca alvo com linha de visão até 460 px e atira a cada 0,3 s. Dano 0,8× poder da arma + 1 | 18 s | 32 |
| Baliza de contenção | Reduz velocidade de mobs em 45%, de chefes em 20%, e limpa tiros hostis num raio de 185 px a cada 1,2 s | 12 s | 30 |

Os preços somam `2 × índice da arena`. Cada equipamento tem estoque de uma unidade por parada e exige o terceiro slot vazio. O botão 3 consome o equipamento do slot e o coloca aos pés do jogador. Há no máximo quatro equipamentos ativos. Pausar congela sua duração; trocar de arena limpa os colocados, mantendo o que ainda estiver no slot. Tentativas de colocar dentro de cobertura, fora da arena ou acima do limite não consomem o item.

## Chefes e escudos

Marte persegue e avança em linha após travar uma mira antecipada. Netuno orbita, mantém distância e faz deslocamentos laterais rápidos. Júpiter intercepta a direção do jogador e executa avanços. Os avisos de movimento duram 0,65 s; a mira fica travada para permitir esquiva. Chefes comuns também combinam o anel anterior com três disparos apontados para a posição prevista do jogador.

Escudos absorvem o dano antes da vida. Projéteis colidem com o contorno visível e o dano excedente passa para a vida ao quebrar a proteção. A HUD mostra uma barra azul e a quantidade restante. Netuno tem 35% da vida em escudo no chefe comum e 55% no superchefe. Júpiter tem 65% e 85%, respectivamente. Esses dois escudos não regeneram automaticamente.

O superchefe de Marte usa os quatro quadros originais de `assets/mobs_marte/mob_marte3`, em escala 2×, sem modificar os PNGs. O chefe comum mantém `mob_marte2`.

## Arena 13: Nexo

`scenes/world/alien_throne.tscn` tem piso de 1792 × 1088 px. A horda possui 132 inimigos e intercala Marte, Netuno e Júpiter; os papéis de Júpiter continuam variados. A arena termina com o **Deus Alienígena**, com arte geométrica provisória.

O chefe tem 520 de vida e 390 de escudo no ciclo zero. Combina salvas sobrepostas com chuva de meteoros, olho gravitacional, prisão circular, explosões de tempestade, órbitas e dash. Ao entrar nas fases de 55% e 25% de vida, limpa os perigos e restaura 35% do escudo máximo uma vez. Não há regeneração contínua de escudo. Os ataques de terreno continuam com avisos, aberturas e limites de força. A arena começa com 240 s e a entrada desse chefe acrescenta 120 s.

Depois da loja final, a campanha termina normalmente. O loop infinito é o ciclo de prestígio e novas runs com limites e dificuldade maiores.

## Aba Teste

O menu principal abre uma lista das 13 arenas. Cada uma oferece **Arena** ou **Chefe**. O seletor permite começar com mina, torreta ou baliza e há invulnerabilidade opcional. A sessão recebe consumíveis e moedas temporárias para experimentar a loja.

Esse modo não altera Coins permanentes, SpaceCoin, recorde ou tempo total jogado. Contratos ficam desativados e o relógio da arena não acaba. Reiniciar mantém a arena e o equipamento escolhido. O resultado oferece repetir ou escolher outra arena; começar uma expedição pelo menu volta ao modo normal.

## Validação

- `tests/infinite_deployables.gd`: ciclos repetidos e altos, limites salvos, uso real do mouse no menu Teste, isolamento de progresso, equipamentos, escudos, movimentos, sprite de Marte e saúde elevada.
- `tests/smoke.gd`: campanha completa com 13 cenas, navegação, chefes, loja e vitória.
- `tests/spacecoin_prestige.gd`: migração de saves, cancelamento, reset e moedas especiais.
- `tests/density.gd -- --god` com `--fixed-fps 60`: na validação local atingiu 80 inimigos, 323 projéteis, 26 áreas e 1.262 partículas. Verifica funcionamento e limites; não mede FPS em outras máquinas nem substitui partidas humanas para ajustar dificuldade.

Prévias: `docs/preview-arena-test-menu.png`, `docs/preview-alien-god.png` e `docs/preview-mars-superboss-sprite.png`.
