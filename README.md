# GP-H Consulta Histórica

Aplicativo gratuito para **consulta, pesquisa, análise e estudo histórico dos resultados do Jogo do Bicho do Rio de Janeiro**, desenvolvido para Windows.

> **Escopo dos dados:** os resultados pesquisados e exibidos pelo programa são referentes ao **Rio de Janeiro**. O histórico não deve ser tratado automaticamente como válido para outras praças, estados ou bancas.

## Download

**Versão atual:** v0.1.15  
**Sistema:** Windows 10/11  
**Preço:** gratuito

➡️ **[Baixar GP-H Consulta Histórica v0.1.15 para Windows](https://github.com/clienteg1603/GP-H-Consulta-Historica/releases/download/v0.1.15/GP-H_Consulta_Historica_v0.1.15_Windows.zip)**

Também é possível abrir a [página oficial do Release v0.1.15](https://github.com/clienteg1603/GP-H-Consulta-Historica/releases/tag/v0.1.15).

O pacote já inclui o executável. **Não é necessário instalar Python.**

**SHA-256 do ZIP oficial:** `32d0ff3483049c76ab7ebb481be6219f1f3c915dc24ec4b61b145729f0d134a0`

## Primeira utilização

Na primeira vez que o programa for aberto, ele irá **criar automaticamente sua base de dados e iniciar a primeira sincronização do histórico**.

Essa primeira sincronização irá consultar os resultados do **Rio de Janeiro desde 02/01/2026 até o último resultado disponível no momento da sincronização**.

Durante o processo, o programa mostra o andamento da carga. Caso a conexão seja interrompida, os dados já salvos são mantidos e a sincronização poderá continuar posteriormente.

Depois da primeira carga, as próximas sincronizações passam a buscar apenas os resultados novos ou necessários para manter a base atualizada.

## Recursos

- consulta do histórico de resultados;
- pesquisa por bicho, grupo, dezena, centena e milhar;
- filtros por período, sorteio e prêmio;
- consulta dos **Jogos do Dia**;
- indicadores de atraso;
- acompanhamento de **Cabeça 1º**;
- estatísticas e rankings históricos;
- base de dados armazenada localmente no computador;
- atualização dos resultados pela internet;
- interface gráfica para Windows, sem janela de console.

## Como usar

1. Baixe o arquivo ZIP pelo botão acima.
2. Extraia o conteúdo para uma pasta de sua preferência.
3. Execute `GP-H Consulta Historica.exe`.

É necessária conexão com a internet para realizar a primeira sincronização e buscar novas atualizações.

## Importante

Os dados utilizados pelo programa são referentes aos **resultados do Rio de Janeiro**.

Resultados de outras localidades, estados, praças ou bancas podem ser diferentes e **não fazem parte da base utilizada pelo GP-H Consulta Histórica**.

Resultados podem sofrer correções, atrasos de publicação ou diferenças conforme a fonte consultada. Informações muito recentes devem ser conferidas quando necessário.

Resultados, frequências, atrasos, rankings e demais estatísticas históricas **não garantem resultados futuros**.

O programa é disponibilizado gratuitamente para **consulta, análise e estudo histórico**.

## Gratuito, mas não open source

O **GP-H Consulta Histórica** é disponibilizado gratuitamente para uso pessoal. A disponibilização gratuita do executável **não significa que o código-fonte esteja sendo publicado como software de código aberto**.

Consulte os [Termos de Uso](TERMOS_DE_USO.md) para as condições de distribuição e utilização.

## Versão atual

### v0.1.15

- cria automaticamente a base local na primeira utilização;
- inicia a primeira sincronização do histórico sem configuração manual;
- consulta os resultados do Rio de Janeiro desde **02/01/2026** até o último resultado disponível;
- mantém o progresso caso a sincronização seja interrompida;
- depois da primeira carga, realiza atualizações incrementais;
- mantém Jogos do Dia, pesquisas, filtros, atrasos, estatísticas e rankings;
- executável Windows sem necessidade de Python e sem abertura de console.

---

**GP-H Consulta Histórica** — consulta histórica de resultados do Rio de Janeiro para Windows.
