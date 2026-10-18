# Música e efeitos originais

## Trilhas dos planetas

As três composições de `music/` são originais, sintetizadas em estéreo a 22.050 Hz. Usam referências de linguagem musical dos compositores pedidos, com timbres eletrônicos, pads e delay espacial; não são gravações nem transcrições de obras deles.

| Arquivo | Direção | Duração |
| --- | --- | --- |
| `music/mars.wav` | Referência Bach: ré menor, contraponto, arpejos de cravo sintetizado, pulso eletrônico a 112 BPM | 34,29 s |
| `music/neptune.wav` | Referência Mozart: ré maior, 4/4 a 160 BPM, melodia ágil no piano sintetizado e baixo de Alberti eletrônico | 48 s |
| `music/jupiter.wav` | Referência Chopin: dó menor, melodia lírica sobre piano sintetizado e arpejos em semicolcheias, pulso a 192 BPM | 30 s |

`music/preview.wav` reúne 12 segundos de cada planeta, nessa ordem. `tools/compose_planet_music.py` contém as melodias, harmonias, sintetizador e geração reproduzível. `compositions.json` registra os tempos e durações.

O nó `PlanetMusic` muda a faixa na troca de planeta e mantém a reprodução entre arenas do mesmo setor. O loop é configurado em tempo de execução, com caudas de delay circulares e emenda curta para evitar estalos. O volume baixa durante loja/pausa e respeita o volume geral e Mudo. Voltar ao menu ou encerrar a run interrompe a faixa do planeta.

`tests/shop_music.gd` decodifica mais de dois ciclos de cada faixa para verificar reprodução contínua e testa as transições no jogo.

## Disparo mais suave

`shot.wav` agora mistura seno e triângulo, com queda de 560 para 240 Hz, sem a camada de ruído do disparo anterior. A voz do tiro passou de -10 para -16 dB e continua limitada a uma reprodução por rajada.

## Efeitos

Foram sintetizados **22 efeitos**, sem samples externos. Eles já estão integrados ao jogo e passam pelo volume geral e pela opção Mudo. Os arquivos são WAV PCM de 16 bits, mono, a 22.050 Hz. Não são projetos BeepBox; você pode substituir os WAVs por seus próprios sons exportados mantendo os nomes.

Ouça `sfx_preview.wav`: disparo, dash, recarga, Eco, moeda, bônus de moeda, cura, escudo, explosão, alerta do chefe e vitória, separados por pequenas pausas.

| Arquivo em `sfx/` | Evento integrado |
| --- | --- |
| `shot.wav` | Disparo da arma, uma vez por rajada |
| `hit.wav` | Acerto em inimigo próximo |
| `player_hurt.wav` | Dano recebido pelo astronauta |
| `enemy_down.wav` | Morte de inimigo comum |
| `dash.wav` | Início do dash |
| `dash_ready.wav` | Fim da recarga do dash |
| `echo.wav` | Ativação do Eco |
| `coin.wav` | Coleta de moeda comum |
| `coin_bonus.wav` | Coleta rápida ou moeda rara |
| `item_pickup.wav` | Coleta de consumível |
| `heal.wav` | Uso do kit médico |
| `bomb.wav` | Bomba e explosão de chefe |
| `shield.wav` | Ativação do escudo |
| `overdrive.wav` | Ativação da sobrecarga |
| `ui_click.wav` | Confirmação de botão |
| `purchase.wav` | Compra concluída nas lojas |
| `error.wav` | Compra recusada por falta de moedas ou inventário cheio |
| `boss_alert.wav` | Entrada do chefe e mudanças de fase do superchefe |
| `stage_clear.wav` | Limpeza da arena e abertura da loja |
| `defeat.wav` | Fim da run por derrota |
| `victory.wav` | Vitória da campanha |
| `frost_warning.wav` | Aviso de geada em Netuno |

`scripts/game_audio.gd` limita o total a dez vozes. Duas ficam reservadas para dano e alertas; sons comuns têm espaçamento mínimo e não são reproduzidos quando a fonte está muito longe da câmera. Isso evita multiplicar o volume por dezenas de inimigos ou por cada projétil do leque.

O gerador reproduzível está em `tools/generate_sfx.py` e usa Python com NumPy. Frequências, envelopes, durações e formas de onda podem ser alteradas ali. Ele gera também a prévia e verifica se os sons têm conteúdo e não clipam individualmente.

## Música do menu

Os MP3 originais em `musica/` tinham aproximadamente **51,226 segundos**, com cerca de **25 segundos de silêncio no final**. As cópias em `musica/processed/` duram cerca de **26,445 segundos**. Os originais foram preservados.

O jogo toca a cópia de soundmenu1 uma vez e depois a cópia de SoundMenu com loop direto configurado em tempo de execução. Há também recuperação caso a reprodução pare inesperadamente no menu. Abrir Loja, Configurações ou Como Jogar não reinicia a faixa. Iniciar a run continua interrompendo a música de menu.

`tools/prepare_menu_audio.gd` recria as cópias com o decodificador do próprio Godot. O teste `tests/superboss_audio.gd` decodifica 90 segundos de reprodução para verificar que o silêncio longo não retorna.
