# card.cardaccounts

## Visão Geral

Estrutura de dados pertencente à aplicação **NovoCard** que representa o estado financeiro da conta associada a cada cartão. Esta tabela armazena informações de saldo, limite de crédito, valores pendentes e dados de fatura para os diferentes tipos de cartão suportados:

| Tipo de Cartão | Comportamento |
|---|---|
| **Crédito** | Rastreia o limite de crédito e o valor utilizado |
| **Pré-pago** | Rastreia o saldo carregado |
| **Débito** | Reflete um snapshot do saldo da conta corrente vinculada, atualizado de forma assíncrona |

---

## Estrutura de Dados

### Esquema e Localização

- **Esquema:** `card`
- **Tabela:** `cardaccounts`
- **Tipo:** Tabela relacional (estrutura de dados)

### Colunas

| Coluna | Tipo | Obrigatório | Valor Padrão | Descrição |
|---|---|---|---|---|
| `accountid` | UNIQUEIDENTIFIER | Sim | `NEWID()` | Identificador único da conta |
| `cardid` | UNIQUEIDENTIFIER | Sim | — | Referência ao cartão associado |
| `currency` | NCHAR(3) | Sim | `BRL` | Código da moeda (ISO 4217) |
| `balance` | DECIMAL(15,2) | Sim | 0.00 | Saldo atual da conta |
| `creditlimit` | DECIMAL(15,2) | Sim | 0.00 | Limite de crédito concedido |
| `availablebalance` | DECIMAL(15,2) | Sim | 0.00 | Valor disponível para gasto em tempo real (limite − utilizado − pendente) |
| `pendingamount` | DECIMAL(15,2) | Sim | 0.00 | Autorizações retidas ainda não liquidadas como transações postadas |
| `statementbalance` | DECIMAL(15,2) | Sim | 0.00 | Saldo capturado no fechamento da última fatura, base para cálculo do pagamento mínimo |
| `minimumpayment` | DECIMAL(15,2) | Sim | 0.00 | Valor do pagamento mínimo da fatura |
| `duedate` | DATE | Não | NULL | Data de vencimento da fatura |
| `laststatementdate` | DATE | Não | NULL | Data do último fechamento de fatura |
| `lastpaymentdate` | DATETIMEOFFSET | Não | NULL | Data e hora do último pagamento realizado |
| `lastpaymentamount` | DECIMAL(15,2) | Não | NULL | Valor do último pagamento realizado |
| `updatedat` | DATETIMEOFFSET | Sim | `SYSDATETIMEOFFSET()` | Timestamp da última atualização do registro |

### Chave Primária

| Constraint | Coluna |
|---|---|
| `pkcardaccounts` | `accountid` |

### Relacionamentos

| Constraint | Coluna | Tabela Referenciada | Coluna Referenciada | Comportamento ao Deletar |
|---|---|---|---|---|
| `uqcardaccountscard` | `cardid` | `card.cards` | `cardid` | CASCADE |

A constraint `uqcardaccountscard` também garante **unicidade**, assegurando que cada cartão possua no máximo uma conta financeira.

### Regras de Validação (CHECK Constraints)

| Constraint | Regra | Finalidade |
|---|---|---|
| `chkcreditlimitnonnegative` | `creditlimit >= 0` | Impede limite de crédito negativo |
| `chkavailablebalancerange` | `availablebalance <= creditlimit` | Garante que o saldo disponível não exceda o limite |
| `chkpendingnonnegative` | `pendingamount >= 0` | Impede valor pendente negativo |

### Índices

| Índice | Coluna | Finalidade |
|---|---|---|
| `idxcardaccountscardid` | `cardid` | Otimiza consultas por cartão |
| `idxcardaccountsduedate` | `duedate` | Otimiza consultas por data de vencimento (ex.: cobranças, alertas) |

---

## Insights

- A criação da tabela é **idempotente** — só é executada caso a tabela ainda não exista, evitando erros em re-execuções de scripts.
- A moeda padrão **BRL** (Real Brasileiro) indica que a aplicação é voltada primariamente ao mercado brasileiro, embora o campo permita outras moedas.
- O campo `availablebalance` representa o valor efetivamente disponível para uso, já descontando autorizações pendentes, o que é essencial para decisões de aprovação de transações em tempo real.
- O campo `statementbalance` serve como base para o cálculo do pagamento mínimo, desacoplando o saldo da fatura do saldo corrente que continua sendo movimentado.
- O índice em `duedate` sugere a existência de processos batch ou rotinas de notificação que consultam contas por proximidade de vencimento.
- A exclusão em cascata via `cardid` garante que, ao remover um cartão da tabela `card.cards`, sua conta financeira correspondente é automaticamente eliminada, mantendo a integridade referencial.
- O uso de `DATETIMEOFFSET` nos campos de timestamp indica suporte a múltiplos fusos horários, relevante para operações internacionais ou registros de auditoria precisos.
