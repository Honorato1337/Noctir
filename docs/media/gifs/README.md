# Mecânicas em movimento

[Voltar ao jogo](../../../README.md) · [Baixar todos os GIFs em ZIP](../one-more-orbit-gifs.zip)

Oito GIFs em **640×360**, **20 FPS**, loop infinito e sem áudio. Capturados no Godot, com o astronauta e a câmera em uma área isolada para destacar as mecânicas. As legendas fazem parte da captura. Os frames foram codificados com paleta compartilhada e sem dithering para preservar a pixel art.

A arma equipada na versão atual é a espingarda. Prisma e Berserk são variações de disparo, não armas separadas. O último GIF mostra o asset da arma original e o tiro simples antigo somente como demonstração; não há seletor dessa arma na versão atual.

## MOVIMENTO

Astronauta andando.

![Astronauta andando](01-andando.gif)

## ESPINGARDA

3 projéteis por tiro.

![3 projéteis por tiro](02-espingarda.gif)

## MOVER + ATIRAR

Movimento e disparos simultâneos.

![Movimento e disparos simultâneos](03-andando-atirando.gif)

## PRISMA

Espingarda com +2 projéteis.

![Espingarda com +2 projéteis](04-prisma.gif)

## DASH

Investida com invulnerabilidade.

![Investida com invulnerabilidade](05-dash.gif)

## ECO TEMPORAL

Rebobina e repete os disparos.

![Rebobina e repete os disparos](06-eco.gif)

## BERSERK

Rajadas em todas as direções.

![Rajadas em todas as direções](07-berserk.gif)

## ARMA ORIGINAL

Demonstração do asset antigo.

![Demonstração do asset antigo](08-arma-original.gif)

## Reproduzir as capturas

```powershell
godot --fixed-fps 20 --path . --script tools/capture_mechanics.gd
python tools/package_mechanics.py
```

Os PNGs intermediários ficam em `tmp/mechanics-frames`, fora do Git. O manifesto inclui duração, tamanho e hash SHA-256 dos GIFs. O ZIP contém os oito GIFs, o manifesto e este guia. Nenhuma mudança no sistema de armas é necessária para gravá-los.
