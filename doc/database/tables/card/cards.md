# Documentação: Tabela `card.cards`

## Visão Geral

| Atributo       | Valor                          |
|----------------|--------------------------------|
| **Aplicação**  | NovoCard                       |
| **Schema**     | card                           |
| **Objeto**     | cards                          |
| **Tipo**       | Estrutura de Dados (Tabela)    |

A tabela `card.cards` é a estrutura central para o registro de cartões emitidos. Cada registro representa um cartão único — físico ou virtual — pertencente a um cliente. A tabela gerencia todo o ciclo de vida do cartão, desde a emissão até o cancelamento, passando por ativação, bloqueios e expiração.

Os números de cartão (PAN) são armazenados em formato mascarado (ex.: `4111 **** **** 1234`), em conformidade com o padrão **PCI-DSS**. O PAN completo é mantido exclusivamente em um cofre seguro externo.

---

## Estrutura de Colunas

### Identificação e Relacionamentos

| Coluna         | Tipo               | Nulável | Descrição                                                                 |
|----------------|--------------------|---------|---------------------------------------------------------------------------|
| cardid         | UNIQUEIDENTIFIER   | Não     | Identificador único do cartão (PK, gerado automaticamente via `NEWID()`) |
| customerid     | UNIQUEIDENTIFIER   | Não     | Referência ao cliente proprietário (`customer.customers`)                 |
| cardtypeid     | INT                | Não     | Tipo do cartão (`card.cardtypes`)                                         |
| designid       | UNIQUEIDENTIFIER   | Sim     | Design visual do cartão, atribuído após seleção                           |

### Dados do Cartão (PCI-DSS)

| Coluna          | Tipo           | Nulável | Descrição                                                        |
|-----------------|----------------|---------|------------------------------------------------------------------|
| maskedpan       | NVARCHAR(19)   | Não     | Número do cartão em formato mascarado                            |
| cardholdername  | NVARCHAR(100)  | Não     | Nome impresso no cartão                                          |
| expirymonth     | SMALLINT       | Não     | Mês de expiração (1–12)                                          |
| expiryyear      | SMALLINT       | Não     | Ano de expiração (> 2020)                                        |
| lastfourdigits  | Computada      | —       | Últimos 4 dígitos do PAN (persistida, derivada de `maskedpan`)   |
| expiresat       | Computada      | —       | Data de expiração como DATETIMEOFFSET (1º dia do mês, UTC)       |

### Formato e Capacidades

| Coluna           | Tipo          | Padrão     | Descrição                                                    |
|------------------|---------------|------------|--------------------------------------------------------------|
| cardformat       | NVARCHAR(10)  | PHYSICAL   | Formato do cartão: PHYSICAL, VIRTUAL ou BOTH                 |
| iscontactless    | BIT           | 1 (Sim)    | Habilitado para pagamento por aproximação                    |
| isonlineenabled  | BIT           | 1 (Sim)    | Habilitado para compras online                               |
| isinternational  | BIT           | 0 (Não)    | Habilitado para uso internacional                            |

### Ciclo de Vida

| Coluna              | Tipo              | Descrição                                              |
|---------------------|-------------------|--------------------------------------------------------|
| status              | NVARCHAR(30)      | Estado atual do cartão (ver tabela de status abaixo)   |
| issuedat            | DATETIMEOFFSET    | Data/hora de emissão                                   |
| activatedat         | DATETIMEOFFSET    | Data/hora de ativação                                  |
| lastusedat          | DATETIMEOFFSET    | Data/hora do último uso registrado                     |
| cancelledat         | DATETIMEOFFSET    | Data/hora do cancelamento                              |
| cancellationreason  | NVARCHAR(255)     | Motivo do cancelamento                                 |
| createdat           | DATETIMEOFFSET    | Data/hora de criação do registro                       |
| updatedat           | DATETIMEOFFSET    | Data/hora da última atualização do registro            |

---

## Status do Cartão

| Status              | Descrição                                                    |
|---------------------|--------------------------------------------------------------|
| PENDINGACTIVATION   | Cartão emitido, aguardando ativação pelo cliente             |
| ACTIVE              | Cartão ativo e disponível para uso                           |
| BLOCKEDTEMPORARY    | Bloqueio temporário iniciado pelo cliente                    |
| BLOCKEDFRAUD        | Bloqueio por suspeita de fraude (sistema ou analista)        |
| EXPIRED             | Cartão expirado                                              |
| CANCELLED           | Cartão cancelado definitivamente                             |
| LOST                | Cartão reportado como perdido                                |
| STOLEN              | Cartão reportado como roubado                                |

---

## Índices

| Índice                    | Coluna(s)        | Observação                              |
|---------------------------|------------------|-----------------------------------------|
| pkcards (PK)             | cardid           | Chave primária clustered                |
| idxcardscustomerid       | customerid       | Busca por cliente                       |
| idxcardscardtypeid       | cardtypeid       | Busca por tipo de cartão               |
| idxcardsstatus           | status           | Filtro por estado do ciclo de vida      |
| idxcardslastfour         | lastfourdigits   | Busca pelos últimos 4 dígitos           |
| idxcardsexpiresat        | expiresat        | Consultas de expiração                  |
| idxcardsissuedat         | issuedat (DESC)  | Consultas por data de emissão recente   |

---

## Relacionamentos (Chaves Estrangeiras)

| Constraint            | Tabela Referenciada       | Coluna Referenciada |
|-----------------------|---------------------------|---------------------|
| fkcardscustomer       | customer.customers        | customerid          |
| fkcardscardtype       | card.cardtypes            | cardtypeid          |

---

## Regras de Negócio (Constraints)

| Constraint              | Regra                                                                 |
|-------------------------|-----------------------------------------------------------------------|
| chkcardsexpirymonth     | Mês de expiração entre 1 e 12                                         |
| chkcardsexpiryyear      | Ano de expiração superior a 2020                                      |
| chkcardsformat          | Formato deve ser PHYSICAL, VIRTUAL ou BOTH                            |
| chkcardsstatus          | Status restrito aos 8 valores válidos do ciclo de vida                |

---

## Insights

- **Conformidade PCI-DSS**: A arquitetura separa o PAN mascarado (armazenado na tabela) do PAN completo (mantido em cofre seguro externo), reduzindo o escopo de auditoria PCI.
- **Cartões Virtuais e Físicos**: O campo `cardformat` com a opção `BOTH` permite que um mesmo registro represente um cartão físico com sua contraparte digital vinculada, suportando estratégias de digitalização.
- **Controle Granular de Uso**: Os flags `iscontactless`, `isonlineenabled` e `isinternational` permitem configuração individual por cartão, viabilizando políticas de segurança personalizadas pelo cliente ou pela instituição.
- **Ciclo de Vida Completo**: A distinção entre `BLOCKEDTEMPORARY` (ação do cliente) e `BLOCKEDFRAUD` (ação do sistema/analista) permite rastreabilidade clara da origem do bloqueio para fins regulatórios e de atendimento.
- **Criação Condicional**: O script verifica a existência prévia da tabela antes de criá-la, garantindo idempotência na execução em ambientes de deploy contínuo.
- **Colunas Computadas Persistidas**: `lastfourdigits` e `expiresat` são calculadas e armazenadas fisicamente, otimizando consultas frequentes sem custo de recálculo em tempo de leitura.
- **Índice Descendente em `issuedat`**: Otimizado para consultas que buscam os cartões emitidos mais recentemente, cenário comum em dashboards operacionais e de atendimento.
