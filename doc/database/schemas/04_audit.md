# Esquema de Auditoria — NovoCard

## Visão Geral

Este artefato define a estrutura de dados do esquema **audit**, responsável por centralizar a trilha de auditoria da aplicação **NovoCard**. Todas as mutações significativas realizadas nos esquemas de clientes, cartões e designs são registradas neste esquema, atendendo a requisitos de **conformidade regulatória**, **resolução de disputas** e **análise forense**.

---

## Estrutura de Dados

### Esquema `audit`

O esquema `audit` é criado de forma condicional (somente se ainda não existir), garantindo idempotência na execução do script.

---

### Tabela `audit.auditlog`

Registro imutável de todas as operações de **INSERT**, **UPDATE** e **DELETE** realizadas nas tabelas de negócio do NovoCard. Os valores anteriores e posteriores à alteração são armazenados em formato JSON, permitindo rastreabilidade completa das mudanças.

#### Colunas

| Coluna | Tipo | Nulável | Descrição |
|---|---|---|---|
| `logid` | `BIGINT IDENTITY(1,1)` | Não | Identificador único sequencial do registro de auditoria (chave primária) |
| `schemaname` | `NVARCHAR(63)` | Não | Nome do esquema da tabela afetada |
| `tablename` | `NVARCHAR(63)` | Não | Nome da tabela afetada |
| `operation` | `NVARCHAR(10)` | Não | Tipo da operação realizada (restrito a `INSERT`, `UPDATE` ou `DELETE`) |
| `recordid` | `NVARCHAR(100)` | Não | Chave primária do registro afetado, convertida para texto para compatibilidade entre tabelas |
| `oldvalues` | `NVARCHAR(MAX)` | Sim | Snapshot JSON dos valores **antes** da alteração |
| `newvalues` | `NVARCHAR(MAX)` | Sim | Snapshot JSON dos valores **após** a alteração |
| `changedby` | `NVARCHAR(100)` | Não | Usuário responsável pela alteração (padrão: usuário de sistema da sessão) |
| `changedat` | `DATETIMEOFFSET` | Não | Data e hora da alteração com fuso horário (padrão: momento atual) |
| `ipaddress` | `VARCHAR(45)` | Sim | Endereço IP de origem (suporte a IPv4 e IPv6) |
| `sessionid` | `NVARCHAR(100)` | Sim | Identificador da sessão que originou a alteração |

#### Restrições

| Tipo | Nome | Detalhe |
|---|---|---|
| Chave Primária | `pk_auditlog` | Coluna `logid` |
| Check | `chk_audit_operation` | `operation` deve ser `INSERT`, `UPDATE` ou `DELETE` |

#### Índices

| Nome | Colunas | Observação |
|---|---|---|
| `idx_auditlog_table` | `schemaname`, `tablename` | Otimiza consultas filtradas por tabela de origem |
| `idx_auditlog_record` | `recordid` | Otimiza buscas pelo registro específico afetado |
| `idx_auditlog_changedat` | `changedat DESC` | Otimiza consultas cronológicas (mais recentes primeiro) |
| `idx_auditlog_operation` | `operation` | Otimiza filtros por tipo de operação |

---

## Insights

- **Imutabilidade por design**: A tabela é projetada como um log somente de inserção (*append-only*). Não há mecanismos de atualização ou exclusão previstos, reforçando a integridade da trilha de auditoria.
- **Compatibilidade entre tabelas**: O uso de `NVARCHAR(100)` para `recordid` permite registrar chaves primárias de diferentes tipos (inteiros, GUIDs, compostas concatenadas) em uma única tabela centralizada.
- **Armazenamento JSON**: A escolha de `NVARCHAR(MAX)` com snapshots JSON para `oldvalues` e `newvalues` oferece flexibilidade para auditar tabelas com estruturas distintas sem necessidade de colunas específicas por entidade.
- **Rastreabilidade completa**: A combinação de `changedby`, `ipaddress` e `sessionid` permite identificar não apenas **quem** realizou a alteração, mas também **de onde** e em qual **contexto de sessão**.
- **Criação idempotente**: Tanto o esquema quanto a tabela utilizam verificações de existência prévia, permitindo que o script seja executado múltiplas vezes sem erros.
- **Cobertura transversal**: O esquema atende a múltiplos domínios da aplicação (clientes, cartões e designs), consolidando a auditoria em um único ponto de consulta.
- **Suporte a conformidade**: A estrutura é adequada para atender requisitos regulatórios como PCI-DSS e LGPD, que exigem rastreamento detalhado de acessos e alterações em dados sensíveis.
