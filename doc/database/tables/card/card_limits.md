

# card.cardlimits — Controles de Velocidade de Gastos e Saques por Cartão

## Visão Geral

Estrutura de dados pertencente à aplicação **NovoCard** responsável por armazenar os **limites de velocidade de gastos e saques** associados a cada cartão. Cada cartão possui um único perfil de limites ativo. Os limites podem ser ajustados pelo próprio cliente (dentro do teto de elegibilidade) ou por analistas de risco como parte de uma resposta a fraude.

---

## Estrutura de Dados

### Identificação e Relacionamento

| Coluna | Tipo | Nulável | Padrão | Descrição |
|--------|------|---------|--------|-----------|
| `limitid` | UNIQUEIDENTIFIER | Não | `NEWID()` | Identificador único do registro de limites (chave primária) |
| `cardid` | UNIQUEIDENTIFIER | Não | — | Referência ao cartão associado (chave única, com exclusão em cascata) |

### Limites de Compra

| Coluna | Tipo | Nulável | Padrão | Descrição |
|--------|------|---------|--------|-----------|
| `dailypurchaselimit` | DECIMAL(12,2) | Não | 5.000,00 | Limite diário para compras |
| `monthlypurchaselimit` | DECIMAL(12,2) | Não | 30.000,00 | Limite mensal para compras |

### Limites de Saque (ATM / Dinheiro)

| Coluna | Tipo | Nulável | Padrão | Descrição |
|--------|------|---------|--------|-----------|
| `dailywithdrawallimit` | DECIMAL(12,2) | Não | 1.500,00 | Limite diário para saques em caixa eletrônico |
| `monthlywithdrawallimit` | DECIMAL(12,2) | Não | 5.000,00 | Limite mensal para saques em caixa eletrônico |

### Limites por Canal

| Coluna | Tipo | Nulável | Padrão | Descrição |
|--------|------|---------|--------|-----------|
| `onlinetransactionlimit` | DECIMAL(12,2) | Não | 3.000,00 | Limite para transações online |
| `contactlesslimit` | DECIMAL(10,2) | Não | 300,00 | Teto por aproximação (NFC/contactless) sem necessidade de PIN |
| `internationaldailylimit` | DECIMAL(12,2) | Não | 2.000,00 | Limite diário para transações internacionais |

### Limite por Transação Individual

| Coluna | Tipo | Nulável | Padrão | Descrição |
|--------|------|---------|--------|-----------|
| `singletransactionlimit` | DECIMAL(12,2) | Não | 5.000,00 | Valor máximo permitido em uma única transação |

### Controle de Origem e Temporalidade

| Coluna | Tipo | Nulável | Padrão | Descrição |
|--------|------|---------|--------|-----------|
| `setby` | NVARCHAR(20) | Não | `SYSTEM` | Origem da definição do limite |
| `istemporary` | BIT | Não | 0 | Indica se os limites são temporários |
| `temporaryuntil` | DATETIMEOFFSET | Sim | — | Data/hora até a qual os limites temporários são válidos; após esse momento, os valores anteriores são restaurados |
| `reason` | NVARCHAR(255) | Sim | — | Justificativa para a alteração dos limites |
| `createdat` | DATETIMEOFFSET | Não | `SYSDATETIMEOFFSET()` | Data/hora de criação do registro |
| `updatedat` | DATETIMEOFFSET | Não | `SYSDATETIMEOFFSET()` | Data/hora da última atualização |

### Valores Permitidos para `setby`

| Valor | Significado |
|-------|-------------|
| `SYSTEM` | Limites definidos automaticamente na emissão do cartão |
| `CUSTOMER` | Limites ajustados pelo cliente via autoatendimento |
| `RISKANALYST` | Limites alterados por analista de risco (override de compliance/fraude) |

---

## Restrições e Regras de Integridade

| Constraint | Tipo | Regra |
|------------|------|-------|
| `pkcardlimits` | Primary Key | `limitid` é identificador único do registro |
| `uqcardlimitscard` | Unique + Foreign Key | Cada cartão possui no máximo um registro de limites; referencia `card.cards(cardid)` com exclusão em cascata |
| `chklimitssetby` | Check | `setby` deve ser `SYSTEM`, `CUSTOMER` ou `RISKANALYST` |
| `chkdailyltemonthlypurchase` | Check | O limite diário de compras não pode exceder o limite mensal de compras |
| `chkdailyltemonthlywithdrawal` | Check | O limite diário de saques não pode exceder o limite mensal de saques |
| `chksingleltedaily` | Check | O limite por transação individual não pode exceder o limite diário de compras |

---

## Índices

| Índice | Coluna(s) | Finalidade |
|--------|-----------|------------|
| `idxcardlimitscardid` | `cardid` | Otimização de consultas por cartão |

---

## Insights

- **Relação 1:1 com o cartão**: A constraint `UNIQUE` em `cardid` garante que cada cartão tenha exatamente um perfil de limites ativo, simplificando a lógica de autorização de transações.
- **Exclusão em cascata**: Ao remover um cartão da tabela `card.cards`, o registro de limites correspondente é automaticamente excluído, mantendo a consistência referencial.
- **Hierarquia de limites protegida por constraints**: As regras de check garantem em nível de banco de dados que `transação individual ≤ diário ≤ mensal`, prevenindo configurações inconsistentes independentemente da origem da alteração.
- **Mecanismo de limites temporários**: A combinação de `istemporary` e `temporaryuntil` permite que analistas de risco reduzam limites de forma emergencial com reversão automática programada — cenário típico de resposta a suspeita de fraude.
- **Rastreabilidade de alterações**: Os campos `setby` e `reason` fornecem trilha de auditoria sobre quem alterou os limites e por qual motivo, essencial para compliance regulatório.
- **Limites por contactless significativamente menores**: O teto de 300,00 para transações por aproximação (sem PIN) reflete a prática de mercado de mitigar riscos em transações sem autenticação forte.
- **Criação condicional**: A tabela só é criada se ainda não existir, permitindo execução idempotente do script em ambientes de deploy contínuo.
