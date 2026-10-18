# Galeria e fundo de Júpiter

Onze capturas em PNG, 1920×1080: menu, Marte, Netuno, Júpiter, sobrevivência, loja e controles por toque, além de caos no combate e extração urgente. Imagens capturadas no próprio Godot com a arte e a HUD atuais, sem montagem posterior. As cenas são preparadas para demonstração, com semente fixa e proteção do personagem durante a captura. O progresso salvo não é alterado.

## Fundo

- [jupiter-fundo.png](jupiter-fundo.png): 1536×896, chão completo, sem paredes, personagens ou interface. Exportado pelo mesmo renderizador de terreno usado no jogo, incluindo orientação dos tiles e tonalidade.
- [jupiter-tile.png](jupiter-tile.png): 32×32, tile lógico de Júpiter, na paleta do jogo, antes do escurecimento aplicado ao desenhar. No cenário é ampliado para 64×64 com filtro nearest.
- Fonte compartilhada dos pisos: `assets/environment/floor_tiles-v3.png`. O atlas contém todos os planetas; estes PNGs são exportações separadas para facilitar o uso.

## Reproduzir

Com Godot 4.7.2 e uma superfície gráfica disponível:

```powershell
Godot --path . --script tools/capture_repository.gd
```

O script exporta o fundo, o tile e as seis capturas de computador. A sétima imagem usa a mesma cena de Marte com controles por toque; para refazê-la, defina temporariamente `game.preferences.touch_mode = 1` no script e salve a captura de Marte como `07-controles-mobile.png`. O valor normal é 2 (toque desativado para a galeria de computador).

## Pedras de Júpiter

[jupiter-rochas.zip](jupiter-rochas.zip) reúne dois sprites de pedra, um trecho de parede e uma prévia ampliada. Todos os PNGs têm transparência; os sprites mantêm o recorte e a paleta que o jogo aplica ao atlas, sem redesenho.

## Capturas de caos e urgência

- `08-caos-total.png`: mais de 70 inimigos, Deus Alienígena, Berserk, campo da baliza e vida baixa.
- `09-extracao-urgente.png`: contagem de 3 segundos, alerta vermelho, foguete e loot abandonado.

Para reproduzir essas imagens e a exportação das pedras:

```powershell
Godot --path . --script tools/capture_chaos.gd
```

São cenas de demonstração preparadas dentro do jogo, com proteção temporária do personagem, sem montagem posterior e sem alterar o save ou o balanceamento do jogo.

## Plutão (0.2.0)

`10-plutao.png`: Planície do Exílio, cenário exclusivo da Sobrevivência, com rochas congeladas e gêiseres de nitrogênio. É a imagem atual do modo na galeria; `05-sobrevivencia.png` registra o cenário anterior.

## Leviatã Boreal (0.2.2)

`11-leviata-boreal.png` mostra o superchefe de Netuno com os três frames originais de `mob_netuno3`. Para refazer: `Godot --path . --script tools/capture_neptune_super.gd`.
