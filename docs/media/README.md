# Galeria e fundo de Júpiter

Sete capturas em PNG, 1920×1080: menu, Marte, Netuno, Júpiter, sobrevivência, loja e controles por toque. Imagens capturadas no próprio Godot com a arte e a HUD atuais, sem montagem posterior. As cenas são preparadas para demonstração, com semente fixa e proteção do personagem durante a captura. O progresso salvo não é alterado.

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
