# Carteiras e progressão permanente

O menu principal tem o botão **Loja**, com o saldo atual. A tela de resultado também permite abrir a loja diretamente.

## Como ganhar coins

**100 pontos da run = 1 coin permanente.** As sobras são acumuladas entre tentativas: uma run de 1.234 pontos rende 12 coins e guarda 34 pontos; outra de 76 rende mais 1 coin e deixa 10 pontos guardados.

Vitória e derrota concedem coins. A vitória considera a pontuação final, incluindo o bônus de vida. Reiniciar, voltar ao menu ou fechar normalmente a janela também encerra a contagem da run atual e converte os pontos já conquistados. Cada run é contabilizada apenas uma vez: abrir a loja, voltar ao resultado ou apertar os botões novamente não repete o pagamento. Fechamento forçado ou falha do processo antes de contabilizar não garante a recompensa da run em andamento.

Esses coins são separados das **moedas coletadas nas arenas**. Coins compram bônus permanentes no menu; moedas da arena continuam comprando módulos temporários e suprimentos entre fases. As novas carteiras SpaceCoin e Prestígio também são independentes.

## Melhorias

| Melhoria | Bônus por nível | Limite | Preços dos níveis em coins |
| --- | --- | --- | --- |
| Blindagem | +1 de vida máxima | 3 | 45 / 100 / 180 |
| Núcleo de plasma | +5% de dano inicial | 5 | 30 / 55 / 90 / 140 / 210 |
| Gatilho refinado | +4% de cadência inicial | 3 | 35 / 75 / 135 |
| Botas orbitais | +4% de movimento inicial | 3 | 25 / 60 / 110 |
| Propulsor auxiliar | -6% de recarga inicial do dash | 3 | 30 / 65 / 120 |
| Reserva temporal | +2 segundos por arena | 3 | 25 / 55 / 100 |

Os percentuais acumulam sobre o atributo inicial: dano no nível 5 dá +25%, por exemplo. A cadência divide o intervalo original por `1 + 0,04 * nível`. Os módulos adquiridos dentro da run são aplicados depois, mantendo seus próprios efeitos e custos.

As compras entram em vigor na **próxima expedição**, em uma nova instância do personagem. Reiniciar não reaplica os bônus sobre valores já aprimorados. A loja mostra nível atual, bônus total e preço do próximo nível; bloqueia compras sem saldo ou acima do limite. Os módulos da run, as moedas da arena e os consumíveis continuam sendo zerados ao reiniciar.

## Salvamento e edição

- `scripts/progression.gd`: conversão, catálogo, preços, níveis, aplicação dos bônus e salvamento.
- `scenes/ui/permanent_shop.tscn`: layout editável dos seis cartões, saldo e retorno ao menu.
- `scripts/game.gd`: navegação, contabilização única de cada run e ligação dos botões.
- `user://progression.cfg`: saldo de coins, sobra de pontos e níveis comprados. O arquivo é gravado após a contabilização e após cada compra. O recorde anterior continua em `user://record.cfg`.

No Godot, **Project > Open User Data Folder** abre a pasta do save. As gravações escrevem um arquivo temporário e depois substituem o arquivo completo. Uma compra cuja gravação falhe é desfeita sem cobrar; se a gravação da recompensa falhar, o saldo fica disponível na sessão e o resultado mostra o problema.

Não renomeie `PermanentBuy1` a `PermanentBuy6`, `PermanentLevel1` a `PermanentLevel6`, `PermanentCost1` a `PermanentCost6`, `PermanentWallet`, `PermanentProgress`, `PermanentNotice` e `BackButton` sem atualizar o controlador. O tema continua W95FA, com After Burner somente no título principal.

## Verificação

```powershell
godot --headless --path . --script res://tests/progression.gd
godot --headless --path . --script res://tests/smoke.gd
godot --path . --script res://tests/menu_preview.gd
```

O teste de progressão usa um arquivo separado dentro de `tmp`, que é removido ao terminar. Todos os testes e capturas usam perfis em memória; não carregam nem alteram o saldo real do jogador. O teste verifica persistência, substituição do save existente, rejeição de compras inválidas, rollback se a gravação falhar, efeitos nas próximas runs e proteção contra pagamentos duplicados.


## SpaceCoin dos contratos

Cada run sorteia um único contrato: seis chefes, dois superchefes ou quatro chefes sem morrer entre eles. O progresso atravessa arenas; morrer zera somente a sequência do terceiro objetivo. Há um limite de **1 SpaceCoin por run**. Completar o contrato dá **1 SpaceCoin**, creditada e salva imediatamente em `user://progression.cfg`. Não é necessário vencer nem encerrar a run para guardar a recompensa. O mesmo contrato não paga duas vezes. O resultado mostra o ganho desta expedição e o saldo, e a Loja mostra as três carteiras permanentes.

A aba **Equipamentos / Teste** apresenta Trajes, Armas e Módulos como espaços reservados. As futuras compras darão habilidades e usarão SpaceCoin. Nesta versão não há preços, compras nem habilidades de equipamento; os cartões ficam desabilitados.

## Prestígio

Na aba **Prestígio**, o reset exige simultaneamente:

- Todos os seis atributos permanentes no último nível (20 níveis no ciclo zero; mais seis níveis a cada ciclo).
- Saldo de pelo menos **1.000 Coins permanentes**, obtidos com pontos das runs.

O botão abre uma confirmação com o custo e os efeitos. Confirmar consome exatamente **1.000 Coins**, zera os seis atributos e concede **1 Prestígio**. Coins acima do custo, SpaceCoin, Prestígio anterior, sobra de pontos, recorde e configurações são preservados. Os níveis comprados voltam a zero na próxima run; o bônus de ciclo permanece. Cada reset aumenta em **1** o limite de cada atributo e a dificuldade dos inimigos. Para fazer outro reset é necessário alcançar os novos máximos e reunir o custo novamente. Não há limite de ciclos definido no jogo.

Prestígio é uma moeda reservada para skins. A aba **Skins / Em breve** já existe, mas não oferece compras nesta versão. O histórico de ciclos fica salvo separadamente do saldo, para permitir gastar a moeda em implementações futuras.

A transação é desfeita por completo se o salvamento falhar. Cancelar a confirmação não altera o perfil. O botão fica bloqueado quando falta saldo ou algum atributo não está no máximo.

## Compatibilidade dos saves

O arquivo mantém `wallet.coins`, `wallet.remainder` e a seção `upgrades`. Foram acrescentados `wallet.space_coins`, `wallet.prestige` e `wallet.prestige_cycles`. Um save antigo recebe zero nas novas carteiras, preservando os valores anteriores. Todas as compras, recompensas e resets salvam as novas carteiras junto das antigas.

`tests/spacecoin_prestige.gd` verifica migração, salvamento, isolamento das moedas, falha de gravação, requisitos, confirmação/cancelamento, resets repetidos, atributos da próxima run e permanência da SpaceCoin após derrota. Usa um perfil isolado em `tmp/`, sem alterar o save real.


## Escala dos ciclos

`max_level(chave)` retorna o limite original + `prestige_cycles`. Os preços além da tabela original continuam a partir do último preço, somando 80 por nível adicional. O carregamento do save lê primeiro o ciclo e depois valida os níveis contra os limites expandidos.

A vida dos inimigos é multiplicada por `1 + 0,18 × ciclo`. O dano de contato, projéteis e áreas é `1 + floor(ciclo / 4)`. A velocidade aumenta gradualmente com retornos decrescentes. O piloto mantém +1 vida máxima e +10% do dano inicial por ciclo para que o reinício continue jogável. Curas acrescentam o ciclo à quantidade básica; bombas acompanham o poder atual da arma.

Movimento e recarga de dash usam retornos decrescentes depois dos três primeiros níveis. Isso evita velocidade impraticável ou recarga negativa; os níveis máximos e o poder de vida/dano continuam crescendo. Acima de 42 de vida, a HUD usa um coração com contador exato, sem criar milhares de desenhos.

A expansão é verificada também por `tests/infinite_deployables.gd`, incluindo ciclos altos, salvamento dos novos máximos e dano dos inimigos.

## Equipamentos de armas

Em Loja → Equipamentos, a espingarda é desbloqueada por **3 SpaceCoins**. A compra é permanente e permite escolher a arma das próximas runs nessa aba, sem cobrar novamente. A arma original é gratuita e continua disponível.

- Original: um projétil, intervalo base de 0,18s.
- Espingarda: três projéteis em leque, intervalo base de 0,48s e os dez frames de gun2.
- Prisma adiciona dois projéteis em qualquer arma; melhorias de cadência continuam funcionando.
- Eco grava o modelo da arma, os projéteis e o dano usados no momento original.

O desbloqueio e a seleção são preservados ao morrer, trocar de arena, iniciar nova run e fazer Prestígio. Os saves antigos começam com a arma original e mantêm seus saldos. O equipamento não ocupa os slots [1], [2] ou [3] e não é vendido por moedas da run.
