# Configurações e controles

## Áudio

Configurações > Áudio tem volume geral, músicas (menu e planetas), efeitos (arma, combate, clima e habilidades) e interface (cliques, compras e erros). Cada canal é independente e recebe o volume geral. Mudo silencia tudo. Testar efeitos usa o canal de efeitos.

## Vídeo no computador

Janelas disponíveis: 960×600, 1152×720, 1280×720, 1600×900 e 1920×1080; tela cheia usa o monitor. A imagem mantém sua proporção, com barras quando necessário. Janelas grandes são limitadas à área útil do monitor. No celular a orientação é paisagem e o tamanho se adapta automaticamente; no navegador o tamanho é gerenciado pela página.

## Teclado

O preset padrão move com WASD e permite tiro com setas ou mouse. O segundo move com setas e usa WASD para tiro; mouse continua disponível. Os botões da lista permitem remapear cada ação: clique, pressione a nova tecla, Esc cancela. Se a tecla já estiver usada, as duas ações trocam de tecla. Selecionar um preset limpa remapeamentos individuais e restaura os padrões daquele preset. As dicas da HUD acompanham as teclas configuradas.

## Joystick

- Analógico esquerdo: movimento; direito: mira e disparo automático. Zona morta de 22%.
- RT: atirar na direção atual; LT: Berserk.
- A: dash; LB: Eco; X: extrair.
- Y e B: consumíveis; RB: equipamento de chão; Start: pausa.
- Menus: direcional ou analógico esquerdo navega, A confirma, B volta onde disponível; LB/RB mudam foco.

Os nomes seguem o layout Xbox reconhecido pelo Godot; controles PlayStation usam os botões equivalentes. Desconectar um controle usado pausa a run. A mira permanece na última direção ao soltar o analógico.

## Celular e toque

Detecção automática de tela de toque, com opção de forçar ou desligar os controles. Direcional esquerdo move, direito mira e atira; os dois podem ser usados simultaneamente. Botões de dash (com recarga), Eco, Berserk, extração, pausa e três slots ficam na tela. Menus funcionam por toque. A HUD se adapta para evitar sobreposição. Perda de foco do aplicativo pausa a run; dedos e ações são liberados ao abrir menus.

O projeto contém os controles e ajustes de janela/orientação. Este trabalho não gera APK ou pacote iOS: exportação nativa ainda exige templates do Godot e SDK da plataforma, além de teste em aparelhos reais. Não foram instalados SDKs nem plugins adicionais.

## Persistência e testes

As preferências ficam em user://settings.cfg. Saves antigos continuam válidos, mantendo o volume geral e o tempo jogado. Os novos canais começam em 100%, preservando a mixagem anterior.

Testes de integração usam eventos reais do sistema de entrada do Godot (teclado, eventos de joystick e multitouch simulados), verificam buses, persistência, remapeamento, menu, movimento, tiro, dash e pausa. A resolução foi verificada na janela do Windows. Validação com joystick físico e celular continua necessária.

## Ajuste de proporção — 0.1.5

A base de layout é 1152×720. O canvas usa aspecto expand: em 1920×1080 a área lógica aumenta para 1280×720, preenchendo a janela sem letterbox e sem distorcer os sprites. A HUD mantém suas posições relativas à área central de 1152×720; flashes de dano e extração cobrem toda a janela. Menus, fundos e controles de toque acompanham a área visível. tests/neptune_fullhd.gd verifica Full HD e a centralização após trocar a resolução.

## Perfil de desempenho do celular (0.3.0)

Ativado automaticamente no Android, independentemente da opção de controles por toque. O computador mantém os limites completos.

| Recurso | Computador | Celular |
| --- | --- | --- |
| Inimigos simultâneos | 80 | 32 |
| Tamanho das hordas | 100% | 65%, arredondado para cima |
| Partículas de combate | 1800 | 300, com emissão reduzida a 25% |
| Partículas ambientais | 180 | 40 |
| Impactos meteorológicos | 48 | 18 |
| Campos de chefes/mobs | 96 / 24 | 32 / 8 |
| Limite de tiros hostis / total com tiros aliados | 480 / 900 | 180 / 240 |
| Textos de dano simultâneos | 100 | 20 |

O celular renderiza em viewport interno, usando a base lógica 1152×720 e o ajuste de proporção existente, em vez de desenhar toda a cena na resolução física da tela. Avisos de ataque e marcas de perigo permanecem. Navegação e separação entre inimigos são recalculadas em intervalos de 0,2s e 0,12s; colisões continuam sendo verificadas a cada movimento. As transformações visuais são atualizadas em até 30 Hz no celular.

O APK exclui a faixa de prévia e os MP3 originais de menu não usados na partida; os WAV processados e os originais no projeto são preservados. As otimizações foram verificadas em teste do perfil mobile no computador; FPS e consumo precisam ser medidos em um aparelho real.
