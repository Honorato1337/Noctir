# Otimizações da versão 0.3.1

- Efeitos de combate: teto de 600 partículas no computador (antes 1.800), 96 no perfil móvel (antes 300). Limites adicionais por quadro evitam picos de explosões simultâneas.
- A densidade decorativa diminui gradualmente quando os quadros ficam lentos. A lógica, o dano e as marcações de perigo continuam independentes desse ajuste.
- Partículas fora da câmera deixam de ser criadas. Remoção por troca com o último elemento evita deslocar arrays inteiros.
- Tiros aliados usam uma grade espacial compartilhada por atualização da física. Seu desenho é criado no nascimento, em vez de ser reconstruído em cada atualização.
- Separação entre inimigos é calculada em intervalos distribuídos, mantendo o deslocamento em cada atualização da física.
- HUD atualiza a 30 Hz e imediatamente ao mudar de estado. Câmera e simulação continuam na frequência normal.
- Perfil móvel: 24 inimigos ativos, até 120 projéteis hostis/160 totais, 20 partículas ambientais e renderização interna de 1152×720 com limite de 60 FPS.
- Rover, foguete, terreno e partículas usam texturas pequenas preparadas antes da execução. As fontes artísticas permanecem no projeto.

## Verificação

O teste de grade comparou 1.000 posições com 60 inimigos: 1.435 candidatos contra 60.000 na busca completa, sem perder colisões, incluindo escudos. Esse resultado mede comparações, não um ganho de FPS.

Passaram os testes de orçamento de efeitos, campanha, coleta após combate e transições de veículos no computador. O teste de carga com chefe final e tempestade manteve a partida ativa com 80 inimigos e centenas de projéteis. Não houve validação em aparelho Android; sem um log do dispositivo, a causa do encerramento relatado permanece sem confirmação.

## Reconstruir as texturas preparadas

Ao alterar as imagens-fonte, remova somente os PNGs correspondentes em `assets/optimized`, execute `godot --headless --path . --script res://tools/bake_runtime_art.gd` e reimporte o projeto antes de exportar.
