

# customer.vwcustomercardportfolio

## Visão Geral

Estrutura de dados do tipo **View** pertencente ao schema `customer`, na aplicação **NovoCard**. Consolida informações de portfólio de cartões no nível do cliente, apresentando a quantidade de cartões por classe de produto, a exposição total de crédito e o contexto de KYC e status cadastral. Utilizada pelas equipes de **CRM** e **Risco**.

---

## Tabelas de Origem

| Alias | Tabela | Schema | Tipo de Junção | Chave de Relacionamento |
|-------|--------|--------|----------------|-------------------------|
| `cust` | `customers` | `customer` | Tabela principal | — |
| `c` | `cards` | `card` | LEFT JOIN | `c.customerid = cust.customerid` |
| `ct` | `cardtypes` | `card` | LEFT JOIN | `ct.cardtypeid = c.cardtypeid` |
| `ca` | `cardaccounts` | `card` | LEFT JOIN | `ca.cardid = c.cardid` |

O uso de `LEFT JOIN` garante que todos os clientes sejam retornados, mesmo aqueles que não possuem cartões vinculados.

---

## Colunas Retornadas

### Dados Cadastrais do Cliente

| Coluna | Descrição |
|--------|-----------|
| `customerid` | Identificador único do cliente |
| `fullname` | Nome completo |
| `email` | Endereço de e-mail |
| `kycstatus` | Situação do processo de Know Your Customer |
| `customerstatus` | Status cadastral do cliente |
| `creditscore` | Pontuação de crédito |
| `incomerange` | Faixa de renda declarada |

### Contagem de Cartões por Classe de Produto

| Coluna | Descrição |
|--------|-----------|
| `totalcards` | Quantidade total de cartões vinculados ao cliente (todos os status) |
| `activecreditcards` | Quantidade de cartões de **crédito** com status ativo |
| `activedebitcards` | Quantidade de cartões de **débito** com status ativo |
| `activeprepaidcards` | Quantidade de cartões **pré-pagos** com status ativo |

### Exposição de Crédito

| Coluna | Descrição |
|--------|-----------|
| `totalcreditlimit` | Soma dos limites de crédito de todos os cartões de crédito |
| `totalcreditutilized` | Soma dos saldos utilizados nos cartões de crédito |
| `totalcreditavailable` | Soma do crédito disponível nos cartões de crédito |

### Saldos Pré-Pagos

| Coluna | Descrição |
|--------|-----------|
| `totalprepaidbalance` | Soma dos saldos dos cartões pré-pagos |

### Atividade e Datas

| Coluna | Descrição |
|--------|-----------|
| `lastcardusedat` | Data/hora da última utilização de qualquer cartão do cliente |
| `onboardedat` | Data de cadastro (onboarding) do cliente |
| `lastloginat` | Data/hora do último login do cliente |

---

## Classes de Produto Consideradas

| Classe | Descrição |
|--------|-----------|
| `CREDIT` | Cartão de crédito |
| `DEBIT` | Cartão de débito |
| `PREPAID` | Cartão pré-pago |

---

## Regras de Negócio

1. **Contagem de cartões ativos**: apenas cartões com `status = 'ACTIVE'` são contabilizados nas colunas segmentadas por classe de produto. A coluna `totalcards` considera todos os cartões independentemente de status.
2. **Exposição de crédito**: calculada exclusivamente para cartões da classe `CREDIT`, sem filtro de status — ou seja, inclui cartões de crédito bloqueados ou cancelados que ainda possuam saldo.
3. **Saldo pré-pago**: agregado para todos os cartões da classe `PREPAID`, também sem filtro de status.
4. **Tratamento de nulos**: as colunas financeiras utilizam `COALESCE(..., 0)` para garantir que clientes sem cartões da respectiva classe retornem valor zero em vez de nulo.

---

## Insights

- A view fornece uma **visão 360° do portfólio de cartões** de cada cliente, sendo uma fonte centralizada para dashboards de CRM e relatórios de risco.
- A inclusão de `creditscore` e `incomerange` junto com a exposição de crédito permite análises de **concentração de risco** e **adequação de limite** diretamente a partir desta view.
- A comparação entre `totalcreditlimit` e `totalcreditutilized` viabiliza o cálculo da **taxa de utilização de crédito** (utilization rate), métrica fundamental para gestão de risco.
- A presença de `kycstatus` permite filtrar rapidamente clientes com pendências regulatórias que possuam exposição de crédito ativa.
- As colunas `lastcardusedat` e `lastloginat` possibilitam identificar clientes **inativos** ou com risco de churn, apoiando campanhas de retenção.
- Cartões de crédito inativos, bloqueados ou cancelados **são incluídos** nos totais de exposição financeira, o que é relevante para cenários de cobrança e provisionamento.
- Não há segmentação de métricas financeiras para cartões de **débito**, indicando que esses cartões não possuem saldo ou limite gerenciado neste modelo.
