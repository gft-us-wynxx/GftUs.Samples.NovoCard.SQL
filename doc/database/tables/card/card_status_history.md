# Documentação — `card.cardstatushistory`

## Visão Geral

| Atributo       | Detalhe                                                                                                                                                  |
|----------------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Aplicação**  | NovoCard                                                                                                                                                 |
| **Schema**     | `card`                                                                                                                                                   |
| **Objeto**     | `cardstatushistory`                                                                                                                                      |
| **Tipo**       | Estrutura de dados (tabela)                                                                                                                              |
| **Finalidade** | Registro imutável (ledger) de todas as transições de status de cartão. Cada mudança de status gera um novo registro, garantindo rastreabilidade completa. |

Esta tabela é utilizada principalmente para **relatórios de conformidade (compliance)** e **investigações de disputas de clientes**, permitindo reconstruir o histórico completo de estados pelos quais um cartão passou.

---

## Estrutura de Dados

### Colunas

| Coluna           | Tipo                  | Nulável | Descrição                                                                                      |
|------------------|-----------------------|---------|------------------------------------------------------------------------------------------------|
| `historyid`      | `BIGINT IDENTITY`     | Não     | Identificador sequencial único do registro de histórico (chave primária).                      |
| `cardid`         | `UNIQUEIDENTIFIER`    | Não     | Referência ao cartão na tabela `card.cards`. Exclusão em cascata.                              |
| `previousstatus` | `NVARCHAR(30)`        | Não     | Status do cartão **antes** da transição.                                                       |
| `newstatus`      | `NVARCHAR(30)`        | Não     | Status do cartão **após** a transição.                                                         |
| `reason`         | `NVARCHAR(255)`       | Sim     | Motivo ou justificativa da mudança de status.                                                  |
| `initiatedby`    | `NVARCHAR(20)`        | Não     | Ator responsável pela mudança de status.                                                       |
| `operatorid`     | `NVARCHAR(100)`       | Sim     | Identificador interno do usuário operador (aplicável quando o ator é RISKANALYST ou SUPPORT).  |
| `channel`        | `NVARCHAR(20)`        | Sim     | Canal pelo qual a mudança de status foi solicitada.                                            |
| `ipaddress`      | `VARCHAR(45)`         | Sim     | Endereço IP de origem da solicitação (suporte a IPv4 e IPv6).                                  |
| `changedat`      | `DATETIMEOFFSET`      | Não     | Data e hora da mudança de status, com fuso horário. Padrão: momento atual do servidor.         |

### Valores Permitidos — `initiatedby`

| Valor          | Descrição                                      |
|----------------|-------------------------------------------------|
| `CUSTOMER`     | Mudança iniciada pelo próprio cliente.          |
| `SYSTEM`       | Mudança automática do sistema.                  |
| `RISKANALYST`  | Mudança realizada por um analista de risco.     |
| `FRAUDENGINE`  | Mudança disparada pelo motor automatizado de regras de fraude. |
| `SUPPORT`      | Mudança realizada pela equipe de suporte.       |

### Valores Permitidos — `channel`

| Valor    | Descrição                          |
|----------|------------------------------------|
| `APP`    | Aplicativo móvel                   |
| `WEB`    | Portal web                         |
| `IVR`    | Unidade de Resposta Audível (URA)  |
| `BRANCH` | Agência / ponto de atendimento    |
| `API`    | Integração via API                 |
| `BATCH`  | Processamento em lote              |

---

## Relacionamentos

| Tipo             | Tabela Referenciada | Coluna Local | Coluna Referenciada | Comportamento de Exclusão |
|------------------|---------------------|--------------|---------------------|---------------------------|
| Chave Estrangeira | `card.cards`       | `cardid`     | `cardid`            | `CASCADE`                 |

Ao excluir um cartão da tabela `card.cards`, todos os registros de histórico de status associados serão automaticamente removidos.

---

## Índices

| Nome                                    | Coluna(s)    | Ordenação  | Finalidade                                                        |
|-----------------------------------------|--------------|------------|-------------------------------------------------------------------|
| `pkcardstatushistory` (PK, clustered)   | `historyid`  | ASC        | Identificação única de cada registro.                             |
| `idxcardstatushistorycardid`            | `cardid`     | ASC        | Consultas rápidas de histórico por cartão.                        |
| `idxcardstatushistorychangedat`         | `changedat`  | DESC       | Consultas ordenadas cronologicamente (mais recentes primeiro).    |
| `idxcardstatushistorynewstatus`         | `newstatus`  | ASC        | Filtragem eficiente por status de destino (ex.: buscar todos os bloqueios por fraude). |

---

## Restrições (Constraints)

| Nome                          | Tipo    | Regra                                                                                      |
|-------------------------------|---------|--------------------------------------------------------------------------------------------|
| `pkcardstatushistory`         | PK      | `historyid` é único e não nulo.                                                            |
| `fkstatushistorycard`         | FK      | `cardid` deve existir em `card.cards`.                                                     |
| `chkstatushistoryinitiator`   | CHECK   | `initiatedby` restrito a: CUSTOMER, SYSTEM, RISKANALYST, FRAUDENGINE, SUPPORT.             |
| `chkstatushistorychannel`     | CHECK   | `channel` restrito a: APP, WEB, IVR, BRANCH, API, BATCH.                                  |

---

## Insights

- **Natureza imutável**: a tabela funciona como um log de auditoria — registros são apenas inseridos, nunca atualizados ou removidos diretamente (exceto pela cascata de exclusão do cartão pai).
- **Rastreabilidade completa**: a combinação de `initiatedby`, `operatorid`, `channel` e `ipaddress` permite identificar com precisão **quem**, **como** e **de onde** cada mudança de status foi originada, atendendo requisitos regulatórios e de auditoria.
- **Crescimento volumétrico**: por ser um modelo append-only vinculado a cada transição de status de cada cartão, esta tabela tende a crescer significativamente ao longo do tempo. O índice descendente em `changedat` favorece consultas que priorizam eventos mais recentes.
- **Suporte a automação e operação humana**: o campo `initiatedby` distingue claramente ações automatizadas (SYSTEM, FRAUDENGINE) de ações manuais (CUSTOMER, RISKANALYST, SUPPORT), facilitando análises de efetividade de regras automatizadas versus intervenções humanas.
- **Exclusão em cascata**: a remoção de um cartão elimina todo o seu histórico de transições, o que deve ser considerado em políticas de retenção de dados e conformidade regulatória — pode ser necessário arquivar os dados antes da exclusão.
- **Campo `reason` opcional**: nem todas as transições possuem justificativa textual, o que pode dificultar investigações retroativas caso o preenchimento não seja padronizado nas camadas de aplicação.
