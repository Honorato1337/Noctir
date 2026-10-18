# Sugestões de áudio para o jogo

Esta é a direção sonora do projeto. As faixas fornecidas para o menu, três composições originais dos planetas e 22 efeitos originais já estão integrados. Veja a [biblioteca entregue](../assets/audio/README.md) e a prévia `assets/audio/sfx_preview.wav`. As sugestões abaixo continuam como referência para ampliar a variedade, ampliar as identidades dos planetas e produzir variações.

## Identidade

Misturar sintetizadores curtos de ficção científica com sons materiais: traje, metal, gelo, minerais e eletricidade. Os sons precisam informar o jogador durante hordas densas. Reservar os timbres mais claros para dano recebido, perigo ambiental, dash disponível e entrada do chefe.

## Controles e astronauta

| Evento | Som sugerido | Duração e variações |
| --- | --- | --- |
| Movimento | Passos abafados dentro do traje, com detalhe do piso | 4–6 variações; tocar por passada, não por frame |
| Dash iniciado | Jato curto com estalo eletrônico | 120–220 ms; sensação de deslocamento rápido |
| Dash recarregado | Dois bipes ascendentes suaves | 100–180 ms; uma vez quando a recarga terminar |
| Tentativa de dash indisponível | Clique seco e discreto | 50–80 ms; limitar repetição |
| Disparo do jogador | Pulso de plasma com ataque definido e cauda curta | 70–120 ms; 3–5 variações próximas |
| Disparo em leque | O mesmo ataque com uma camada mais aberta | Um som por disparo da arma, não por projétil |
| Sobrecarga ativa | Disparo um pouco mais grave e elétrico | Preservar a identificação da arma original |
| Dano recebido | Impacto no traje seguido de alerta eletrônico | 180–300 ms; deve se destacar dos impactos nos inimigos |
| Pouca vida | Dois pulsos graves espaçados | Aviso ao entrar em vida crítica; repetição lenta e moderada |
| Cura | Três notas ascendentes e fechamento pneumático | 300–500 ms |
| Morte | Falha elétrica e perda de sinal | 0,8–1,5 s; reduzir sons de combate nesse momento |

## Eco e itens

| Evento | Som sugerido | Duração e variações |
| --- | --- | --- |
| Ativar Eco | Sucção invertida, desaceleração curta e estalo de retorno | 500–800 ms; assinatura principal do jogo |
| Eco disparando | Versão filtrada e distante da arma | Mais baixa que a arma real; evitar duplicar o volume |
| Eco terminando | Cauda digital que se desfaz | 200–400 ms |
| Eco sem carga/histórico | Dois bipes descendentes | 100–150 ms; sem spam ao segurar Q |
| Kit médico | Clique da cápsula, ar pressurizado e notas de cura | 350–500 ms |
| Bomba orbital | Carga curta e explosão grave com ataque seco | 600–900 ms; um único impacto principal |
| Escudo ativado | Campo energético abrindo | 250–400 ms |
| Escudo terminando | Cristal eletrônico se fechando | 150–250 ms |
| Sobrecarga ativada | Motor carregando e nota elétrica ascendente | 300–500 ms |
| Sobrecarga terminando | Descarga descendente curta | 150–250 ms |

## Inimigos e combate

| Evento | Som sugerido | Observação |
| --- | --- | --- |
| Inimigo de Marte andando | Cliques de patas e fragmentos minerais | Usar apenas alguns inimigos próximos como fonte |
| Inimigo de Marte atacando | Estalo orgânico áspero | Não tocar continuamente pelo simples contato |
| Inimigo de Marte morrendo | Quebra de pedra com impacto úmido curto | 3 variações de 120–250 ms |
| Sentinela de Netuno disparando | Estalo de gelo com nota aguda curta | Um evento para o par de estilhaços |
| Sentinela de Netuno morrendo | Cristal fragmentando | Evitar agudos estridentes em hordas |
| Autômato de Júpiter preparando investida | Motor subindo de rotação | Deve antecipar o movimento, acompanhando o aviso visual |
| Autômato investindo | Chicote elétrico e jato metálico | Curto, com direção espacial |
| Autômato morrendo | Colapso metálico e faíscas | Cauda menor que a do chefe |
| Acertar inimigo | Impacto pequeno: mineral, cristal ou metal conforme o setor | Agrupar impactos muito próximos no tempo |
| Projétil na cobertura | Tique de metal ou gelo | Mais baixo que acertar um alvo |
| Entrada do chefe | Sirene curta, impacto grave e rugido próprio | 1–2 s; dar espaço ao anúncio visual |
| Chefe atingindo segunda fase | Descarga energética e rugido alterado | Um aviso único na transição |
| Chefe preparando ataque | Timbre específico do ataque | Prioridade maior que tiros e moedas |
| Chefe morrendo | Explosão em camadas e silêncio breve | 1,5–2,5 s; distinguir de uma morte comum |

## Planetas e ambiente

| Ambiente/evento | Sugestão |
| --- | --- |
| Marte | Vento seco baixo, estrutura metálica distante e pequenos detritos |
| Netuno em estado calmo | Ar frio, ressonância de gelo e um fundo sintético profundo |
| Aviso de geada em Netuno | Cristalização crescente durante os 1,5 s do aviso; terminar junto da ativação |
| Geada e rajada ativas | Vento mais forte e crostas estalando; cair ao terminar a janela de perigo |
| Júpiter | Vento grave, vibração de plataforma e eletricidade distante |
| Mudança de arena | Escotilha, propulsão e pequeno sinal de chegada |
| Portal disponível | Campo energético discreto; sinal único ao liberar a extração |
| Extrair | Confirmação ascendente e transporte rápido |
| Relógio quase acabando | Alerta espaçado nos segundos finais; não disputar prioridade com vida crítica |

## Moedas, loja e interface

| Evento | Sugestão |
| --- | --- |
| Coleta de moeda comum | Tique eletrônico brilhante, muito curto |
| Coleta rápida com bônus | Segunda nota acima da coleta comum |
| Moeda rara | Pequeno acorde, diferente de apenas aumentar o volume |
| Item coletado | Clique de encaixe no traje e bip de confirmação |
| Slots cheios | Bip opaco e curto; limitar a uma vez por segundo |
| Passar por botão | Clique leve; opcional para não cansar ao navegar |
| Confirmar botão | Estalo limpo, diferente da navegação |
| Voltar/fechar tela | Nota curta descendente |
| Comprar | Confirmação de transação e encaixe mecânico |
| Comprar melhoria permanente | Mesmo motivo da compra, com acorde adicional mais satisfatório |
| Sem saldo/estoque | Dois toques secos, baixos |
| Trocar ofertas | Sequência digital curta, com final neutro: não anunciar sucesso antes da oferta |
| Arena concluída | Pequena fanfarra de 1–2 s |
| Derrota | Motivo melódico descendente; deixar a nova tentativa convidativa |
| Vitória | Variação completa e mais longa do motivo de arena concluída |
| Novo recorde | Três notas ascendentes, distintas da vitória |

## Música

- **Abertura:** soundmenu1 uma vez ao abrir o jogo, seguida de SoundMenu em loop. Já integrado com cópias sem os cerca de 25 segundos de silêncio final dos MP3 originais, em `musica/processed`.
- **Marte:** batida seca, baixo simples e pulsos de sintetizador, deixando espaço para o tiro.
- **Netuno:** textura fria e espaçada, com ritmo que ganha tensão nas rajadas.
- **Júpiter:** baixo grave, percussão elétrica e sensação de instabilidade.
- **Chefes:** uma camada adicional de percussão e baixo; intensificar na segunda fase sem aumentar demais o volume.
- **Loja entre arenas:** retirar a percussão e usar um motivo mais calmo, mantendo a identidade do planeta.
- **Resultado:** frase curta de vitória ou derrota, com espaço para os efeitos de coins e recorde.

## Mixagem para hordas

1. Prioridade máxima: dano recebido, alertas de perigo, entrada e ataques anunciados do chefe.
2. Prioridade média: arma do jogador, dash, Eco, itens e confirmações de compra.
3. Prioridade baixa: impactos repetidos em inimigos, passos, moedas comuns e ambiente.

Proposta de implementação futura: barramentos **Master**, **Música**, **Efeitos**, **Interface** e **Ambiente**, todos sob o volume geral já existente. Usar AudioStreamPlayer2D para fontes do mundo e AudioStreamPlayer para avisos da interface. Dar mais volume e presença ao que estiver próximo da câmera.

Limitar sons simultâneos por família. Como ponto de partida: até 4 impactos, 3 mortes comuns e 2 coletas dentro de uma janela curta. Agrupar várias moedas coletadas de uma vez. Tocar a arma uma vez por rajada, mesmo com vários projéteis. Variar discretamente o tom dos impactos comuns, mas manter os tons dos alertas constantes para que sejam reconhecíveis.

Não depender somente de som: manter corações, barra do dash, avisos de geada, direção da investida e indicadores de extração para quem jogar sem áudio.

## Ordem sugerida de produção

**Primeiro:** tiro, acerto, dano recebido, morte, dash, dash pronto, Eco, moeda, item, botão e compra. Esses sons já dão resposta aos comandos e tornam o combate mais legível.

**Depois:** identidade dos três inimigos, aviso de geada, investida de Júpiter, chefe, fim de arena e extração.

**Por último:** passos, camadas de ambiente, variações de música por planeta e transições musicais. Reservar a identidade sonora do chefe de Marte para acompanhar a arte que ainda será enviada.
