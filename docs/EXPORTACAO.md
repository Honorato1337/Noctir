# Exportação Windows e Android

## Estado atual — 18/10/2026

- Windows **0.3.2**: `OneMoreOrbit.exe` disponível na [release atual](https://github.com/Honorato1337/Noctir/releases/tag/v0.3.2), com dados incorporados e checksum SHA-256.
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
