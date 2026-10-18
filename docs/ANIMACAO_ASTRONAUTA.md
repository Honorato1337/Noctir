# Animação do astronauta

Os cinco PNGs criados pelo time foram integrados sem alteração em `asssets/astronauta` (o diretório existente tem três letras “s”). Cada frame tem 32 × 32 pixels e transparência.

## Onde editar no Godot

Abra `scenes/actors/player.tscn` e selecione **Visual**, um AnimatedSprite2D. Clique no recurso **Sprite Frames** no Inspector para abrir o editor de animações.

- **walk:** os cinco frames, em ordem de 0 a 4, com loop a **10 FPS**.
- **idle:** somente `pixil-frame-0.png`, exibido ao parar.
- **Scale:** 2 × 2, mantendo escala inteira e filtro nearest.
- **Position:** (0, -8), para alinhar os pés à posição lógica do personagem.

O recurso compartilhado está em `asssets/astronauta/astronaut_frames.tres`. Para ajustar a cadência, altere o FPS de walk nesse recurso. O dash acelera a reprodução em 1,8×. A animação acompanha o movimento também no caminho até o portal; pausa, loja, menu e tela de resultado interrompem a reprodução.

## Eco e combate

O histórico do rebobinador registra o frame exibido. `EchoVisual` usa o mesmo PNG gravado, com transparência e coloração ciano. A indicação de mira, o escudo, a sobrecarga, o piscar após dano e as partículas continuam funcionando.

A colisão, a velocidade, o dano e a lógica de tiro foram preservados. A arte recebida tem uma única vista; o personagem permanece nessa orientação, sem inventar vistas ou rotacionar o desenho conforme a mira.

O campo **Use Placeholder Graphics**, na raiz do personagem, permite voltar ao desenho geométrico para comparação. O padrão agora é usar a animação criada pelo time.

## Verificar

Use F5 para jogar. O teste específico está em `tests/astronaut_animation.gd`: verifica andar, parar, avançar frames, pausar e reproduzir os frames no eco. O teste de jogo geral permanece em `tests/smoke.gd`.

## Arma e música do menu

A arma usa `assets/gun/gun.png` sem alterar o PNG original. Em `scenes/actors/player.tscn`, os nós `Weapon/Sprite` e `EchoWeapon/Sprite` usam um AtlasTexture com a região visível do desenho (7, 12, 10, 9), escala 2x e filtro nearest. O pivô fica na altura das mãos, acompanha a mira e passa atrás do corpo ao apontar para cima. O histórico do Eco inclui a direção da arma.

Ao abrir o jogo, o nó `MenuMusic` toca soundmenu1 uma vez. O sinal `finished` inicia SoundMenu, com loop configurado em tempo de execução. O jogo usa cópias WAV em `musica/processed`, sem a longa cauda silenciosa dos MP3 originais. Navegar entre menu, Loja, Como Jogar e Configurações mantém a reprodução sem recomeçar a faixa. Iniciar uma run interrompe a música; ao voltar ao menu, apenas o loop retorna. O volume próprio é -12 dB e o barramento Master respeita volume geral e mudo.

O teste `tests/weapon_music.gd` cobre a abertura, a transição para o loop, a navegação e a arma. As sugestões para o restante do áudio estão em [Plano de áudio](PLANO_DE_AUDIO.md).

## Inimigo pequeno de Marte

Os arquivos `assets/mobs_marte/mob_marte1/pixil-frame-0.png`, `pixil-frame-1.png` e `pixil-frame-2.png` formam a animação `walk` do recurso `mars_frames.tres`, a 8 FPS. Os PNGs originais foram preservados. A escala é 2x, com filtro nearest, e a animação para na pausa e na loja.

O nó `MarsVisual` da cena `scenes/actors/enemy.tscn` aparece apenas para o inimigo comum de Marte. O chefe mantém a arte anterior até que seu sprite seja enviado. Os outros planetas continuam com suas identidades próprias.
