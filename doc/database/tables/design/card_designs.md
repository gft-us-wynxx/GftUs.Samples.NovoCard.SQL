

# design.carddesigns

## Visão Geral

Estrutura de dados pertencente à aplicação **NovoCard** responsável por registrar o design (arte/personalização visual) aplicado a um cartão específico. Cada cartão possui no máximo um design vigente (`iscurrent = 1`), porém todo o histórico de designs anteriores é mantido para fins de rastreabilidade.

Os clientes podem personalizar elementos visuais sobre o template base, como nome impresso, cor de destaque, monograma e preferência de fonte. Toda personalização passa por um fluxo de **moderação de conteúdo** antes de ser aprovada para impressão/renderização.

---

## Esquema e Relacionamentos

| Relacionamento | Tabela Referenciada | Coluna FK | Comportamento de Exclusão |
|---|---|---|---|
| Cartão | `card.cards` | `cardid` | `CASCADE` — ao excluir o cartão, seus designs são removidos |
| Template | `design.designtemplates` | `templateid` | Sem cascata (restrição padrão) |

---

## Estrutura de Colunas

### Identificação

| Coluna | Tipo | Nulável | Padrão | Descrição |
|---|---|---|---|---|
| `designid` | `UNIQUEIDENTIFIER` | Não | `NEWID()` | Chave primária do design |
| `cardid` | `UNIQUEIDENTIFIER` | Não | — | Cartão ao qual o design está associado |
| `templateid` | `UNIQUEIDENTIFIER` | Não | — | Template base utilizado para o design |

### Personalização do Cliente

| Coluna | Tipo | Nulável | Padrão | Descrição |
|---|---|---|---|---|
| `customnametext` | `NVARCHAR(26)` | Sim | — | Nome personalizado impresso na face do cartão, substituindo o nome completo (máx. 26 caracteres) |
| `customcolor` | `NCHAR(7)` | Sim | — | Cor hexadecimal de destaque escolhida pelo cliente (ex.: `#FF5A2D`) |
| `monogram` | `NCHAR(2)` | Sim | — | Monograma de 1 a 2 caracteres |
| `fontpreference` | `NVARCHAR(30)` | Sim | — | Preferência de fonte para renderização |

### Estado do Design

| Coluna | Tipo | Nulável | Padrão | Descrição |
|---|---|---|---|---|
| `iscurrent` | `BIT` | Não | `1` | Indica se este é o design vigente do cartão |
| `approvalstatus` | `NVARCHAR(20)` | Não | `PENDING` | Status da moderação de conteúdo |
| `approvedat` | `DATETIMEOFFSET` | Sim | — | Data/hora da aprovação |
| `rejectionreason` | `NVARCHAR(255)` | Sim | — | Motivo da rejeição, quando aplicável |
| `assignedat` | `DATETIMEOFFSET` | Não | `SYSDATETIMEOFFSET()` | Data/hora em que o design foi atribuído ao cartão |
| `replacedat` | `DATETIMEOFFSET` | Sim | — | Data/hora em que o design foi substituído por outro |

#### Valores Permitidos para `approvalstatus`

| Valor | Significado |
|---|---|
| `PENDING` | Aguardando moderação |
| `APPROVED` | Aprovado para impressão/renderização |
| `REJECTED` | Rejeitado pela moderação |
| `CANCELLED` | Cancelado |

### Metadados de Renderização

| Coluna | Tipo | Nulável | Padrão | Descrição |
|---|---|---|---|---|
| `renderurl` | `NVARCHAR(500)` | Sim | — | URL da imagem/artefato renderizado |
| `renderversion` | `SMALLINT` | Não | `1` | Versão da renderização (incrementada a cada re-renderização) |
| `renderedat` | `DATETIMEOFFSET` | Sim | — | Data/hora da última renderização |

### Auditoria

| Coluna | Tipo | Nulável | Padrão | Descrição |
|---|---|---|---|---|
| `createdat` | `DATETIMEOFFSET` | Não | `SYSDATETIMEOFFSET()` | Data/hora de criação do registro |

---

## Índices

| Índice | Colunas | Tipo | Finalidade |
|---|---|---|---|
| `pk_carddesigns` | `designid` | Primary Key | Identificação única do design |
| `idx_carddesigns_cardid` | `cardid` | Não-único | Consultas por cartão |
| `idx_carddesigns_templateid` | `templateid` | Não-único | Consultas por template |
| `idx_carddesigns_onecurrent` | `cardid` (filtrado: `iscurrent = 1`) | **Único filtrado** | Garante que apenas um design vigente exista por cartão |
| `idx_carddesigns_approval` | `approvalstatus` | Não-único | Consultas por status de aprovação |

---

## Insights

- **Unicidade do design vigente**: O índice único filtrado `idx_carddesigns_onecurrent` é a garantia em nível de banco de dados de que nunca haverá dois designs simultâneos marcados como vigentes para o mesmo cartão. Qualquer processo de troca de design deve desativar o anterior (`iscurrent = 0` e preencher `replacedat`) antes de inserir ou ativar o novo.

- **Fluxo de moderação obrigatório**: Todo design nasce com status `PENDING`. A personalização só deve ser renderizada e impressa após transição para `APPROVED`. Processos de fila/backoffice podem utilizar o índice `idx_carddesigns_approval` para buscar itens pendentes de forma eficiente.

- **Exclusão em cascata**: A remoção de um cartão na tabela `card.cards` elimina automaticamente todo o histórico de designs associados. Já a exclusão de um template em `design.designtemplates` será bloqueada enquanto houver designs referenciando-o.

- **Versionamento de renderização**: O campo `renderversion` permite rastrear quantas vezes a arte foi gerada, útil para cenários de re-renderização após correções no template ou nos dados do cliente.

- **Criação condicional**: A tabela só é criada caso ainda não exista no banco (`IF OBJECT_ID ... IS NULL`), garantindo idempotência do script de implantação.
