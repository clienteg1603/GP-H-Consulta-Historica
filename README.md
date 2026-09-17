# GP-H Consulta Histórica

Aplicativo gratuito para **consulta e análise histórica de resultados do Jogo do Bicho do Rio de Janeiro**, desenvolvido para Windows.

> **Escopo dos dados:** os resultados pesquisados e exibidos pelo programa são referentes ao **Rio de Janeiro**. O histórico não deve ser tratado automaticamente como válido para outras praças, estados ou bancas.

## Download

**Versão atual:** v0.1.14  
**Sistema:** Windows 10/11  
**Preço:** gratuito

➡️ **[Baixar GP-H Consulta Histórica v0.1.14 para Windows](https://github.com/clienteg1603/GP-H-Consulta-Historica/releases/download/v0.1.14/GP-H_Consulta_Historica_v0.1.14_Windows.zip)**

Também é possível abrir a [página oficial do Release v0.1.14](https://github.com/clienteg1603/GP-H-Consulta-Historica/releases/tag/v0.1.14).

O pacote já inclui o executável. **Não é necessário instalar Python.**

**SHA-256 do ZIP oficial:** `35e13022e5a5cea1c566f7cb72f4bbc0702b12d5e95ad4402ee8bda8b6983557`

## Primeira execução e criação do histórico

Em um computador onde o GP-H nunca foi usado, o arquivo local `gph_historico.db` ainda não existe.

A distribuição pública independente está sendo preparada para que a primeira execução faça automaticamente a carga inicial do histórico do **Rio de Janeiro**, criando o banco local em:

`%LOCALAPPDATA%\GP-H_Central_Historica\dados\gph_historico.db`

A carga histórica inicial deve funcionar assim:

1. detectar que o banco ainda não existe ou está vazio;
2. criar o banco local do usuário;
3. consultar os resultados do **Rio de Janeiro a partir de 02/01/2026**;
4. continuar a consulta **até a data atual disponível no momento da sincronização**;
5. salvar o progresso localmente;
6. nas próximas execuções, buscar apenas resultados novos ou correções necessárias, em vez de baixar todo o ano novamente.

Se algum resultado do dia ainda não estiver publicado pela fonte consultada, o programa poderá terminar a sincronização no **último resultado disponível** e completar o restante em uma atualização posterior.

> **Importante sobre a v0.1.14:** esta versão foi criada originalmente em um ambiente no qual o banco histórico já existia. A carga histórica automática completa para um PC totalmente novo será tratada como requisito da próxima revisão pública antes de recomendarmos a distribuição para novos usuários.

## Período da consulta

Para um usuário novo, o histórico público planejado começa em **02/01/2026** e vai até **o resultado mais recente disponível** no dia em que a atualização for feita.

Exemplo: se a primeira execução ocorrer em 17/09/2026 e todos os resultados desse dia já estiverem disponíveis, a base poderá abranger **02/01/2026 → 17/09/2026**. Se o último sorteio do dia ainda não estiver disponível, ele será incorporado quando a atualização for executada novamente.

## O que o programa oferece

- consulta organizada do histórico de resultados;
- visualização dos **Jogos do dia**, com as extrações separadas por horário;
- navegação por dia anterior e próximo, botão **Hoje** e calendário;
- atualização dos resultados pela própria tela;
- acompanhamento de atraso de **Bicho 1º–5º**;
- acompanhamento de **Cabeça 1º**, que considera especificamente a última aparição do animal no 1º prêmio;
- acompanhamento de atrasos de **Centena** e **Dezena**;
- consulta por bicho e informações da última ocorrência;
- interface gráfica própria para Windows, sem janela de console.

## Como instalar

1. Baixe o arquivo ZIP pelo botão acima.
2. Extraia o conteúdo para uma pasta de sua preferência.
3. Abra o executável do **GP-H Consulta Histórica**.

O programa é portátil e não exige instalação do Python.

## Sobre os resultados

O GP-H Consulta Histórica foi desenvolvido para trabalhar com o histórico usado no projeto GP-H e com resultados do **Rio de Janeiro**.

Resultados podem sofrer correções, atrasos de publicação ou diferenças conforme a fonte consultada. Por isso, informações muito recentes devem ser conferidas quando necessário.

## Uso responsável

O programa é uma ferramenta de **consulta, organização e análise histórica**. Dados passados e estatísticas não garantem resultados futuros.

O usuário é responsável pelo uso que fizer das informações apresentadas e por observar a legislação aplicável em sua localidade.

## Gratuito, mas não open source

O **GP-H Consulta Histórica** é disponibilizado gratuitamente para uso pessoal. A disponibilização gratuita do executável **não significa que o código-fonte esteja sendo publicado como software de código aberto**.

Consulte os [Termos de Uso](TERMOS_DE_USO.md) para as condições de distribuição e utilização.

## Versão

### v0.1.14

- mantém os recursos existentes da v0.1.13;
- adiciona o indicador **Cabeça 1º** na tela inicial;
- uma aparição no 2º, 3º, 4º ou 5º prêmio não zera o atraso de Cabeça 1º;
- mantém Jogos do dia, calendário, navegação entre datas e atualização de resultados;
- executável Windows sem necessidade de Python e sem abertura de console.

---

**GP-H Consulta Histórica** — consulta histórica de resultados do Rio de Janeiro para Windows.
