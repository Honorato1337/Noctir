# Direção de arte: criaturas e terrenos

## O que foi integrado

A direção usa os contornos escuros, a iluminação em blocos e a expressividade de criaturas como referência de acabamento de [Momodora: Moonlit Farewell](https://playism.com/en/game/momodora-moonlit-farewell/). O jogo continua com câmera de cima; os personagens, os ambientes e os sprites desta base são novos.

| Planeta | Criatura comum | Chefe | Terreno e barreiras |
| --- | --- | --- | --- |
| Marte | Ferrugóide, um ser de sucata espacial com olhos âmbar e pequenas garras | Devorador de Sucata, uma massa de placas oxidadas e detritos | Solo vermelho de regolito e rochedos de basalto ferruginoso |
| Vênus | Lesma Sulfúrica, com olhos em pedúnculos, língua e crosta de enxofre | Matriarca Sulfúrica, com bolsas ácidas e carapaça mineral | Terra vulcânica oliva e afloramentos de basalto com enxofre |
| Júpiter | Arraia da Tempestade, com nadadeiras rasgadas, couraça violeta e olhos ciano | Soberana do Ciclone, uma arraia maior de três olhos | Crosta mineral violeta e rochedos cristalinos flutuantes sobre as nuvens |

As ideias de monstro de lixo e de lesma vêm das referências indicadas pelo time (Garbagemon e Numemon), com desenhos próprios. O terreno de Júpiter é uma licença de ficção científica, uma formação flutuante, e não uma representação de superfície sólida do planeta.

O astronauta agora tem sprites de frente, costas, esquerda e direita. A direção acompanha a mira. O eco usa esses sprites tingidos de ciano. Os inimigos espelham a orientação e têm um movimento leve de flutuação/respiração. Isso ainda não é uma sequência completa de frames de caminhada e ataque.

## Arquivos de arte

Os quatro atlas foram gerados com a ferramenta **image_gen.imagegen integrada**, depois copiados para o projeto. Os PNGs originais foram preservados, incluindo transparência; não dependem de arquivos na pasta global do Codex.

- `assets/art/planet_atlases/mars_kit.png`
- `assets/art/planet_atlases/venus_kit.png`
- `assets/art/planet_atlases/jupiter_kit.png`
- `assets/art/planet_atlases/astronaut_kit.png`

O conjunto exato de prompts está em [GENERATION_PROMPTS.json](../assets/art/GENERATION_PROMPTS.json). Os três atlas de planeta têm quatro quadrantes: terreno, criatura comum, rocha e chefe. O atlas do astronauta contém quatro direções. Cada PNG tem 1254 × 1254 pixels, com margens e recortes definidos nos recursos `AtlasTexture` de `assets/art/regions`.

## Como o Godot exibe os assets

- `scripts/planet_art.gd`: catálogo dos atlas por planeta e direção do astronauta.
- `scenes/actors/enemy.tscn > Visual`: Sprite2D das criaturas; o controlador escolhe a arte por planeta e se é um chefe.
- `scenes/actors/player.tscn > Visual` e `EchoVisual`: astronauta e eco.
- `scripts/terrain_art.gd`: preenche o piso com textura de terreno, sem linhas de grade industrial.
- `scripts/pixel_cover.gd`: cobre os retângulos das barreiras com conjuntos de rochas do planeta. A posição e as dimensões continuam editáveis nas cenas das arenas.
- `assets/art/pixel_sampling.gdshader`: amostra os atlas em uma grade de pixels, com alpha recortado e sem suavização.
- `assets/art/ground_material.tres`: reduz o contraste da textura de chão para destacar os inimigos, as moedas e os tiros.

Os inimigos comuns usam um quadro visual de 80 px, o chefe de 110 px e o astronauta de 74 px. A margem transparente faz com que o corpo ocupe parte desse quadro. As colisões continuam com os raios da jogabilidade. As barreiras usam retângulos para colisão; o desenho das rochas é irregular e tem pequenas saliências decorativas.

## Editar ou substituir

Para trocar uma criatura, substitua o recurso correspondente em `assets/art/regions` ou atualize o catálogo `planet_art.gd`. Para usar um personagem completamente diferente, desative **Use Planet Sprites** na raiz da cena e adicione seu próprio Sprite2D/AnimatedSprite2D como filho. Os sprites do catálogo são escolhidos durante a partida, portanto mudar somente a prévia do campo Texture não troca o catálogo.

Para mover rochas, abra a arena e altere os nós dentro de `Obstacles`, mantendo-os sem rotação e escala 1. A colisão e a navegação acompanham seus retângulos; o script distribui os agrupamentos de pedras nesses espaços. `Sector Index` controla a prévia do planeta no editor. Ao jogar, o setor da fase define o planeta.

Para ajustar o contraste do chão, edite `flatten_strength` em `ground_material.tres`. Para ajustar o tamanho visual do pixel, edite `source_pixel_step` nos materiais. Os PNGs não precisam ser alterados para esses ajustes.

## Prévia e validação

As imagens `docs/preview-mars-art.png`, `preview-venus-art.png` e `preview-jupiter-art.png` mostram cada bioma. `preview-biomes.png` coloca os três lado a lado. `preview-arena.png` mostra o cenário em combate com uma horda e efeitos.

Os testes de jogo continuam percorrendo as 12 fases, as colisões, a loja, o inventário e os chefes. Também verificam as direções do astronauta e a seleção de sprites por planeta. O teste de densidade foi repetido com os novos atores. Ainda vale conferir a legibilidade em monitores menores e durante partidas humanas.
