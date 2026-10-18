# Dificuldade da expedição

Iniciar Expedição abre a escolha de modo. A escolha vale pela run inteira; reiniciar conserva o modo. Voltar ao menu permite escolher outro. As três chances por run permanecem nos três modos. Teste de arenas utiliza o equilíbrio Médio e não dá recompensas.

| Ajuste | Fácil | Médio | Difícil |
| --- | --- | --- | --- |
| Coins permanentes por pontuação | 25% | 100% | 150% |
| Contrato por run | Desativado | Até 1 SpaceCoin | Até 1 SpaceCoin |
| Quantidade de inimigos e reforços | 70% | 100% | 130% |
| Vida dos inimigos e chefes | 70% | 100% | 135% |
| Movimento dos inimigos | 85% | 100% | 115% |
| Velocidade de projéteis inimigos | 85% | 100% | 120% |
| Tempo inicial por arena | 120% | 100% | 95% |

O multiplicador é aplicado à pontuação usada na conversão para Coins permanentes, mantendo o resto em pontos para a próxima moeda. Não multiplica a carteira existente, moedas coletadas na arena ou SpaceCoin. Bônus de Prestígio se combinam com os fatores do modo. Escudos dos chefes acompanham a vida ajustada.

O modo aparece na HUD e no relatório da run. Os contratos continuam únicos por run nos modos Médio e Difícil.

Validação: tests/difficulty.gd cobre seleção, fatores de combate, pagamento único, bloqueio de contratos, reinício e troca de modos. tests/input_flow.gd verifica os cliques reais no menu e os controles em combate.
