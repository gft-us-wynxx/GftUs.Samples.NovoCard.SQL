

# card.vwtransactionsummary

## Visão Geral

View que fornece um **resumo mensal de gastos por cartão**, agregando informações por tipo de transação e categoria de estabelecimento comercial (MCC). Essa estrutura alimenta o **painel de análise de gastos** do aplicativo NovoCard e o **processo batch de geração de extratos**.

**Aplicação:** NovoCard
**Schema:** card
**Tipo:** View (estrutura de dados derivada)

---

## Fontes de Dados

| Tabela | Alias | Descrição |
|---|---|---|
| `card.transactions` | `t` | Transações realizadas com cartões |
| `card.cards` | `c` | Cadastro de cartões |
| `card.cardtypes` | `ct` | Tipos/produtos de cartão |

### Relacionamentos

| Origem | Destino | Condição |
|---|---|---|
| `card.transactions` | `card.cards` | `c.cardid = t.cardid` |
| `card.cards` | `card.cardtypes` | `ct.cardtypeid = c.cardtypeid` |

---

## Filtros Aplicados

Somente transações com os seguintes status são consideradas:

| Status | Descrição |
|---|---|
| `POSTED` | Transações efetivadas |
| `REVERSED` | Transações estornadas |
| `DISPUTED` | Transações em disputa |

---

## Colunas Retornadas

### Identificação

| Coluna | Descrição |
|---|---|
| `cardid` | Identificador do cartão |
| `customerid` | Identificador do cliente |
| `maskedpan` | Número do cartão mascarado |
| `lastfourdigits` | Últimos quatro dígitos do cartão |
| `productclass` | Classe do produto (ex: Gold, Platinum) |
| `network` | Bandeira do cartão |

### Dimensões de Agrupamento

| Coluna | Descrição |
|---|---|
| `statementmonth` | Primeiro dia do mês de referência (truncamento da data de autorização) |
| `transactiontype` | Tipo da transação (ex: compra, saque) |
| `merchantcategorycode` | Código de categoria do estabelecimento (MCC) |
| `billingcurrency` | Moeda de faturamento |

### Métricas de Volume e Valor

| Coluna | Descrição |
|---|---|
| `transactioncount` | Quantidade total de transações |
| `totalamount` | Valor total das transações |
| `avgamount` | Valor médio por transação |
| `maxsingletransaction` | Maior valor em uma única transação |
| `firsttransactionat` | Data/hora da primeira transação no período |
| `lasttransactionat` | Data/hora da última transação no período |

### Contadores por Modalidade

| Coluna | Descrição |
|---|---|
| `onlinecount` | Quantidade de transações realizadas online |
| `internationalcount` | Quantidade de transações internacionais |
| `contactlesscount` | Quantidade de transações por aproximação (contactless) |
| `reversalcount` | Quantidade de transações estornadas |
| `disputecount` | Quantidade de transações em disputa |

---

## Granularidade

Cada linha da view representa a combinação única de:

**Cartão → Mês de referência → Tipo de transação → Categoria do estabelecimento → Moeda de faturamento**

---

## Insights

- A coluna `statementmonth` é calculada utilizando `DATEADD/DATEDIFF` para truncar a data ao primeiro dia do mês, garantindo compatibilidade ampla com diferentes versões do SQL Server.
- Os contadores de modalidade (`onlinecount`, `internationalcount`, `contactlesscount`) permitem análises de comportamento de uso do cartão sem necessidade de consultar a tabela transacional de origem.
- A inclusão de transações com status `REVERSED` e `DISPUTED` junto com `POSTED` possibilita que os consumidores da view calculem valores líquidos (total menos estornos e disputas) conforme a necessidade do relatório.
- A presença de `reversalcount` e `disputecount` como colunas separadas viabiliza indicadores de qualidade operacional e risco por cartão/mês.
- A view centraliza dados de três tabelas distintas, servindo como camada de abstração tanto para o dashboard em tempo real quanto para o batch de extratos, reduzindo duplicação de lógica de negócio.
