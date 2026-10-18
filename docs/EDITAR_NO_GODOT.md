# Editar cenas e layout no Godot

Importe **o project.godot da raiz Noctir**, que fica ao lado de `README.md`, `scripts` e `scenes`. Existe também um `docs/project.godot` nesta pasta de trabalho; ele não é o projeto do jogo, pois seus caminhos relativos não apontam para essas cenas. O arquivo foi preservado. Se o editor estiver com `docs` como raiz `res://`, volte ao Project Manager e importe o arquivo correto.

## Onde editar

| O que mudar | Cena/recurso |
| --- | --- |
| Menu principal | `scenes/ui/main_menu.tscn` |
| Instruções de controles | `scenes/ui/controls.tscn` |
| Vida, tempo, pontos e avisos | `scenes/ui/hud.tscn` |
| Tela de pausa | `scenes/ui/pause_menu.tscn` |
| Loja, módulos e consumíveis | `scenes/ui/shop_screen.tscn` |
| Loja de melhorias permanentes do menu | `scenes/ui/permanent_shop.tscn` |
| Configurações de volume | `scenes/ui/settings_menu.tscn` |
| Vitória e derrota | `scenes/ui/result_screen.tscn` |
| Piso, pilares, spawns, portal | `scenes/world/*.tscn` (12 cenas) |
| Astronauta, inimigo e tiro | `scenes/actors/*.tscn` |
| Cores e estilos de toda a UI | `ui_theme.tres` |
| Composição geral | `scenes/main.tscn` |

Esses arquivos já estão conectados ao jogo. F5 executa a experiência completa. F6 em uma tela isolada serve para conferir o layout; os botões são ligados pelo controlador ao executar o jogo completo e não navegam sozinhos em F6.

Se o jogo estiver animando, mas os botões e o teclado não responderem na janela de execução do editor, confira o botão **Entrada** na barra superior dessa janela. Ele precisa estar ativado para **permitir envio de entradas para o jogo**. Com essa opção desligada, o Godot bloqueia os comandos antes que cheguem aos scripts.

## Mudar o menu principal

1. No painel FileSystem, abra `scenes/ui/main_menu.tscn` com dois cliques e selecione a aba **2D**.
2. A árvore principal é `MainMenu > Center > Layout`. Em `Content > Mission > Box` estão `Title`, `Description`, `StartButton`, `PermanentShopButton` e `MenuActions`, que contém `SettingsButton` e `ControlsButton`. Em `Content > Astronaut > Box` ficam a prévia animada, o `Record` e as dicas. `Eyebrow` recebe data, hora e tempo jogado em runtime. `Route` contém os três cartões dos planetas; sua visibilidade pode ser ajustada no editor.
3. Selecione `Title` e altere **Text** no Inspector. Para o tamanho, use **Theme Overrides > Font Sizes > Font Size**. Cor por nó: **Theme Overrides > Colors**.
4. Para mudar a largura dos painéis, selecione `Mission` ou `Astronaut` e altere **Layout > Custom Minimum Size > X**. A posição central vem do `CenterContainer`; a largura geral mínima fica em `Layout`.
5. Para espaçamento entre elementos, selecione `Box` e ajuste **Theme Overrides > Constants > Separation**.
6. A altura dos botões vem de **Layout > Custom Minimum Size > Y**. O container controla sua posição; arrastar um filho de `VBoxContainer` não define a posição final. Para mudar a ordem, reordene os nós na árvore.
7. Troque o fundo pela cor de `Backdrop`, ou adicione um `TextureRect` abaixo dele na ordem visual apropriada, com seu asset no campo Texture. Use **Mouse > Filter = Ignore** nos elementos decorativos para não bloquear os botões.
8. Salve com Ctrl+S e use F5. Não renomeie os nós funcionais `StartButton` e `ControlsButton` sem atualizar suas referências no script.

O título e os textos estáticos vêm da cena. Os números do HUD, os três módulos sorteados e o resumo do resultado são atualizados em runtime; seus textos provisórios no editor servem para visualizar o espaço ocupado.

Na loja, `Modules` contém os botões `Choice1`, `Choice2` e `Choice3`. Dentro deles, as Labels `ModuleTitle`, `ModuleDesc` e `ModuleCost`, com sufixos 1–3, recebem os dados sorteados. A linha `Inventory` exibe os slots pretos `StoreSlot1` e `StoreSlot2`, com os mesmos ícones da HUD. Preserve os nomes desses nós ao editar. Os cartões de módulos usam Labels com Mouse Filter Ignore para permitir clicar no botão inteiro.

O resultado mostra `ScoreValue`, `BestValue`, `KillsValue`, `ArenaValue` e `TimeValue` separadamente. O controlador preenche esses campos e escolhe automaticamente o primeiro botão de cada tela para navegação por teclado. A variação `PrimaryButton` do tema define os botões verdes de ação principal.

`RewardValue` mostra os coins recebidos e a sobra de pontos. `PermanentShopButton`, no menu e no resultado, abre a loja de bônus para as próximas runs. O catálogo e o salvamento ficam em `scripts/progression.gd`. Veja [Progressão permanente](PROGRESSAO_PERMANENTE.md) para ajustar a conversão, os preços e os limites.

## Cores, fontes e estilo compartilhado

Abra `ui_theme.tres`. O recurso Theme define Label, Button e PanelContainer e já usa W95FA. O título principal tem um override com After Burner Neue. A HUD foi reduzida a uma faixa de 72 px; as fontes e os espaçamentos são editáveis nas cenas. Modifique os StyleBoxFlat de `Button > Styles > Normal/Hover/Pressed/Focus` e `PanelContainer > Styles > Panel` para trocar fundo, borda, cantos e margens. Todas as telas herdam esse tema.

Para uma fonte própria, importe um `.ttf`/`.otf` e atribua ao **Default Font** do tema. Respeite a licença do arquivo. Overrides locais de uma Label têm prioridade sobre o tema; remova o override se quiser que ela siga o padrão global.

## Mudar o HUD

Abra `scenes/ui/hud.tscn`. Selecione e arraste as Labels no editor 2D: `Timer`, `Echo`, `Score`, `Coins` e `Counters`. Todos os textos da HUD usam 22 px. O nó `Health` é um Control com `scripts/heart_meter.gd`, que desenha os corações em pixel art, os espaços vazios, o flash ao sofrer dano e o alerta de vida baixa. O medidor ajusta as fileiras para comportar as melhorias de vida, incluindo os 20 corações possíveis. Diferentemente do menu, esses nós têm posições livres para facilitar sua composição.

Mantenha os nomes e a opção **Access as Unique Name** dos nós dinâmicos (ícone `%`), pois `scripts/hud.gd` usa essas referências. Não coloque painéis opacos por cima da área de combate sem conferir a visibilidade. Labels e decoração usam Mouse Filter Ignore para permitir mirar e atirar.

## Relógio, tempo total e volume

A data e a hora vêm do relógio local do sistema e são atualizadas a cada segundo no menu. `JOGADO` acumula tempo em combate e durante a caminhada para extração; menus, loja e pausa não contam. O contador é salvo a cada 30 segundos de jogo e ao encerrar a run ou fechar normalmente a janela. A contagem começa com esta versão, sem estimar durações de partidas antigas.

`scripts/user_settings.gd` guarda volume geral, mudo e tempo acumulado em `user://settings.cfg`, separado do save de progressão permanente. O volume controla o barramento **Master** do Godot; músicas e efeitos que passarem por ele respeitam o ajuste. O botão **Testar Som** gera um tom curto para conferir o volume, mesmo antes de adicionar músicas ao projeto.

Em `scenes/ui/settings_menu.tscn`, preserve `VolumeSlider`, `VolumeValue`, `MuteButton`, `TestSoundButton`, `SettingsNotice`, `PreviewSound` e `BackButton`. O tema do slider fica em `ui_theme.tres`, e o puxador pixelado em `assets/icons/slider_handle.svg`. Ajustes são aplicados imediatamente e gravados após uma pausa curta na alteração do volume; voltar ao menu também força a gravação.

## Mudar a arena

Abra uma das doze cenas em `scenes/world/`. Cada fase tem seu layout próprio; `arena.tscn` é apenas a primeira. A sequência fica no campo Arena Scenes da raiz de main.tscn. Consulte o [catálogo de arenas](ARENAS.md). Paleta, inimigos e perigos continuam definidos pelo planeta, com quatro fases por setor.

- **Floor:** posição e Size delimitam a arena. A borda acompanha esses limites quando a partida começa.
- **Obstacles/PillarA e PillarB:** arraste e redimensione os ColorRects no editor 2D. O jogo lê os retângulos para gerar a colisão. Para criar outra cobertura, duplique um desses nós dentro de `Obstacles`.
- **PlayerSpawn:** posição inicial do astronauta.
- **Portal:** destino da extração e da seta. Mantenha dentro de Floor e fora das coberturas.
- **BossSpawn:** posição inicial do chefe.
- **SpawnGates:** mova os Marker2D para os locais de entrada dos inimigos. Mantenha ao menos um marcador, dentro da arena e fora dos obstáculos.
- **Hazards:** posição dos centros das zonas de geada de Netuno; o raio ainda é 54 no código. Esses marcadores não desenham uma nuvem fora do jogo.

A paleta dos planetas substitui as cores de Floor e dos pilares ao começar a arena. Para mudar a cor definitiva de cada planeta, edite `scripts/planets.gd`. Mantenha os nomes dos grupos e dos marcadores principais. Evite rotacionar ou escalar a arena e os ColorRects: a colisão usa retângulos alinhados aos eixos.

## Adicionar sprites ao personagem

O astronauta já usa os cinco frames criados pelo time. Abra `scenes/actors/player.tscn`, selecione **Visual** (AnimatedSprite2D) e abra o recurso **Sprite Frames** para editar idle, walk e o FPS. O recurso está em `asssets/astronauta/astronaut_frames.tres`. A escala é 2x, com filtro nearest; os PNGs originais foram preservados.

O nó **EchoVisual** exibe os frames gravados pelo rebobinador. Para voltar ao astronauta geométrico, habilite **Use Placeholder Graphics** na raiz. As cenas de inimigos continuam com o desenho por código e podem receber seus próprios Sprite2D/AnimatedSprite2D. Veja [Animação do astronauta](ANIMACAO_ASTRONAUTA.md).

O inimigo pequeno de Marte já usa `MarsVisual`, um AnimatedSprite2D em `scenes/actors/enemy.tscn`, com os três frames de `assets/mobs_marte/mob_marte1` a 8 FPS e escala 2x. O controlador o mostra apenas em inimigos comuns de Marte. O chefe mantém a arte atual e os inimigos dos outros planetas continuam com seu desenho próprio.

O indicador de recarga fica em `DashCard`, com `DashStatus` e `DashCooldown`, em `scenes/ui/hud.tscn`. Os valores acompanham a recarga real, incluindo as melhorias do propulsor. A câmera fica em `scenes/main.tscn`; sua suavização é editável no Inspector, e seus limites são atualizados pelo controlador em cada arena.

Na raiz de player.tscn, **Speed**, **Damage**, **Interval**, **Max Health** e **Dash Recharge** ficam no Inspector. O balanceamento de inimigos e projéteis pode ser substituído pelo controlador de acordo com planeta, chefe e upgrades.

## Instâncias e cenas

`main.tscn` instancia a arena, o HUD e uma prévia do menu; o controlador troca a tela exibida em `UI/ScreenHost`. Abra a cena original pelo FileSystem ou por **Open in Editor** na instância para modificar sua fonte. O menu é reinstanciado durante a navegação; overrides feitos apenas na prévia dentro de main.tscn não são o lugar para personalizar sua versão definitiva.

Use F5 após salvar. Verifique pausa, Como Jogar, escolha de módulo e retorno ao menu. Não é necessário instalar plugin para editar qualquer um desses layouts.


O sistema de compra e a escolha gratuita foram separados: a tela usada entre fases agora é `shop_screen.tscn`. O arquivo antigo `upgrade_screen.tscn` foi preservado como referência, mas não é exibido no fluxo atual. Veja [Combate e loja](COMBATE_E_LOJA.md) para ajustar preços, drops, slots e chefes.


Os slots ficam em `SlotOne` e `SlotTwo`: são ColorRects pretos de 64 × 64 px. Seus filhos `SlotOneIcon` e `SlotTwoIcon` são TextureRects atualizados conforme o inventário. As teclas 1 e 2 aparecem nos filhos `Key`. Os ícones estão em `assets/icons`; o catálogo `ICONS` de `scripts/loot_system.gd` é usado tanto para os drops quanto para a HUD. Não renomeie os nós marcados com `%` sem atualizar o script da HUD.
