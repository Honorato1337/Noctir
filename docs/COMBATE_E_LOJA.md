# Combate, consumíveis e loja

## Fontes

After Burner Neue permanece somente no título do menu principal. A interface restante, a loja, os números de dano e os avisos usam `fonts/w95fa/W95F.otf`, por meio de `ui_theme.tres` e da fonte do controlador. Os arquivos das fontes e suas licenças foram preservados.

## Fluxo de cada fase

As treze arenas seguem **horda → chefe e reforços → loja → extração**. A última loja, após o Deus Alienígena, encerra a campanha pelo botão Concluir Expedição.

- Horda inicial: `36 + arena_index * 6`, ou seja, de **36 a 102 inimigos**.
- Entrada em grupos de 6 a 9 inimigos, aproximadamente a cada 0,65–0,375 segundo, conforme a arena.
- Limite de **80 inimigos ativos**; os restantes aguardam na fila de reforços.
- Quando a horda inteira já entrou e pelo menos 65% dos seus inimigos foram eliminados, o chefe aparece junto de **14 a 36 reforços**.
- Enquanto estiver vivo, o chefe pode chamar grupos adicionais a cada 7 segundos. O orçamento dessas chamadas é finito: 12 a 23 inimigos. Depois de matar o chefe, ainda é preciso eliminar os inimigos restantes e a fila de reforços para abrir a loja.
- Chefes têm vida e cadência crescentes. Sua segunda fase aumenta a quantidade de projéteis radiais. Cada planeta mantém o comportamento visual do seu tipo de inimigo.
- A janela inicial vai de 105 a 171 segundos, mais módulos de tempo. A entrada do chefe acrescenta 20 segundos.

Os inimigos ficaram mais rápidos, os disparos hostis passaram para 225 px/s e o intervalo de invulnerabilidade depois de sofrer dano caiu para 0,65 segundo. A arma inicial também recebeu cadência de 0,18 segundo para viabilizar o combate de multidão. Esses valores são uma primeira passagem de balanceamento; dificuldade e duração precisam de partidas humanas.

## Superchefes de fim de planeta

As arenas **4, 8 e 12** terminam com Imperador Ferrugem, Leviatã Boreal e Titã da Tempestade. O chefe comum de Marte usa os quatro quadros do time em `assets/mobs_marte/mob_marte2`. A arte do superchefe continua provisória. Cada superchefe tem **2,4 vezes a vida** do chefe correspondente, raio de 40 px e três fases: inicial, abaixo de **55%** de vida e abaixo de **25%**.

Os padrões combinam anéis com corredor seguro, dois leques laterais e seis braços giratórios, sempre em camadas. Cada ataque começa com um aviso visual de **0,9s**. Os disparos causam 1 de dano e viajam entre 142 e 186 px/s, mais devagar que os tiros comuns. Os detalhes estão na seção final deste documento.

Ao mudar de fase, o superchefe limpa projéteis hostis, faz uma pausa curta e adiciona oito reforços uma única vez. Sua entrada adiciona dez reforços, aumenta em oito o orçamento de invocações e acrescenta **70 segundos** ao relógio, em vez dos 20 do chefe comum. As chamadas ocorrem a cada 5,5s, respeitando o orçamento finito e o limite de 80 inimigos ativos. O objetivo é densidade com oportunidades de esquiva; os valores ainda precisam de partidas humanas.

## Setor de Netuno

As arenas 5–8 usam plataformas em tons de azul e ciano, coberturas congeladas e sentinelas de gelo. Os inimigos mantêm distância e disparam dois estilhaços em leque a cada 2,4 segundos. Os projéteis hostis desse setor têm forma de cristal, trilha azul e núcleo claro. O chefe mantém o ataque radial e inicia um aviso de geada quando entra.

O perigo usa um ciclo local de **7 segundos**, reiniciado em cada arena. Aos **3,5s**, as zonas marcadas mostram **AVISO**; dos **5s aos 7s**, mostram **GEADA**, causam dano por contato e reduzem o movimento normal em **40%** dentro do raio de **54 px**. Durante essa janela, uma rajada empurra o traje para a direita e levemente para cima. O dash mantém sua velocidade e permite escapar. O relógio da tempestade para na pausa e na loja; após limpar a arena, a extração fica livre do efeito.

As cenas são `neptune_outpost.tscn`, `neptune_frostfields.tscn`, `neptune_windways.tscn` e `neptune_storm_core.tscn`. Os marcadores ficam em `Hazards`; os detalhes de gelo são desenhados por `arena_decor.gd` e `pixel_cover.gd`. Esses cenários e inimigos são uma interpretação de ficção científica.

## Moedas e itens no chão

Inimigos comuns têm **55% de chance** de deixar moedas. Quando há um drop, seu valor é **1 crédito (75%)**, **2 créditos (20%)** ou **5 créditos (5%)**. Chefes garantem **12 + arena_index créditos**, mesmo em uma fase de azar; superchefes acrescentam mais **12 créditos**. O índice da primeira arena é zero.

Coletar uma moeda em até **2,5 segundos** concede **+1 crédito**. O contorno verde indica essa janela; moedas de valor alto têm contorno dourado. A atração começa a **80 px**. Moedas comuns piscam nos dois segundos finais e **somem após 14 segundos**; a recompensa do chefe não expira. Os prazos param na pausa e na loja. Ao concluir a arena, apenas os drops ainda existentes são recolhidos automaticamente, **sem bônus rápido**. Assim, esperar a limpeza não rende o mesmo que coletar durante o combate.

Cada morte tem **2,5% de chance** de deixar também um consumível. Essa chance é independente a cada inimigo; não há garantia de item por fase. O personagem coleta o item ao tocar nele se houver espaço.

O inventário tem exatamente **dois slots**, sem empilhamento. Use **1** para o primeiro e **2** para o segundo durante o combate. Se estiver cheio, o item permanece no chão. Ao concluir a arena, itens restantes preenchem slots vazios; itens que continuarem no chão são descartados ao entrar na próxima arena. Moedas e itens carregados permanecem entre fases, mas são zerados ao reiniciar a partida.

Os coins da **loja permanente do menu** são outra carteira: vêm da pontuação e permanecem entre tentativas. As compras dessa loja dão bônus iniciais para as próximas runs. Veja [Progressão permanente](PROGRESSAO_PERMANENTE.md).

| Item | Efeito |
| --- | --- |
| Kit médico | Recupera até 3 pontos de vida; não é consumido se a vida estiver cheia |
| Bomba orbital | Causa 12 de dano em cada inimigo comum e 24 nos chefes; limpa os projéteis presentes |
| Escudo | Concede pelo menos 5 segundos de invulnerabilidade |
| Sobrecarga | Durante 9 segundos, aumenta o dano em 50% e reduz o intervalo de tiro para 45% |

## Loja

O cronômetro fica parado enquanto a loja está aberta. Cada fase oferece três módulos distintos sorteados, compráveis uma vez por visita. Os efeitos duram até o fim da tentativa. A intenção é escolher entre uma melhoria, uma compra de sobrevivência ou poupar para as próximas arenas.

| Módulo | Preço base |
| --- | --- |
| Estabilizador | 30 |
| Propulsor | 32 |
| Traje | 36 |
| Reator | 38 |
| Prisma | 40 |
| Plasma | 44 |

O preço parte de `base + arena_index * 5` e cresce **35% por cópia já instalada do mesmo módulo**. Normalmente varia entre **90% e 120%** desse valor. Cada oferta tem **12% de chance** de promoção, custando **65%** do valor atual. O preço é arredondado e permanece fixo enquanto a oferta não é trocada. Promoções aparecem como **OFERTA!**, e passar o mouse explica o desconto.

O botão **Trocar** sorteia novamente apenas módulos não comprados. A primeira troca custa `12 + arena_index * 2`; a segunda custa mais 8 moedas. Há **duas trocas por parada**, sem garantia de promoção. Módulos instalados permanecem instalados e não voltam a ficar à venda nessa visita. A troca é uma aposta paga, não uma fonte de moedas.

O reparo imediato de **2 pontos de vida** custa `16 + arena_index * 2`. Bomba, escudo e sobrecarga custam `20 + arena_index * 2` cada e ocupam um slot. Há **uma unidade de cada suprimento por parada**, incluindo o reparo. Se faltarem moedas, houver vida cheia para reparo, slots cheios para consumíveis ou estoque esgotado, a compra é recusada sem cobrar. Não é obrigatório gastar para continuar. Moedas poupadas podem financiar várias compras em uma visita futura.

A tela editável é `scenes/ui/shop_screen.tscn`. **Probabilidades, preços e prazos** ficam em `scripts/economy.gd`. Estoque e transações estão em `scripts/game.gd`; os itens e a coleta estão em `scripts/loot_system.gd`.

O teste de economia simula 200 sementes por arena (2.400 cenários), incluindo todos os reforços opcionais e os extras dos superchefes, coleta rápida de 60% das moedas e resgate do restante. Essa hipótese é generosa: ignora perdas por expiração e inflação por módulos já instalados. Com os novos drops, 232 cenários (cerca de 10%) permitiram comprar os três módulos. Os contratos pagam SpaceCoin e não aumentam a renda da loja orbital. O teste detecta renda excessiva e não substitui partidas humanas para ajustar o risco da coleta.

## Efeitos e densidade

`scripts/combat_fx.gd` desenha faíscas, explosões, dano flutuante e partículas de coleta, além de movimentar levemente a câmera nos impactos. Dash deixa partículas e os consumíveis têm efeitos visuais próprios. A HUD usa outro CanvasLayer, por isso fica estável durante a tremida.

Há um orçamento de **1.800 partículas** e 100 textos flutuantes simultâneos. O teste `tests/density.gd` simula uma arena de Netuno com um superchefe, inimigos, disparos e efeitos. Na validação local desta versão, atingiu 80 inimigos, 325 projéteis e 913 partículas simultâneos sem erros. Esse teste de lógica não mede FPS em outros computadores.

Os efeitos sonoros já estão integrados, com dez vozes no máximo e duas reservadas para dano e alertas. A [biblioteca de áudio](../assets/audio/README.md) lista os 22 sons e explica como substituí-los.

## Verificar

```powershell
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --script res://tests/economy.gd
godot --headless --path . --script res://tests/neptune.gd
godot --headless --fixed-fps 60 --path . --script res://tests/density.gd
```

O primeiro teste percorre as 12 fases, os chefes, a loja e as regras de dinheiro e inventário. O segundo verifica o comportamento sob alta densidade. As prévias estão em `docs/preview-arena.png` e `docs/preview-shop.png`.


## Ícones e slots na HUD

Os itens no chão e os dois slots exibem os mesmos ícones de `assets/icons`: kit médico, bomba, escudo e sobrecarga. Os slots são quadrados pretos no canto superior direito, identificados por 1 e 2. Um slot vazio não mostra ícone; usar um item remove seu ícone. Ao coletar outro, ele ocupa o primeiro slot disponível. A chance de consumível continua em 2,5%, com os efeitos descritos acima. A HUD usa fonte de 22 px e mostra apenas dados essenciais.


## Loja compacta e superchefes em camadas

Os cartões da loja mostram apenas nome e preço. Os efeitos, contrapartidas, duração dos suprimentos e condições de compra aparecem em uma janela ao passar o mouse; navegar com Tab também revela os detalhes. A janela não captura cliques e desaparece ao sair do controle. Os dois slots continuam mostrando os ícones dos itens.

Nas arenas 4, 8 e 12, a vida do superchefe passou de `(40 + arena_index * 12) * 1,5` para `(40 + arena_index * 12) * 2,4`: aumento de 60%. A entrada concede agora 70 segundos adicionais no total, em vez de 40. A imunidade do jogador após dano e o dano de 1 por projétil permanecem.

Cada ataque usa de duas a quatro salvas sobrepostas, espaçadas em 0,32 s, conforme a fase. Os anéis usam 40/48/56 direções antes de excluir um corredor seguro de 0,6 radianos; as camadas preservam o mesmo corredor, indicado durante o aviso de 0,9 s. Outros padrões combinam dois leques laterais ou seis braços giratórios. As velocidades vão de 142 a 186 px/s e os projéteis duram 3,5 s. A mudança de fase limpa os tiros e as salvas pendentes, oferecendo uma pausa para reposicionar.

Há coroas, satélites e faíscas cosméticas constantes. O emissor do superchefe interrompe novas emissões quando há 480 projéteis na cena; inimigos comuns e o jogador continuam com seus próprios disparos. Reforços continuam finitos, e as partículas respeitam o limite de 1.800. O teste de densidade usa a terceira fase dos superchefes de Netuno e Júpiter; isso verifica limites e funcionamento, não substitui partidas humanas para ajustar dificuldade e FPS.


## Mecânicas de terreno por planeta

As salvas sobrepostas continuam, combinadas com mecânicas ambientais próprias:

- **Marte:** cinco a sete explosões sinalizadas ao redor da última posição do jogador, com detonações escalonadas. A segunda sequência também antecipa um enxame de oito a doze reforços, consumindo o orçamento finito existente.
- **Netuno:** prisão circular de gelo, quatro a seis regiões de geada ao redor e os perigos normais da arena. A prisão procura uma abertura de passagem sem pilares e dentro da arena; se não houver uma passagem reta disponível, a prisão não é criada naquele ataque. A abertura verde não causa dano nem empurra. As outras partes do anel causam 1 de dano por contato e empurram para dentro, sem criar paredes permanentes. Dash atravessa as regiões perigosas durante sua imunidade.
- **Júpiter:** olho gravitacional de raio 340 px que atrai o jogador, combinado com cinco a sete explosões de tempestade. O centro causa dano. A atração é limitada a 170 px/s mesmo com vários campos, e o dash ignora a força. Os olhos ficam nas posições anunciadas, em vez de seguir o jogador.

Explosões avisam por pelo menos 1,05 s; a prisão avisa por 1,25 s, e a gravidade por 1,1 s. As fases seguintes intensificam o número de regiões e as salvas. Cada mudança de fase limpa os perigos do chefe; matá-lo também remove suas áreas imediatamente. Pausar congela contagens e dano. Existem no máximo 96 áreas, com limite de 24 criadas por mobs comuns. Os parâmetros ficam em `scripts/planet_encounters.gd`.

## Mobs de Júpiter

Cada inimigo comum recebe um de três papéis por sorteio. Carregadores avançam rapidamente e deixam minas elétricas que explodem após 0,85 s. Atiradores procuram distância, travam a mira por 0,7 s e disparam cinco projéteis. Guardiões têm mais vida, disparam três projéteis e criam poços gravitacionais menores. Faixas claras identificam os atiradores; um anel identifica guardiões. Os emissores desses papéis param de criar projéteis quando a cena chega a 480, preservando espaço para o jogador.

O teste de Júpiter (`tests/density.gd -- --jupiter`, com `--fixed-fps 60`) atingiu 80 inimigos, 433 projéteis, 33 áreas e 1.461 partículas na validação local. A dificuldade final ainda precisa de partidas humanas.

## Replay: contratos por run

Um único objetivo é sorteado no início de cada run:

- Derrote seis chefes (superchefes também contam).
- Derrote dois superchefes.
- Derrote quatro chefes sem morrer entre eles. Sofrer dano é permitido; morrer reinicia a sequência.

O progresso continua entre arenas. Completar o contrato paga uma única SpaceCoin, salva imediatamente no perfil; o limite é uma por run. Arenas seguintes não renovam objetivos nem pagamentos. Moedas, dash e inimigos comuns não avançam contratos. Reiniciar descarta o progresso incompleto e sorteia outro objetivo. A moeda já paga permanece. Modo Teste não avança contratos nem concede SpaceCoin.

SpaceCoin compra habilidades na Loja; a aba de equipamentos continua como teste.

