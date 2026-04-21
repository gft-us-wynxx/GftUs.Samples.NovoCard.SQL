

# card.transactions

## Visão Geral

Estrutura de dados responsável por armazenar os registros de transações financeiras realizadas com cartões na aplicação **NovoCard**. Contempla toda a atividade de cartões, incluindo compras, estornos, saques, cargas de saldo em cartões pré-pagos, taxas, juros e chargebacks. Cada registro representa um único evento de autorização ou liquidação (posting).

---

## Ciclo de Vida da Transação

| Estado | Descrição |
|---|---|
| **AUTHORIZED** | Reserva (hold) realizada no saldo/limite do cartão |
| **POSTED** | Transação compensada e liquidada |
| **REVERSED** | Estorno completo realizado antes da liquidação |
| **DECLINED** | Transação negada |
| **CANCELLED** | Transação cancelada |
| **DISPUTED** | Transação em disputa/contestação |

> Transações autorizadas migram para o estado **POSTED** após o processo de clearing (compensação).

---

## Estrutura de Dados

### Identificação da Transação

| Coluna | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `transactionid` | UNIQUEIDENTIFIER | Sim | Identificador único da transação (PK, gerado automaticamente) |
| `cardid` | UNIQUEIDENTIFIER | Sim | Referência ao cartão utilizado (FK → `card.cards`) |
| `accountid` | UNIQUEIDENTIFIER | Sim | Referência à conta do cartão (FK → `card.cardaccounts`) |
| `authorizationcode` | NVARCHAR(20) | Não | Código de autorização retornado pela bandeira |
| `externalreference` | NVARCHAR(100) | Não | Referência externa para integração com sistemas terceiros |

### Tipo de Transação

| Coluna | Tipo | Obrigatório | Valores Permitidos |
|---|---|---|---|
| `transactiontype` | NVARCHAR(30) | Sim | PURCHASE, REFUND, CASH_WITHDRAWAL, BALANCE_LOAD, FEE, REVERSAL, CHARGEBACK, INTEREST, CASH_ADVANCE |

### Valores e Câmbio

| Coluna | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `amount` | DECIMAL(15,2) | Sim | Valor final da transação na moeda de cobrança |
| `originalamount` | DECIMAL(15,2) | Não | Valor original na moeda do estabelecimento (antes da conversão cambial). Nulo para transações domésticas |
| `originalcurrency` | NCHAR(3) | Não | Moeda original da transação (código ISO) |
| `billingcurrency` | NCHAR(3) | Sim | Moeda de cobrança (padrão: **BRL**) |
| `exchangerate` | DECIMAL(12,6) | Não | Taxa de câmbio aplicada na conversão |

### Dados do Estabelecimento

| Coluna | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `merchantname` | NVARCHAR(255) | Não | Nome do estabelecimento |
| `merchantid` | NVARCHAR(50) | Não | Identificador do estabelecimento |
| `merchantcategorycode` | CHAR(4) | Não | Código de categoria do estabelecimento conforme ISO 18245 (MCC) |
| `merchantcity` | NVARCHAR(100) | Não | Cidade do estabelecimento |
| `merchantcountry` | NCHAR(2) | Não | País do estabelecimento (código ISO de 2 caracteres) |

### Estado e Características da Transação

| Coluna | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `status` | NVARCHAR(20) | Sim | Estado atual da transação (padrão: AUTHORIZED) |
| `declinereason` | NVARCHAR(100) | Não | Motivo da recusa, quando aplicável |
| `isonline` | BIT | Sim | Indica se a transação foi realizada online |
| `isinternational` | BIT | Sim | Indica se a transação é internacional |
| `iscontactless` | BIT | Sim | Indica se a transação foi por aproximação (contactless) |
| `installments` | SMALLINT | Sim | Número de parcelas (1 a 24). Valor 1 indica transação à vista |

### Datas e Timestamps

| Coluna | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `authorizedat` | DATETIMEOFFSET | Sim | Data/hora da autorização |
| `postedat` | DATETIMEOFFSET | Não | Data/hora da liquidação |
| `reversedat` | DATETIMEOFFSET | Não | Data/hora do estorno |
| `createdat` | DATETIMEOFFSET | Sim | Data/hora de criação do registro |

---

## Relacionamentos

| Chave Estrangeira | Tabela Referenciada | Coluna |
|---|---|---|
| `fktransactionscard` | `card.cards` | `cardid` |
| `fktransactionsaccount` | `card.cardaccounts` | `accountid` |

---

## Índices

| Índice | Coluna(s) | Finalidade |
|---|---|---|
| `pktransactions` | `transactionid` | Chave primária |
| `idxtransactionscardid` | `cardid` | Consultas por cartão |
| `idxtransactionsaccountid` | `accountid` | Consultas por conta |
| `idxtransactionsstatus` | `status` | Filtragem por estado da transação |
| `idxtransactionsauthorizedat` | `authorizedat` (DESC) | Consultas ordenadas por data de autorização (mais recentes primeiro) |
| `idxtransactionsmerchantcode` | `merchantcategorycode` | Análises por categoria de estabelecimento (MCC) |
| `idxtransactionstype` | `transactiontype` | Filtragem por tipo de transação |

---

## Regras de Negócio e Validações

| Regra | Descrição |
|---|---|
| `chktxntype` | Tipo de transação restrito a 9 valores pré-definidos |
| `chktxnstatus` | Status restrito a 6 estados válidos |
| `chktxninstallments` | Parcelamento limitado entre 1 e 24 parcelas |
| Criação condicional | A tabela só é criada se não existir previamente no banco de dados |

---

## Insights

- **Parcelamento brasileiro (parcelado):** O campo `installments` suporta de 1 a 24 parcelas, aderente ao modelo de parcelamento amplamente utilizado no mercado brasileiro.
- **Suporte a transações internacionais:** A estrutura contempla conversão cambial completa com moeda original, moeda de cobrança e taxa de câmbio, permitindo rastreabilidade total do valor cobrado ao portador.
- **Classificação MCC (ISO 18245):** O código de categoria do estabelecimento é utilizado para análises de gastos (spending analytics) e aplicação de regras de limite por categoria.
- **Indexação orientada a performance:** A presença de índices em colunas de alta cardinalidade de consulta (cartão, conta, status, data, tipo e MCC) indica um volume transacional elevado e necessidade de respostas rápidas em consultas operacionais e analíticas.
- **Modalidades de captura:** Os flags `isonline`, `isinternational` e `iscontactless` permitem segmentação detalhada do canal de captura, essencial para análise de fraude e comportamento de uso.
- **Moeda padrão BRL:** A moeda de cobrança padrão é o Real Brasileiro, confirmando que a aplicação é voltada ao mercado nacional com suporte a operações internacionais.
- **Rastreabilidade temporal completa:** Os campos de data (`authorizedat`, `postedat`, `reversedat`, `createdat`) permitem acompanhar todo o ciclo de vida da transação com precisão de fuso horário (DATETIMEOFFSET).
