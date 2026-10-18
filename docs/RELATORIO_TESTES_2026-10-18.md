# Relatório de testes — One More Orbit

Data: 18/10/2026. Código avaliado: `33c325f`. Godot 4.7.2, Windows.

## Resultado

Foram executadas 39 suítes automatizadas. Após repetir com janela as cinco suítes que dependem de renderização e entrada, 35 suítes passaram e quatro continuaram com expectativas desatualizadas. Foram contabilizadas 973 verificações aprovadas, substituindo os resultados headless pelos resultados com janela nas cinco repetições.

Uma reprodução adicional confirmou um defeito no histórico do Eco. Nenhuma correção no código do jogo foi feita nesta auditoria.

## Bug confirmado

### Prioridade média: Eco reproduz disparos que foram bloqueados pelo limite de projéteis

**Impacto:** em combate saturado, o Eco pode causar dano com tiros que o jogador não chegou a disparar. A limitação de projéteis protege o desempenho, mas o histórico registra tentativas como se fossem tiros reais. O problema também se aplica ao Berserk.

**Reprodução isolada:**

1. Iniciar uma partida com perfil mobile e espingarda.
2. Ocupar o limite total de 240 projéteis.
3. Tentar disparar: o total permanece em 240, mas o histórico registra três tiros.
4. Liberar os projéteis e ativar o Eco com histórico suficiente.
5. O Eco gera três projéteis referentes ao disparo recusado.

**Evidência obtida:**

```
REPRO bullets_at_cap=240 recorded_shots=3
REPRO echo_bullets_after_clearing=3
```

**Causa:** `scripts/game.gd:495` retorna `null` quando o orçamento acaba, enquanto `scripts/player.gd:226` e `fire_berserk()` devolvem todas as direções tentadas sem conferir se o projétil foi criado. A reprodução usa o limite real do perfil mobile, preenchido artificialmente para tornar o caso determinístico; não estima sua frequência em partidas normais.

**Correção recomendada:** gravar no histórico apenas direções para as quais `game.shoot()` retornou um projétil válido. Acrescentar cobertura para disparo parcialmente aceito, espingarda e Berserk no limite.

Script e saída: `tmp/qa-audit/echo_cap_repro.gd` e `tmp/qa-audit/echo_cap_repro.log`.

## Problemas da bateria de testes

Estes resultados não foram classificados como defeitos do jogo:

| Suíte | Motivo da falha atual |
| --- | --- |
| `infinite_deployables` | Tenta abrir a aba Teste sem liberar o acesso de desenvolvedor. A execução não alcança todas as verificações e termina por timeout. |
| `spacecoin_prestige` | Ainda espera prévias indisponíveis na área de equipamentos, que já possui compra funcional de arma. |
| `superboss_audio` | Compara a vida dos três superchefes com uma fórmula anterior ao rebalanceamento e aos multiplicadores de dificuldade/progressão. |
| `neptune` | Exige texto contendo BOReAL na entrada da última arena de Netuno; o aviso atual usa o nome do superchefe Cervo Abissal. |

Recomendação: atualizar essas quatro suítes antes de usar o resultado agregado como critério para uma release. Suas partes não executadas não devem ser consideradas validadas.

## Fluxos que passaram

- Menu, seleção de dificuldade, cliques, pausa e retomada.
- Configurações, remapeamento, controles por toque simulados e entradas de controle cobertas pela suíte.
- Câmera, HUD fixa, dash e viagem do foguete com renderização real.
- Inventário, bomba com dano por distância e limite de alvos, espingarda e skins.
- Economia, progressão, contratos cobertos pelos testes, chances por run e recompensas de extração.
- Sobrevivência, eventos climáticos, arenas e mecânicas de inimigos cobertas pelas suítes.
- Limites do perfil mobile: inimigos, partículas, campos e projéteis.
- Teste de densidade terminou em estado `playing`, com 80 inimigos, 377 projéteis, 1.028 partículas e 15 campos, sem travamento durante a amostra. Isso não representa medição de FPS ou teste prolongado de estabilidade.

## Avisos e limites

Alguns processos de teste emitiram avisos de ObjectDB/recursos ainda em uso no encerramento. Isso merece investigar a limpeza dos testes, mas não comprova vazamento crescente durante uma partida.

As falhas iniciais de mouse, toque, câmera, hover da loja e animação do foguete desapareceram ao repetir as suítes com janela. Portanto, não foram reportadas como bugs de gameplay.

O APK não foi validado em aparelho Android físico, e um joystick físico não foi testado manualmente. As validações mobile são simulações e checagens do perfil de desempenho no Windows. Não foram auditados os binários publicados contra o código atual. Também não foi realizada uma campanha completa manual nem uma sessão prolongada de sobrevivência.

Resultados detalhados: `tmp/qa-audit/results.json`, `tmp/qa-audit/native-results.json` e logs na mesma pasta. Os testes da loja também geraram imagens de prévia em `docs/preview-shop.png` e `docs/preview-shop-hover.png`.

## Atualização após correções

O histórico de tiros foi corrigido em `scripts/player.gd`: disparos recusados pelo limite de projéteis não são mais registrados. Espingarda e Berserk também registram somente os projéteis efetivamente criados quando há espaço para apenas parte do disparo.

Adicionado `tests/echo_projectile_cap.gd`, executado com os limites desktop, cobrindo bloqueio completo, aceitação parcial, reprodução do Eco e comportamento normal das armas.

As quatro suítes desatualizadas foram ajustadas ao acesso de desenvolvedor, equipamentos atuais, nomes, balanceamento dos superchefes, tempo do dash e duração da baliza.

Validação desta correção: sete suítes desktop aprovadas, totalizando 379 verificações: `echo_projectile_cap`, `neptune`, `superboss_audio`, `infinite_deployables`, `spacecoin_prestige`, `shotgun` e `smoke`. `git diff --check` também passou. Não foi executada validação de celular nesta etapa, conforme solicitado. Avisos de ObjectDB no encerramento de testes continuam como observação de diagnóstico, sem confirmação de vazamento durante gameplay.
