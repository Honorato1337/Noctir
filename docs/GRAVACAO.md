# Gravação da arena final

O cursor do computador usa `assets/ui/Mira.png`, original do autor, ampliado de 16×16 para 32×32 com filtro nearest e ponto ativo no centro. Na gravação, uma única instância usa o shader de cores negativas, evitando duplicar a inversão do cursor.

A demonstração dura 30 segundos e é controlada por script na arena 13. O perfil é temporário: atributos e módulos elevados, as duas armas, habilidades, consumíveis e equipamentos liberados. A horda foi estendida e o chefe recebeu mais vida para manter o combate. Dano, morte e chances permanecem ativos. O save do jogador não é alterado.

```powershell
godot --path . --fixed-fps 30 --write-movie builds/media/OneMoreOrbit-Nexo-30s.avi --script tools/record_showcase.gd
```

Crie `builds/media` antes de iniciar a captura. O Movie Maker grava na resolução nativa 1152×720, a 30 FPS, com áudio. O relatório em `builds/media/showcase-report.json` registra recursos usados, dano recebido e mortes. O MP4 fica em `builds/media/OneMoreOrbit-Nexo-30s.mp4`; vídeos e intermediários não são versionados no Git. O MP4, o relatório e o ZIP das prints são anexados à release 0.3.3.

A gravação 0.3.3 tem 900 quadros, 30 segundos e áudio AAC com vídeo H.264. O trecho registra 23 pontos de dano real, uma continuação após morte, 151 abates e combate com até 80 inimigos. Foram ativados Eco, Berserk, bomba, escudo, sobrecarga, mina, torreta e baliza, além das duas armas. O kit foi oferecido, mas não consumido com a vida cheia. A nova HUD aparece durante a demonstração.
