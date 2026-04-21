# Documentação — `customer.customers`

## Aplicação

**NovoCard**

---

## Visão Geral

Estrutura de dados que representa o **cadastro principal de clientes** da plataforma NovoCard. Cada registro corresponde a uma pessoa física que realizou o processo de onboarding na plataforma. Um cliente pode possuir múltiplos cartões (crédito, débito e/ou pré-pago) vinculados ao seu cadastro.

---

## Esquema e Tabela

| Esquema    | Tabela      |
|------------|-------------|
| `customer` | `customers` |

---

## Estrutura de Dados

### Colunas

| Coluna | Tipo | Obrigatório | Valor Padrão | Descrição |
|---|---|---|---|---|
| `customerid` | `UNIQUEIDENTIFIER` | Sim | `NEWID()` | Identificador único do cliente (chave primária). |
| `firstname` | `NVARCHAR(100)` | Sim | — | Primeiro nome do cliente. |
| `lastname` | `NVARCHAR(100)` | Sim | — | Sobrenome do cliente. |
| `fullname` | Coluna computada (persistida) | — | `firstname + ' ' + lastname` | Nome completo, gerado automaticamente para indexação e exibição. |
| `email` | `NVARCHAR(255)` | Sim | — | Endereço de e-mail do cliente. Deve ser único na base. |
| `phone` | `NVARCHAR(20)` | Não | — | Número de telefone. |
| `dateofbirth` | `DATE` | Sim | — | Data de nascimento. |
| `taxpayerid` | `NVARCHAR(20)` | Sim | — | CPF (para clientes brasileiros) ou identificador fiscal nacional equivalente. Deve ser único. |
| `nationality` | `NCHAR(2)` | Sim | `BR` | Código de nacionalidade (padrão ISO de 2 caracteres). |
| `gender` | `NCHAR(1)` | Não | — | Gênero autodeclarado. |
| `incomerange` | `NVARCHAR(30)` | Não | — | Faixa de renda mensal autodeclarada, utilizada no cálculo de limite de crédito. |
| `creditscore` | `SMALLINT` | Não | — | Score interno NovoCard (0–1000), derivado de dados de bureau de crédito e sinais comportamentais. |
| `kycstatus` | `NVARCHAR(20)` | Sim | `PENDING` | Estado da verificação KYC (Know Your Customer). Cartões só podem ser emitidos quando o status é **APPROVED**. |
| `status` | `NVARCHAR(20)` | Sim | `ACTIVE` | Status geral do cadastro do cliente na plataforma. |
| `onboardedat` | `DATETIMEOFFSET` | Sim | `SYSDATETIMEOFFSET()` | Data/hora em que o cliente concluiu o onboarding. |
| `lastloginat` | `DATETIMEOFFSET` | Não | — | Data/hora do último login do cliente. |
| `createdat` | `DATETIMEOFFSET` | Sim | `SYSDATETIMEOFFSET()` | Data/hora de criação do registro. |
| `updatedat` | `DATETIMEOFFSET` | Sim | `SYSDATETIMEOFFSET()` | Data/hora da última atualização do registro. |

---

### Valores Permitidos (Constraints de Domínio)

| Coluna | Valores Aceitos |
|---|---|
| `gender` | `M` (Masculino), `F` (Feminino), `X` (Outro/Não-binário) |
| `incomerange` | `BELOW1K`, `1K3K`, `3K5K`, `5K10K`, `10K20K`, `ABOVE20K` |
| `creditscore` | Inteiro entre **0** e **1000** |
| `kycstatus` | `PENDING`, `INREVIEW`, `APPROVED`, `REJECTED` |
| `status` | `ACTIVE`, `SUSPENDED`, `CLOSED`, `BLOCKED` |

---

### Restrições de Unicidade

| Constraint | Coluna | Finalidade |
|---|---|---|
| `uqcustomersemail` | `email` | Garante que cada e-mail esteja associado a um único cliente. |
| `uqcustomerstaxpayerid` | `taxpayerid` | Garante que cada CPF/identificador fiscal esteja associado a um único cliente. |

---

### Índices

| Índice | Coluna(s) | Ordenação | Finalidade |
|---|---|---|---|
| `idxcustomersemail` | `email` | ASC (padrão) | Busca rápida por e-mail. |
| `idxcustomerstaxpayerid` | `taxpayerid` | ASC (padrão) | Busca rápida por CPF/identificador fiscal. |
| `idxcustomersstatus` | `status` | ASC (padrão) | Filtragem por status do cadastro. |
| `idxcustomerskycstatus` | `kycstatus` | ASC (padrão) | Filtragem por estado de verificação KYC. |
| `idxcustomerscreatedat` | `createdat` | DESC | Listagem de clientes mais recentes primeiro. |

---

## Regras de Negócio

1. **Emissão de cartões condicionada ao KYC**: Nenhum cartão (crédito, débito ou pré-pago) pode ser emitido para um cliente cujo `kycstatus` não esteja como `APPROVED`.
2. **Limite de crédito baseado em renda**: A faixa de renda autodeclarada (`incomerange`) é um dos insumos para o cálculo do limite de crédito do cliente.
3. **Score interno**: O `creditscore` é uma pontuação proprietária da NovoCard (escala de 0 a 1000), alimentada por dados de bureaus de crédito e sinais comportamentais do próprio cliente na plataforma.
4. **Criação condicional**: A tabela só é criada caso ainda não exista no banco de dados, evitando erros em execuções repetidas do script.

---

## Insights

- A nacionalidade padrão `BR` e o uso do CPF como identificador fiscal indicam que o mercado primário da NovoCard é o **Brasil**, embora a estrutura permita clientes de outras nacionalidades.
- O campo `lastloginat` sendo opcional sugere que existem clientes cadastrados que ainda não realizaram login (possivelmente em processo de onboarding ou com cadastro criado por canais alternativos).
- A separação entre `onboardedat` e `createdat` indica que o registro técnico pode ser criado em momento diferente da conclusão do onboarding, sugerindo um fluxo de cadastro em múltiplas etapas.
- A existência de índice descendente em `createdat` evidencia consultas frequentes que priorizam clientes mais recentes (dashboards, filas de análise, etc.).
- Os status `SUSPENDED` e `BLOCKED` representam estados distintos de restrição, o que pode indicar diferentes níveis de severidade ou motivos de bloqueio (ex.: inadimplência vs. fraude).
- A coluna `fullname` persistida otimiza consultas de busca e exibição, eliminando a necessidade de concatenação em tempo de execução.
