

# card.vwactivecards

## Visão Geral

A view **card.vwactivecards** pertence à aplicação **NovoCard** e tem como objetivo consolidar todas as informações relevantes de cartões que se encontram atualmente no estado operacional **ACTIVE** (ativo). Ela é consumida pela tela inicial do aplicativo móvel e pelos dashboards de atendimento ao cliente.

---

## Estrutura de Dados

Esta é uma **estrutura de dados** (view) que não contém lógica procedural. Ela agrega dados de múltiplas tabelas em uma única consulta para facilitar o consumo por sistemas downstream.

---

## Tabelas Envolvidas

| Alias | Tabela | Schema | Tipo de Junção | Finalidade |
|-------|--------|--------|----------------|------------|
| `c` | `cards` | `card` | Tabela principal | Dados cadastrais do cartão |
| `ct` | `cardtypes` | `card` | INNER JOIN | Classificação e tipo do cartão |
| `ca` | `cardaccounts` | `card` | INNER JOIN | Informações financeiras da conta vinculada |
| `cd` | `carddesigns` | `design` | LEFT JOIN | Design visual atualmente aplicado ao cartão |
| `dt` | `designtemplates` | `design` | LEFT JOIN | Template de design com cores e thumbnail |

---

## Colunas Retornadas

### Dados do Cartão

| Coluna | Descrição |
|--------|-----------|
| `cardid` | Identificador único do cartão |
| `customerid` | Identificador do cliente titular |
| `maskedpan` | Número do cartão mascarado |
| `cardholdername` | Nome impresso no cartão |
| `lastfourdigits` | Últimos quatro dígitos do cartão |
| `expirymonth` | Mês de expiração |
| `expiryyear` | Ano de expiração |
| `expiresat` | Data/hora completa de expiração |
| `cardformat` | Formato do cartão (físico, virtual, etc.) |
| `iscontactless` | Indica se suporta pagamento por aproximação |
| `isonlineenabled` | Indica se está habilitado para compras online |
| `isinternational` | Indica se permite transações internacionais |
| `status` | Status do cartão (sempre ACTIVE nesta view) |
| `activatedat` | Data/hora de ativação |
| `lastusedat` | Data/hora da última utilização |

### Tipo do Cartão

| Coluna | Origem | Descrição |
|--------|--------|-----------|
| `cardtypename` | `ct.typename` | Nome do tipo de cartão |
| `productclass` | `ct.productclass` | Classe do produto |
| `network` | `ct.network` | Bandeira (Visa, Mastercard, etc.) |
| `tier` | `ct.tier` | Nível/tier do cartão (Gold, Platinum, etc.) |

### Informações Financeiras

| Coluna | Descrição |
|--------|-----------|
| `currency` | Moeda da conta |
| `creditlimit` | Limite de crédito total |
| `availablebalance` | Saldo disponível para uso |
| `balance` | Saldo atual da conta |
| `pendingamount` | Valor de transações pendentes de liquidação |
| `duedate` | Data de vencimento da fatura |

### Design Visual

| Coluna | Origem | Descrição |
|--------|--------|-----------|
| `templatename` | `dt.displayname` | Nome de exibição do template de design |
| `designthumbnailurl` | `dt.thumbnailurl` | URL da miniatura do design do cartão |
| `designprimarycolor` | `dt.primarycolor` | Cor primária do design para renderização na interface |

---

## Critérios de Filtro

| Condição | Descrição |
|----------|-----------|
| `c.status = 'ACTIVE'` | Retorna apenas cartões com status ativo |
| `c.expiresat > SYSDATETIMEOFFSET()` | Exclui cartões já expirados com base na data/hora atual do servidor |
| `cd.iscurrent = 1` | Considera apenas o design atualmente vigente do cartão |
| `cd.approvalstatus = 'APPROVED'` | Considera apenas designs que foram aprovados |

---

## Insights

- As junções com as tabelas de design (`carddesigns` e `designtemplates`) utilizam **LEFT JOIN**, o que significa que cartões sem design personalizado ou sem design aprovado ainda serão retornados — as colunas de design virão como `NULL` nesses casos. Isso é esperado, pois nem todo cartão possui personalização visual.
- A view combina validação de status **e** de validade temporal, garantindo que cartões ativos porém expirados não sejam exibidos.
- A presença de `pendingamount` junto com `availablebalance` e `balance` permite que as interfaces de consumo apresentem uma visão financeira completa sem necessidade de cálculos adicionais.
- A coluna `lastusedat` pode ser utilizada para identificar cartões ativos com baixa utilização, sendo útil para estratégias de engajamento.
- A separação entre `creditlimit`, `balance` e `availablebalance` indica que o sistema suporta cenários onde autorizações pendentes reduzem o saldo disponível antes da efetivação.
