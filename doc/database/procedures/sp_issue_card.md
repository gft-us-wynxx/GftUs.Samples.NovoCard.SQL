# Documentação: Procedimento de Emissão de Cartão

## Visão Geral

| Atributo | Detalhe |
|---|---|
| **Nome** | `card.spissuecard` |
| **Aplicação** | NovoCard |
| **Schema** | `card` |
| **Finalidade** | Emitir um novo cartão para um cliente elegível, realizando todas as validações de negócio necessárias e criando os registros associados em uma única transação atômica |

O procedimento orquestra o processo completo de emissão de um cartão, desde a verificação de elegibilidade do cliente até a criação do cartão, sua conta vinculada, limites de gasto padrão e, opcionalmente, a atribuição de um template de design visual.

---

## Parâmetros

| Parâmetro | Tipo | Obrigatório | Padrão | Descrição |
|---|---|---|---|---|
| `@p_customer_id` | UNIQUEIDENTIFIER | Sim | — | Identificador do cliente destinatário |
| `@p_card_type_id` | INT | Sim | — | Tipo de produto do cartão a ser emitido |
| `@p_cardholder_name` | NVARCHAR(100) | Sim | — | Nome a ser gravado/embossado no cartão |
| `@p_masked_pan` | NVARCHAR(19) | Sim | — | PAN mascarado pré-gerado pelo serviço de cofre (vault) |
| `@p_expiry_month` | SMALLINT | Sim | — | Mês de validade (1–12) |
| `@p_expiry_year` | SMALLINT | Sim | — | Ano de validade (4 dígitos) |
| `@p_card_format` | NVARCHAR(10) | Não | `PHYSICAL` | Formato do cartão: `PHYSICAL`, `VIRTUAL` ou `BOTH` |
| `@p_template_id` | UNIQUEIDENTIFIER | Não | NULL | Template de design visual (opcional) |
| `@p_credit_limit` | DECIMAL(15,2) | Não | 0.00 | Limite de crédito inicial (0 para débito/pré-pago) |
| `@p_initial_balance` | DECIMAL(15,2) | Não | 0.00 | Saldo inicial carregado (aplicável apenas a pré-pago) |
| `@p_issued_by` | NVARCHAR(100) | Não | `SYSTEM_USER` | Identificador do operador ou sistema solicitante |
| `@p_card_id` | UNIQUEIDENTIFIER | **OUTPUT** | — | Retorna o identificador do cartão recém-criado |

---

## Regras de Negócio

### Validações de Elegibilidade

| # | Regra | Código de Erro | Mensagem |
|---|---|---|---|
| 1 | O cliente deve existir na base de dados | 51000 | *Customer not found.* |
| 2 | O status KYC do cliente deve ser **APPROVED** | 51001 | *Customer KYC status is [status]. Card issuance requires APPROVED status.* |
| 3 | O cliente deve estar com status **ACTIVE** | 51002 | *Customer is not ACTIVE (current: [status]). Cannot issue card.* |
| 4 | O tipo de cartão solicitado deve existir | 51003 | *Card type not found.* |
| 5 | O tipo de cartão deve estar ativo (`is_active = 1`) | 51004 | *Card type is not currently active.* |

### Regras de Processamento

- O saldo inicial (`initial_balance`) só é aplicado quando a classe do produto é **PREPAID**. Para demais classes, o saldo é zerado automaticamente.
- Todo cartão é criado com status inicial **PENDING_ACTIVATION**, exigindo ativação posterior.
- A moeda padrão da conta é **BRL** (Real Brasileiro).
- Limites de gasto padrão são criados automaticamente pelo sistema (`set_by = SYSTEM`).
- Quando um template de design é informado, ele é vinculado ao cartão com status de aprovação **APPROVED** e marcado como design corrente (`is_current = 1`).
- Se o parâmetro `@p_issued_by` não for informado, o sistema utiliza a função `SYSTEM_USER` do SQL Server para identificar o operador.

---

## Entidades Envolvidas

| Tabela | Schema | Operação | Finalidade |
|---|---|---|---|
| `customer.customers` | customer | SELECT | Validação de existência, KYC e status do cliente |
| `card.card_types` | card | SELECT | Validação do tipo de cartão |
| `card.cards` | card | INSERT / UPDATE | Criação do registro principal do cartão |
| `card.card_accounts` | card | INSERT | Criação da conta financeira vinculada ao cartão |
| `card.card_limits` | card | INSERT | Definição dos limites de gasto padrão |
| `card.card_status_history` | card | INSERT | Registro do histórico de status (auditoria) |
| `design.card_designs` | design | INSERT | Atribuição do template de design visual |

---

## Process Flow

```mermaid
graph TD
    A[Início - Solicitação de Emissão] --> B{Operador informado?}
    B -- Não --> B1[Definir issued_by como SYSTEM_USER]
    B -- Sim --> C
    B1 --> C{Cliente existe?}
    C -- Não --> C1[Erro 51000: Cliente não encontrado]
    C -- Sim --> D{KYC aprovado?}
    D -- Não --> D1[Erro 51001: KYC não aprovado]
    D -- Sim --> E{Cliente ativo?}
    E -- Não --> E1[Erro 51002: Cliente inativo]
    E -- Sim --> F{Tipo de cartão existe?}
    F -- Não --> F1[Erro 51003: Tipo não encontrado]
    F -- Sim --> G{Tipo de cartão ativo?}
    G -- Não --> G1[Erro 51004: Tipo inativo]
    G -- Sim --> H[Gerar IDs: card_id e account_id]
    H --> I[Calcular saldo inicial conforme classe do produto]
    I --> J[Inserir cartão com status PENDING_ACTIVATION]
    J --> K[Criar conta vinculada em BRL]
    K --> L[Criar limites de gasto padrão]
    L --> M{Template de design informado?}
    M -- Sim --> N[Criar registro de design]
    N --> O[Atualizar cartão com design_id]
    O --> P[Registrar histórico de status]
    M -- Não --> P
    P --> Q[Retornar card_id via OUTPUT]
    Q --> R[Fim]
```

---

## Insights

- **Concorrência controlada**: A consulta ao cliente utiliza hints de lock (`UPDLOCK, ROWLOCK`), o que previne condições de corrida em cenários de emissão simultânea para o mesmo cliente.
- **Atomicidade implícita**: Embora o procedimento não declare explicitamente `BEGIN TRANSACTION`, a expectativa é que o chamador gerencie a transação externa, garantindo que todos os registros (cartão, conta, limites, design, histórico) sejam persistidos ou revertidos em conjunto.
- **Rastreabilidade completa**: O histórico de status é registrado desde a criação, com status anterior `N/A` e novo status `PENDING_ACTIVATION`, permitindo auditoria completa do ciclo de vida do cartão.
- **Separação de responsabilidades com o Vault**: O PAN (número do cartão) não é gerado nem armazenado em texto claro por este procedimento — apenas a versão mascarada é recebida de um serviço externo de cofre, reforçando conformidade com padrões de segurança como **PCI-DSS**.
- **Saldo inicial condicionado à classe do produto**: A lógica garante que apenas cartões **pré-pagos** recebam saldo inicial, evitando inconsistências para produtos de crédito ou débito.
- **Design como entidade independente**: A arquitetura permite que templates de design sejam gerenciados separadamente (schema `design`), possibilitando personalização visual sem impacto na estrutura financeira do cartão.
- **Limite de crédito e saldo disponível**: Na criação da conta, o `available_balance` é inicializado com o valor do `credit_limit`, representando o limite total disponível para uso imediato após ativação.
