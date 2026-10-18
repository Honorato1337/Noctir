# Gravação da arena final

O cursor do computador usa `assets/ui/Mira.png`, original do autor, ampliado de 16×16 para 32×32 com filtro nearest e ponto ativo no centro. A imagem é desenhada também na gravação, pois o cursor nativo do sistema não entra no Movie Maker.

A demonstração dura 30 segundos e é controlada por script na arena 13. O perfil é temporário: atributos e módulos elevados, as duas armas, habilidades, consumíveis e equipamentos liberados. A horda foi estendida e o chefe recebeu mais vida para manter o combate. Dano, morte e chances permanecem ativos. O save do jogador não é alterado.

```powershell
godot --path . --fixed-fps 30 --write-movie tmp/one-more-orbit-final-30s.avi --script tools/record_showcase.gd
```

O Movie Maker grava na resolução nativa 1152×720, a 30 FPS, com áudio. O relatório em `tmp/showcase-report.json` registra recursos usados, dano recebido e mortes. O MP4 entregue fica em `builds/media/OneMoreOrbit-Nexo-30s.mp4`; vídeos e intermediários não são versionados no Git.

A gravação entregue tem 900 quadros, 30 segundos e áudio AAC com vídeo H.264. O trecho contém dano real, uma continuação após morte e combate com até 80 inimigos.
