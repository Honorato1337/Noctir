# NOCTIR — guia de produção para 48 horas

Para personalizar cenas, layout, menu e HUD pelo editor, consulte [Editar no Godot](EDITAR_NO_GODOT.md). A interface agora usa cenas próprias e o mapa usa nós e marcadores editáveis.

## Proposta

**One More Orbit:** uma astronauta precisa reativar uma rota de extração pelo sistema solar. Cada arena abre uma janela curta de sobrevivência. Elimine a horda e o chefe de cada arena, compre na loja e avance. Na última arena de Júpiter, destrua o núcleo que bloqueia o sinal.

Partidas pretendidas de aproximadamente 8–12 minutos com as doze arenas; duração e dificuldade ainda precisam ser medidas com jogadores. A relação com **One More Time** está no reinício rápido, domínio da rota, módulos que mudam a estratégia e recordes. O rebobinador torna o tema uma ação concreta: tentar uma decisão novamente enquanto seu passado ajuda a lutar.

## Identidade própria

A referência é Journey of the Prairie King (Rei da Pradaria), de Stardew Valley. Aproveitamos a clareza de arena e horda, mas propomos mira livre, dash, eco temporal, perigos planetários e escolhas de equipamento com custos. Criem mapas, personagens, animações, áudio e interface próprios. Não reutilizem sprites, sons, mapas ou nomes do minigame.

O diferencial principal deve ser o eco. Priorizem um efeito visual claro para Q e uma situação em que o jogador perceba que pode gravar uma sequência de tiros, voltar e atacar por outro ângulo. Não vendam a mecânica como rebobinar todo o universo: apenas o traje e sua janela temporal são recuperados.

## Configurar o Godot

1. Utilizem **Godot 4.7.2 Standard**, a versão encontrada neste computador; todos da equipe devem usar a mesma versão. GDScript evita dependências de .NET e permite a rota de exportação Web desta base.
2. No Project Manager, escolham **Import**, selecionem o `project.godot` desta pasta e abram o projeto. Não criem outro projeto dentro da pasta existente.
3. Para criar uma base equivalente: projeto **2D**, renderer **Compatibility**, linguagem GDScript e controle de versão Git. Forward+ não é necessário para esta direção visual.
4. Já configurado: viewport 1152 × 720, modo de stretch `canvas_items`, filtro nearest para texturas e cena principal `scenes/main.tscn`.
5. Os comandos são registrados em `setup_inputs()` ao iniciar; por isso não aparecem previamente na lista do Input Map no arquivo. Alterem as teclas nessa função. Uma evolução possível é mover as ações para Project Settings > Input Map para edição visual.
6. Projeto > Configurações > Rendering > Renderer deve usar `gl_compatibility`. Não mudem o renderer no meio da jam sem testar os builds.
7. Apertem F5, cliquem em Iniciar Expedição e joguem a primeira arena antes de mudar qualquer coisa. F6 roda somente a cena aberta.
8. Usem o painel Debugger para acompanhar erros. As versões dos export templates e editor precisam coincidir.

`canvas_items` mantém as coordenadas lógicas e permite redimensionamento; este projeto desenha em 1152 × 720, com barras conforme o aspecto da janela. A base usa formas vetoriais desenhadas por código, não pixel art pronta. Se adotarem sprites pixelados, escolham uma resolução virtual menor (por exemplo 576 × 360) e adaptem todas as medidas e velocidades de forma consistente; não alterem só o viewport.

## Plugins e ferramentas

**Plugins obrigatórios: nenhum.** Esta base não tem dependências de addons. Os recursos nativos cobrem a entrega: AnimationPlayer/AnimatedSprite2D para animação futura, AudioStreamPlayer para sons, TileMapLayer para mapas futuros e InputMap para controles.

Não acrescentem um framework de inventário, multiplayer ou geração procedural durante a jam. Para backup, usem Git por terminal ou cliente de desktop; o plugin de Git dentro do Godot é opcional e não é exigido pelo projeto. Fechem o editor antes de resolver conflitos em arquivos de cena.

Caso decidam instalar um plugin específico: confirmem no AssetLib a compatibilidade com sua versão do Godot; baixem uma versão estável; confiram licença e instruções; instalem apenas a pasta `addons/<plugin>` necessária; depois abram Project > Project Settings > Plugins e habilitem. Alguns pacotes são apenas scripts de runtime e não têm botão Enable. Façam commit antes de instalar e testem imediatamente a exportação. Não foi instalado nem validado qualquer plugin de terceiros nesta entrega.

Fontes oficiais: [renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html), [instalar plugins](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html), [exportar para Web](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html).

## Conteúdo e expansão

| Setor | Fantasia | Mecânica implementada | Expansão sugerida |
| --- | --- | --- | --- |
| Marte | Colônia enferrujada e artrópodes minerais | Perseguição e cobertura por pilares | Poeira anunciando inimigos escavadores |
| Netuno | Plataforma boreal, coberturas congeladas e sentinelas de gelo | Estilhaços duplos, geada anunciada, lentidão e rajadas | Barreiras que bloqueiem temporariamente as rajadas |
| Júpiter | Plataforma suspensa na tempestade | Vento, investida anunciada e chefe radial | Relâmpagos com marcação no chão |

Os inimigos são criaturas e máquinas de ficção; Júpiter não tem uma superfície sólida utilizável como solo terrestre. A plataforma evita esse problema no cenário.

**Fora do protótipo:** oito planetas, coop online, dezenas de armas, geração procedural, narrativa longa e suporte a gamepad/mobile. Para 48h, terminem primeiro uma arena divertida. Os três setores agora têm quatro cenas de arena cada, com layouts próprios em `scenes/world/`. Veja o catálogo em [Arenas](ARENAS.md). Uma loja de seis melhorias permanentes também está implementada no menu; veja [Progressão permanente](PROGRESSAO_PERMANENTE.md).

Depois da jam, Mercúrio pode alternar calor e sombra; Saturno pode usar detritos dos anéis vistos de uma estação; Urano pode alterar o eixo de movimento. Terra pode funcionar como tutorial. Essas são propostas futuras, não conteúdo já pronto.

## Cronograma de 48h

| Horas | Entrega verificável |
| --- | --- |
| 0–4 | Importar, jogar, definir responsáveis, confirmar regras e cortar escopo |
| 4–12 | Ajustar tiro, velocidade, dash e eco; primeira arena divertida; primeiro export |
| 12–22 | Astronauta e três inimigos com animações simples; substituir desenhos provisórios |
| 22–30 | Paletas, perigos legíveis, chefe com aviso visual e efeitos do eco |
| 30–36 | Sons de tiro/acerto/dash/Q e uma faixa curta; ajustar volumes |
| 36–42 | Teste com pessoas que não conhecem os controles; balancear vida e tempo |
| 42–46 | Corrigir bloqueios, testar Windows/Web, screenshot e texto da página |
| 46–48 | Congelar conteúdo, enviar build, verificar download e guardar margem para falhas |

Com três pessoas: programação cuida de combate e builds; arte cuida de astronauta/inimigos/mapas; design/áudio cuida de balanceamento, som e página. Com duas: uma em programação e outra em arte, áudio e testes. Façam commits pequenos, comuniquem qual cena cada um está editando e evitem duas pessoas alterando a mesma `.tscn`.

## Ajustes que mais valem o tempo

1. Tornar o eco imediatamente compreensível: cor ciano exclusiva, rastro e som curto. Não depender só de texto.
2. Medir quantas vezes jogadores usam Q; se esquecem, exibir dica após perder vida pela primeira vez.
3. Se o cronômetro estiver punindo demais, aumentá-lo em `start_room()`, antes de diminuir a quantidade de inimigos. Procurar uma partida que ensine o eco sem exigir uso perfeito.
4. Adicionar sons e impacto de tiro antes de novos planetas. O protótipo atual é silencioso.
5. Testar os caminhos em novos layouts. Os inimigos agora contornam pilares com AStarGrid2D, reconstruída ao carregar cada arena; mantenham corredores largos para o chefe.
6. Evoluir módulos em itens visuais coletáveis se houver tempo. Nesta base os módulos são comprados na loja entre arenas; consumíveis raros já caem no chão.

## Exportação e entrega

Em Editor > Manage Export Templates, instalem templates da mesma versão do editor. Em Project > Export > Add, criem **Windows Desktop** e **Web**. Os presets não vêm pré-gerados, porque o ambiente de exportação e assinatura precisa ser configurado pelo time.

Windows: exportem para `builds/windows/Noctir.exe`, copiem também o `.pck` se separado, iniciem o executável fora do editor e testem uma partida. Web: mantenham Compatibility, Thread Support desabilitado e exportem para `builds/web/index.html`. Compactem todos os arquivos gerados juntos. Publiquem como jogo HTML na plataforma da jam e testem a URL; abrir o arquivo HTML localmente não equivale a servir o jogo por HTTP. Verifiquem o recorde no navegador, pois persistência pode depender de permissões do navegador.

Checklist de jogo: controles, pausa, recomeço, dano, upgrade, portal, cronômetro, eco, fase 2 do chefe e vitória. Testem se dá para vencer sem bugs, depois testem perder. Testem a janela em tela menor e a leitura de avisos de geada/investida. O teste automatizado não mede diversão nem garante compatibilidade de um build exportado.

## Referência do tema e inscrição

Baseado no PDF `[PT] GJ+ 26_27 - Temas.docx.pdf`, especialmente a página 2. O tema permite progressão, combinações e recordes, sem exigir um mundo gigante. A página 1 informa que pelo menos um tema deve ser escolhido e que projetos iniciados antes do fim de semana da jam não serão aceitos. O arquivo não esclarece o horário exato de início, uso de IA, código externo nem todas as condições de inscrição. Confirmem isso nas regras oficiais do evento e descrevam a origem de código/arte conforme exigido. Não há multiplayer nesta proposta e não é necessário adotar os outros temas.


A versão atual tem hordas ampliadas, um chefe por arena, moedas, dois slots de consumíveis e uma loja. Consulte [Combate e loja](COMBATE_E_LOJA.md) para as regras e os números atuais; a duração prevista no cronograma original precisa ser reavaliada com esse escopo.
