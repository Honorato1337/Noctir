# Continuar One More Orbit em outro computador

Estado registrado em 18/10/2026. Repositório: https://github.com/Honorato1337/Noctir.

## Começar no novo PC

1. Instale Git e Godot **4.7.2 Standard**, com GDScript e renderizador Compatibility.
2. Execute `git clone https://github.com/Honorato1337/Noctir.git`. Se já tiver uma cópia limpa, atualize com `git pull --ff-only`.
3. Importe o `project.godot` da raiz no Godot. Aguarde a importação de recursos e pressione F5.
4. Abra essa pasta como projeto no Codex. Os caminhos do computador antigo não precisam ser reproduzidos.

Não são necessários plugins para executar o projeto. A pasta `.godot` é recriada pelo editor.

## Estado do jogo e das versões

- Nome: **One More Orbit**; o nome do repositório continua Noctir.
- Campanha de 13 arenas: Marte, Netuno, Júpiter e Nexo. Sobrevivência infinita em Plutão.
- Arma original gratuita e espingarda comprável por SpaceCoin; dois slots de consumíveis e um exclusivo de equipamento de chão.
- Eco, dash, Berserk, contratos, melhorias permanentes, Prestígio e skins.
- Quinze segundos para coletar e extrair; perder o prazo remove os itens e um terço das moedas. Loja da campanha com vinte segundos; sobrevivência com dez.
- Chefes de Júpiter usam as artes `mob_jupiter2` e `mob_jupiter3`. O menu tem Sair e as descrições de equipamento aparecem em caixas.
- Windows atual: **0.3.2**, com as otimizações da 0.3.1 e dano de 1000× no modo Teste, exclusivo de desenvolvedor. O dano normal não recebe esse multiplicador.
- Android disponível: **0.3.0**. O código atual contém otimizações adicionais para o perfil móvel; um novo APK ainda não foi exportado. Não houve teste em aparelho nesta etapa. O autor suspeita que o encerramento relatado era do próprio celular; não há diagnóstico confirmado por log.
- A página do itch.io foi trabalhada como rascunho, conforme pedido. Verifique o painel da conta antes de qualquer publicação; o estado do site não faz parte do Git.

## Principais arquivos

| Área | Arquivos |
| --- | --- |
| Fluxo da partida, menu, loja e exportação de resultados | `scripts/game.gd` |
| Jogador, arma e dano | `scripts/player.gd` |
| Inimigos e comportamento dos chefes | `scripts/enemy.gd`, `scenes/actors/enemy.tscn` |
| Tiros e busca espacial | `scripts/projectile.gd`, `scripts/game.gd` |
| Partículas e clima | `scripts/combat_fx.gd`, `scripts/arena_weather.gd` |
| Cenas editáveis | `scenes/ui/`, `scenes/world/` |
| Artes autorais | `assets/`, `asssets/astronauta/` |
| Texturas pequenas preparadas | `assets/optimized/`, `tools/bake_runtime_art.gd` |
| Limites e verificações de desempenho | `docs/PERFORMANCE.md` |
| Exportação e assinatura | `docs/EXPORTACAO.md`, `export_presets.cfg` |

## Preferências para futuras alterações

- Manter a arte autoral e a aparência pixelada. Animações podem transformar os sprites existentes; não redesenhar os personagens sem pedido.
- After Burner Neue somente nos títulos; w95fa nas interfaces.
- Combate intenso com hordas e efeitos, preservando a leitura dos ataques e os limites de desempenho.
- A área Teste é de desenvolvedor. Evitar validar em celular sem um novo pedido explícito.
- Descrever claramente qual versão está no EXE, no APK e no código-fonte.

## Verificações úteis no computador

```powershell
godot --headless --path . --script res://tests/performance_budget.gd
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --script res://tests/safe_collection.gd
godot --headless --path . --script res://tests/jupiter_boss_art.gd
godot --headless --path . --script res://tests/density.gd -- --god --weather
```

Os testes de carga verificam limites e continuidade da simulação; não substituem medição de FPS/GPU em aparelhos reais. Avisos de encerramento do ObjectDB apareceram em alguns scripts de teste e não foram tratados como confirmação da causa de crash do celular.

## O que levar separadamente

O Git guarda código, artes, documentação e mídias do projeto. Releases guardam os executáveis. Contas, credenciais, conversas completas do Codex e progresso pessoal do jogador ficam fora do repositório público.

Para preservar o progresso do jogo no Windows, transfira privadamente a pasta de dados do usuário correspondente a `Godot/app_userdata/NOCTIR- One More Orbit` dentro de `%APPDATA%`.

Se possuir `.export-signing/noctir-release.keystore` e suas credenciais, leve-os por um meio privado. A assinatura precisa da mesma chave para atualizar uma instalação Android anterior. Essa pasta não estava disponível no diretório atual durante esta transferência.

Há uma transcrição privada desta conversa preparada em `builds/transferencia/Conversa-One-More-Orbit.md`, no computador antigo. Copie esse arquivo para o novo PC se quiser consultar as mensagens. Ele não é um arquivo de importação nativa do Codex nem contém as imagens anexadas; os anexos e caminhos locais precisam ser transferidos separadamente quando necessários.

## Mensagem pronta para um novo chat

> Este é o projeto One More Orbit, repositório Honorato1337/Noctir. Leia README.md, docs/CONTINUAR_EM_OUTRO_PC.md e docs/PERFORMANCE.md antes de alterar algo. Use o projeto nesta pasta. Preserve os sprites autorais e a fonte w95fa na interface. A versão Windows é 0.3.2 e o último APK é 0.3.0; não confunda os dois. Continue a partir desse estado e aguarde minha próxima solicitação.
