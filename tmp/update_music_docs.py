from pathlib import Path
path=Path(__file__).resolve().parents[1]/'docs/ANIMACAO_ASTRONAUTA.md'
s=path.read_text(encoding='utf-8').split('\n## Arma e música do menu')[0]
s+='''
## Arma e música do menu

A arma usa `assets/gun/gun.png` sem alterar o PNG original. Em `scenes/actors/player.tscn`, os nós `Weapon/Sprite` e `EchoWeapon/Sprite` usam um AtlasTexture com a região visível do desenho (7, 12, 10, 9), escala 2x e filtro nearest. O pivô fica na altura das mãos, acompanha a mira e passa atrás do corpo ao apontar para cima. O histórico do Eco inclui a direção da arma.

Ao abrir o jogo, o nó `MenuMusic` toca `musica/soundmenu1.mp3` uma vez. O sinal `finished` inicia `musica/SoundMenu.mp3`, com loop habilitado. Navegar entre menu, Loja, Como Jogar e Configurações mantém a reprodução sem recomeçar a faixa. Iniciar uma run interrompe a música; ao voltar ao menu, apenas o loop retorna, sem repetir a abertura. O volume próprio é -12 dB e o barramento Master respeita volume geral e mudo.

O teste `tests/weapon_music.gd` cobre a abertura, a transição para o loop, a navegação e a arma. As sugestões para o restante do áudio estão em [Plano de áudio](PLANO_DE_AUDIO.md).

## Inimigo pequeno de Marte

Os arquivos `assets/mobs_marte/mob_marte1/pixil-frame-0.png`, `pixil-frame-1.png` e `pixil-frame-2.png` formam a animação `walk` do recurso `mars_frames.tres`, a 8 FPS. Os PNGs originais foram preservados. A escala é 2x, com filtro nearest, e a animação para na pausa e na loja.

O nó `MarsVisual` da cena `scenes/actors/enemy.tscn` aparece apenas para o inimigo comum de Marte. O chefe mantém a arte anterior até que seu sprite seja enviado. Os outros planetas continuam com suas identidades próprias.
'''
path.write_text(s,encoding='utf-8')
