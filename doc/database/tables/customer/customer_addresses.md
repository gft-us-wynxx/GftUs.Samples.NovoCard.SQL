# Documentação: customer.customeraddresses

## Aplicação
**NovoCard**

## Visão Geral

Estrutura de dados responsável por armazenar os endereços postais e de cobrança associados a cada cliente. Um cliente pode possuir múltiplos endereços cadastrados, sendo que exatamente um deve estar marcado como **primário** (endereço principal de contato/entrega) e um como **endereço de cobrança** (utilizado para envio de faturas do cartão e correspondências de billing).

## Tipo

**Estrutura de Dados** (Tabela)

## Esquema e Objeto

| Esquema | Tabela |
|---|---|
| `customer` | `customeraddresses` |

## Estrutura de Colunas

| Coluna | Tipo de Dado | Obrigatório | Valor Padrão | Descrição |
|---|---|---|---|---|
| `addressid` | UNIQUEIDENTIFIER | Sim | `NEWID()` | Identificador único do endereço (chave primária) |
| `customerid` | UNIQUEIDENTIFIER | Sim | — | Identificador do cliente proprietário do endereço |
| `addresstype` | NVARCHAR(20) | Sim | — | Tipo do endereço: Residencial, Cobrança, Comercial ou Outro |
| `street` | NVARCHAR(255) | Sim | — | Logradouro |
| `number` | NVARCHAR(20) | Sim | — | Número do endereço |
| `complement` | NVARCHAR(100) | Não | — | Complemento (apartamento, bloco, sala, etc.) |
| `neighborhood` | NVARCHAR(100) | Não | — | Bairro |
| `city` | NVARCHAR(100) | Sim | — | Cidade |
| `state` | NCHAR(2) | Sim | — | Unidade federativa (sigla com 2 caracteres) |
| `zipcode` | NVARCHAR(10) | Sim | — | Código postal (CEP) |
| `country` | NCHAR(2) | Sim | `'BR'` | Código do país (padrão ISO, default Brasil) |
| `isprimary` | BIT | Sim | `0` | Indica se é o endereço principal de contato/entrega do cliente |
| `isbilling` | BIT | Sim | `0` | Indica se é o endereço utilizado para envio de fatura e correspondência de cobrança |
| `verifiedat` | DATETIMEOFFSET | Não | — | Data/hora em que o endereço foi confirmado via verificação postal ou envio de documento |
| `createdat` | DATETIMEOFFSET | Sim | `SYSDATETIMEOFFSET()` | Data/hora de criação do registro |
| `updatedat` | DATETIMEOFFSET | Sim | `SYSDATETIMEOFFSET()` | Data/hora da última atualização do registro |

## Valores Permitidos para Tipo de Endereço

| Valor | Significado |
|---|---|
| `RESIDENTIAL` | Endereço residencial |
| `BILLING` | Endereço de cobrança |
| `COMMERCIAL` | Endereço comercial |
| `OTHER` | Outro tipo de endereço |

## Relacionamentos

| Tipo | Tabela Referenciada | Coluna Local | Coluna Referenciada | Comportamento de Exclusão |
|---|---|---|---|---|
| Chave Estrangeira | `customer.customers` | `customerid` | `customerid` | Exclusão em cascata (ao remover o cliente, todos os seus endereços são removidos automaticamente) |

## Restrições (Constraints)

| Nome | Tipo | Descrição |
|---|---|---|
| `pk_customeraddresses` | Primary Key | Garante unicidade do `addressid` |
| `fk_addresses_customer` | Foreign Key | Vincula o endereço a um cliente existente |
| `chk_addresstype` | Check | Restringe os valores de `addresstype` aos quatro tipos permitidos |

## Índices

| Nome do Índice | Coluna(s) | Finalidade |
|---|---|---|
| `idx_addresses_customerid` | `customerid` | Otimiza consultas de endereços por cliente |
| `idx_addresses_type` | `addresstype` | Otimiza filtros por tipo de endereço |
| `idx_addresses_zipcode` | `zipcode` | Otimiza buscas por CEP |

## Insights

- A tabela é criada de forma condicional (somente se ainda não existir), garantindo segurança em execuções repetidas do script de deploy.
- O uso de `UNIQUEIDENTIFIER` com `NEWID()` como chave primária indica uma arquitetura preparada para ambientes distribuídos, onde a geração de IDs não depende de sequências centralizadas.
- O país padrão é **Brasil (`BR`)**, indicando que a aplicação NovoCard tem foco no mercado brasileiro, mas suporta endereços internacionais.
- A exclusão em cascata (`ON DELETE CASCADE`) na chave estrangeira significa que a remoção de um cliente automaticamente elimina todos os seus endereços, simplificando a gestão do ciclo de vida dos dados.
- A regra de negócio de que apenas **um endereço deve ser primário** e **um deve ser de cobrança** por cliente **não é imposta a nível de banco de dados** — não há índice único filtrado ou trigger para garantir essa restrição. Essa validação precisa ser controlada pela camada de aplicação.
- O campo `verifiedat` indica a existência de um processo de verificação de endereço (via correspondência postal ou upload de documento comprobatório), relevante para compliance e prevenção a fraudes no contexto de cartões.
- Não há mecanismo automático de atualização do campo `updatedat` (como um trigger); a aplicação deve gerenciar essa atualização a cada modificação do registro.
