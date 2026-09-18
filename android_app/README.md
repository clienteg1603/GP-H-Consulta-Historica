# GP-H Consulta Histórica — Android

Versão Android em Flutter do GP-H Consulta Histórica.

## Estado atual

Versão de desenvolvimento: **0.1.0 alpha 3**.

Implementado:

- interface própria para Android;
- banco SQLite local;
- primeira sincronização histórica desde 02/01/2026;
- retomada da sincronização em caso de interrupção;
- atualização incremental dos resultados;
- Jogos do dia;
- Pesquisa por Bicho, Grupo, Dezena, Centena e Milhar;
- verificação automática de nova versão pela internet;
- botão manual de atualização no topo do app;
- download do APK mais recente por link público;
- canal de distribuição `android-release` gerado automaticamente pelo GitHub Actions;
- APK release ARM64 para reduzir bastante o tamanho em relação ao APK debug.

## Atualizações do aplicativo

O app consulta o manifesto público:

`https://raw.githubusercontent.com/clienteg1603/GP-H-Consulta-Historica/android-release/latest.json`

Quando o número de build disponível for maior que o instalado, o GP-H mostra uma janela com a nova versão e o botão **Baixar atualização**.

O APK mais recente fica sempre no mesmo endereço público informado pelo manifesto. O Android ainda solicita a confirmação da instalação, como proteção do sistema.

Durante a fase alpha é usada uma chave de assinatura exclusiva de testes. Ela é preservada pelo canal `android-release` para que as próximas alphas possam ser instaladas por cima da Alpha 3 sem desinstalar o aplicativo.

> A chave alpha não será usada na publicação final na Play Store. Antes da versão pública definitiva será adotada uma assinatura de produção.

## Build

O workflow `.github/workflows/android-release.yml` cria um projeto Android temporário, executa análise e testes, gera um APK ARM64 release assinado e publica o APK, o manifesto e a chave alpha na branch `android-release`.
