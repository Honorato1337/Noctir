# Exportação Windows, Linux e Android

## Linux AppImage 0.3.3

Pacote: `OneMoreOrbit-x86_64.AppImage`, 56.482.296 bytes. É a mesma exportação Linux x86_64, encapsulada em um AppImage tipo 2. Para abrir:

```sh
chmod +x OneMoreOrbit-x86_64.AppImage
./OneMoreOrbit-x86_64.AppImage
```

Se o sistema não permitir montar por FUSE, tente `./OneMoreOrbit-x86_64.AppImage --appimage-extract-and-run`. O driver gráfico ainda precisa suportar OpenGL 3.3. Estrutura, permissões internas, checksum do runtime e identidade do executável extraído foram verificados; execução nativa Linux permanece pendente.

Empacotamento no Windows: `python tools/package_appimage.py`, após gerar a exportação Linux. As ferramentas locais ficam em `.godot/export-tools/appimage`: [runtime oficial AppImage](https://github.com/AppImage/type2-runtime), `runtime-source.json` com URL e digest fornecidos pela API da release, e [SquashFS tools NG oficial para Windows](https://infraroot.at/pub/squashfs/windows/squashfs-tools-ng-1.3.2-mingw64.zip), extraído na subpasta `squashfs`. O relatório é salvo em `builds/linux/appimage-report.json`. Fontes e licenças do runtime estão no repositório oficial; as ferramentas de empacotamento não são incluídas no jogo.

## Ports locais — 18/10/2026

O preset `Linux` exporta x86_64 com o pacote de recursos incorporado. Execute `python tools/export_ports.py` com `GODOT_BIN` apontando para o Godot 4.7.2. O arquivo `builds/linux/OneMoreOrbit-Linux-x86_64.tar.gz` preserva a permissão de execução. Extraia e execute `./OneMoreOrbit.x86_64`; se necessário, use `chmod +x OneMoreOrbit.x86_64`. Requer suporte a OpenGL 3.3. A estrutura ELF e o conteúdo empacotado foram verificados no Windows; execução nativa Linux ainda precisa ser validada.

Para tentar apenas Android, execute `python tools/export_game.py --android-only`. O preset agora usa versão 0.3.3, código 22, ARM64 e ARM de 32 bits. O script prepara ferramentas oficiais isoladas em `.godot/export-tools` e cria uma chave local nova quando não existe uma. Não é a assinatura do APK antigo: uma instalação anterior pode precisar ser removida, apagando seu progresso. Guarde backup privado de `.export-signing`; nunca publique essa pasta. Execute `python tools/verify_ports.py` após ambas as exportações para verificar integridade, assinatura e alinhamento. Essa verificação não substitui testes em aparelho Android.

As seções abaixo registram o estado das releases já publicadas, anterior aos novos ports locais.

Resultado da exportação: Linux `.tar.gz` de 55.153.065 bytes; APK release de 77.743.455 bytes. Ambos são 0.3.3 e estão disponíveis na [release 0.3.3](https://github.com/Honorato1337/Noctir/releases/tag/v0.3.3). Linux passou na conferência ELF x86_64, integridade do arquivo e permissão de execução; o teste de mecânicas com seus recursos empacotados terminou com zero falhas. APK passou na assinatura, integridade ZIP e alinhamento de 16 KB; manifesto com minSdk 24 (Android 7), targetSdk 36, `arm64-v8a` e `armeabi-v7a`. Checksums em `builds/checksums-ports.json` e detalhes em `builds/verify-ports.log`. Nenhum dos dois foi executado no sistema alvo.

## Estado atual — 18/10/2026

- Windows **0.3.3**: `OneMoreOrbit.exe` disponível na [release atual](https://github.com/Honorato1337/Noctir/releases/tag/v0.3.3), com dados incorporados e checksum SHA-256.
- Android: último APK publicado **0.3.0**, na [release anterior](https://github.com/Honorato1337/Noctir/releases/tag/v0.3.0). Ainda não há APK com as otimizações da 0.3.1/0.3.2.
- Importe os recursos antes de exportar. As texturas preparadas em `assets/optimized` já estão versionadas; veja `tools/bake_runtime_art.gd` se alterar suas fontes.
- A chave Android e as credenciais não são distribuídas no Git. Elas não estavam presentes no diretório de trabalho atual; recupere a chave original por um meio privado antes de gerar uma atualização Android compatível.

O restante deste documento registra as ferramentas e verificações das exportações anteriores; não implica que SDKs e chave estejam instalados em um novo computador.

## Ferramentas e histórico

Arquivos de saída:

- builds/windows/OneMoreOrbit.exe: Windows x86_64, release, dados incorporados no executável.
- builds/android/OneMoreOrbit.apk: Android ARM64 e ARM de 32 bits, release assinado, pacote com.noctir.onemoreorbit, versão 0.3.0.

Para repetir a exportação, execute tools/export_game.py com Python. Na primeira execução, tools/prepare_exports.py baixa os templates oficiais Godot 4.7.2, OpenJDK Temurin 17 e ferramentas Android oficiais do Google. A instalação fica em .godot/export-tools, sem mudar Java ou Android do sistema. O Godot de exportação usa configuração portátil própria. Defina GODOT_BIN com o caminho do executável Godot 4.7.2; o script também procura Godot no PATH e na pasta Downloads do usuário. Os caminhos locais de templates são aplicados só durante a exportação, e o preset original é restaurado ao finalizar.

Testes, documentação, arquivos temporários e ferramentas locais são excluídos dos pacotes. Os originais dos sprites continuam no projeto.

## Assinatura Android

A chave está em .export-signing/noctir-release.keystore e as credenciais em .export-signing/credentials.json. O script repõe a configuração local de exportação automaticamente a partir dessa pasta. Esses arquivos ficam ignorados e não vão nos pacotes. Faça backup privado da pasta .export-signing antes de transferir o projeto: a mesma assinatura é necessária para atualizar o aplicativo instalado.

O APK pode ser instalado diretamente em um aparelho Android compatível. O sistema pode pedir autorização para instalar aplicativos da origem escolhida. Esta exportação não publica o jogo em nenhuma loja. A validação de instalação e desempenho em aparelho físico precisa ser feita em um celular.

Referência: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html

Validação desta versão: o EXE executou 60 frames fora do editor e encerrou com código 0; o APK passou na verificação de assinatura v2/v3 e alinhamento de 16 KB. Manifesto: minSdk 24, targetSdk 36, arm64-v8a e armeabi-v7a. Não foi instalado em aparelho físico. Hashes em builds/checksums.json.
