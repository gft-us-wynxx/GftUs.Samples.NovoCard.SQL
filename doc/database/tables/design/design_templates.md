# design.designtemplates

## Descrição Geral

Catálogo mestre de templates de design de cartões gerenciado pela equipe de design do **NovoCard**. Os templates definem a estrutura visual base que os clientes podem personalizar. Cada template é versionado — novas versões não invalidam designs de cartões existentes que referenciam versões anteriores.

---

## Esquema e Localização

| Propriedade | Valor |
|---|---|
| **Aplicação** | NovoCard |
| **Schema** | `design` |
| **Tabela** | `designtemplates` |
| **Tipo** | Estrutura de Dados (Tabela) |

---

## Estrutura de Colunas

### Identificação e Versionamento

| Coluna | Tipo | Nulável | Default | Descrição |
|---|---|---|---|---|
| `templateid` | UNIQUEIDENTIFIER | Não | `NEWID()` | Identificador único do template (PK) |
| `templatename` | NVARCHAR(100) | Não | — | Nome técnico do template |
| `displayname` | NVARCHAR(100) | Não | — | Nome de exibição para o usuário |
| `version` | SMALLINT | Não | `1` | Número da versão do template |
| `description` | NVARCHAR(MAX) | Sim | — | Descrição detalhada do template |

### Compatibilidade

| Coluna | Tipo | Nulável | Default | Descrição |
|---|---|---|---|---|
| `compatibleproductclasses` | NVARCHAR(MAX) | Não | `CREDIT,DEBIT,PREPAID` | Classes de produto compatíveis (array JSON) |
| `compatiblenetworks` | NVARCHAR(MAX) | Não | `VISA,MASTERCARD,ELO,AMEX` | Bandeiras de rede compatíveis (array JSON) |

### Propriedades Visuais

| Coluna | Tipo | Nulável | Default | Descrição |
|---|---|---|---|---|
| `primarycolor` | NCHAR(7) | Sim | — | Cor primária em formato HEX (ex: `#1A2B3C`) |
| `secondarycolor` | NCHAR(7) | Sim | — | Cor secundária em formato HEX |
| `baseimageurl` | NVARCHAR(500) | Não | — | URL da imagem base do template |
| `thumbnailurl` | NVARCHAR(500) | Sim | — | URL da miniatura para pré-visualização |
| `isdarktheme` | BIT | Não | `0` | Indica se o template utiliza tema escuro |

### Metadados e Controle

| Coluna | Tipo | Nulável | Default | Descrição |
|---|---|---|---|---|
| `category` | NVARCHAR(50) | Sim | — | Categoria do template (valores restritos) |
| `tags` | NVARCHAR(MAX) | Sim | — | Tags de classificação (array JSON) |
| `isactive` | BIT | Não | `1` | Indica se o template está ativo para uso |
| `isdefault` | BIT | Não | `0` | Quando ativo, é atribuído automaticamente na emissão de cartão caso nenhum design seja selecionado |
| `downloadcount` | INT | Não | `0` | Contador acumulado de cartões que utilizaram este template |
| `createdby` | NVARCHAR(100) | Sim | — | Usuário responsável pela criação |
| `createdat` | DATETIMEOFFSET | Não | `SYSDATETIMEOFFSET()` | Data/hora de criação |
| `updatedat` | DATETIMEOFFSET | Não | `SYSDATETIMEOFFSET()` | Data/hora da última atualização |

---

## Categorias Permitidas

A coluna `category` é restrita aos seguintes valores por meio de constraint `CHECK`:

| Valor |
|---|
| CLASSIC |
| NATURE |
| SPORTS |
| ART |
| GRADIENT |
| PATTERN |
| CUSTOM |
| LIMITEDEDITION |

---

## Constraints

| Nome | Tipo | Detalhe |
|---|---|---|
| `pkdesigntemplates` | Primary Key | `templateid` |
| `uqtemplatenameversion` | Unique | Combinação `templatename` + `version` — garante unicidade por versão |
| `chktemplatecategory` | Check | Restringe `category` aos valores permitidos |

---

## Índices

| Nome | Coluna | Finalidade |
|---|---|---|
| `idxtemplatesactive` | `isactive` | Otimiza consultas filtrando templates ativos/inativos |
| `idxtemplatescategory` | `category` | Otimiza consultas por categoria de template |

---

## Insights

- **Versionamento sem quebra**: A combinação única de `templatename` + `version` permite que múltiplas versões de um mesmo template coexistam. Cartões já emitidos continuam referenciando a versão original, evitando impactos visuais retroativos.

- **Template padrão (`isdefault`)**: O mecanismo de template padrão automatiza o fluxo de emissão de cartões quando o cliente não faz uma escolha ativa de design. É importante garantir que apenas um template esteja marcado como padrão por vez (essa regra não é imposta pela estrutura da tabela e deve ser controlada pela aplicação).

- **Campos JSON para compatibilidade e tags**: As colunas `compatibleproductclasses`, `compatiblenetworks` e `tags` armazenam arrays JSON. Para consultas de filtragem, deve-se utilizar a função `OPENJSON` do SQL Server, o que oferece flexibilidade mas exige atenção ao desempenho em grandes volumes.

- **Ampla cobertura de bandeiras**: Por padrão, os templates são compatíveis com as quatro principais bandeiras (Visa, Mastercard, Elo e Amex) e os três tipos de produto (Crédito, Débito e Pré-pago), cobrindo a maioria dos cenários de emissão.

- **Métrica de popularidade**: O campo `downloadcount` funciona como indicador de popularidade/adoção de cada template, podendo ser utilizado para rankings, recomendações e decisões de descontinuação.

- **Criação condicional**: A tabela só é criada caso ainda não exista (`IF OBJECT_ID ... IS NULL`), garantindo segurança em execuções repetidas do script (idempotência).
