

# Documentação: Catálogo de Tipos de Cartão — `card.cardtypes`

## Visão Geral

Estrutura de dados pertencente à aplicação **NovoCard** que representa o catálogo de produtos de cartão oferecidos pela instituição. Cada registro define uma combinação única de **classe de produto** (Crédito, Débito ou Pré-pago), **bandeira de pagamento** e **nível (tier)**, determinando o comportamento do cartão, suas taxas e limites padrão.

---

## Estrutura de Dados

### Tabela: `card.cardtypes`

| Coluna | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `cardtypeid` | INT (Identity) | Sim | Identificador único do tipo de cartão (chave primária, autoincremento) |
| `typename` | NVARCHAR(50) | Sim | Nome único do tipo de cartão |
| `productclass` | NVARCHAR(10) | Sim | Classe do produto: **CREDIT**, **DEBIT** ou **PREPAID** |
| `network` | NVARCHAR(20) | Sim | Bandeira de pagamento: **VISA**, **MASTERCARD**, **ELO**, **AMEX** ou **HIPERCARD** |
| `tier` | NVARCHAR(20) | Sim | Nível do cartão: **STANDARD**, **GOLD**, **PLATINUM**, **BLACK** ou **INFINITE**. Padrão: STANDARD |
| `annualfee` | DECIMAL(10,2) | Sim | Anuidade cobrada pelo cartão. Padrão: 0.00 |
| `minimumincome` | DECIMAL(12,2) | Não | Renda mínima exigida para elegibilidade |
| `minimumcreditscore` | SMALLINT | Não | Score de crédito interno mínimo para emissão (faixa de 0 a 1000). Nulo indica sem restrição |
| `description` | NVARCHAR(MAX) | Não | Descrição textual do produto |
| `benefits` | NVARCHAR(MAX) | Não | Array JSON contendo a lista de benefícios do cartão |
| `isactive` | BIT | Sim | Indica se o tipo de cartão está ativo para comercialização. Padrão: 1 (ativo) |
| `createdat` | DATETIMEOFFSET | Sim | Data/hora de criação do registro (preenchido automaticamente) |
| `updatedat` | DATETIMEOFFSET | Sim | Data/hora da última atualização do registro (preenchido automaticamente) |

### Restrições e Regras

| Restrição | Tipo | Descrição |
|---|---|---|
| `pk_cardtypes` | Primary Key | Garante unicidade do `cardtypeid` |
| `uq_cardtypes_name` | Unique | Impede duplicidade de nomes de tipo de cartão |
| `chk_cardtypes_class` | Check | Restringe `productclass` a CREDIT, DEBIT ou PREPAID |
| `chk_cardtypes_network` | Check | Restringe `network` às bandeiras homologadas |
| `chk_cardtypes_tier` | Check | Restringe `tier` aos níveis definidos pela instituição |
| `chk_cardtypes_minscore` | Check | Valida que o score mínimo esteja entre 0 e 1000 |

---

## Dados Iniciais (Seed)

A tabela é populada com **8 produtos de cartão** que compõem o portfólio inicial da NovoCard:

### Cartões de Débito

| Nome | Bandeira | Tier | Anuidade | Descrição |
|---|---|---|---|---|
| NOVOCARD_DEBIT_STANDARD | Mastercard | Standard | R$ 0,00 | Cartão de débito padrão vinculado à conta corrente |

### Cartões de Crédito

| Nome | Bandeira | Tier | Anuidade | Descrição |
|---|---|---|---|---|
| NOVOCARD_CREDIT_STANDARD | Visa | Standard | R$ 149,90 | Cartão de crédito de entrada para novos clientes |
| NOVOCARD_CREDIT_GOLD | Mastercard | Gold | R$ 299,90 | Cartão Gold com benefícios de viagem |
| NOVOCARD_CREDIT_PLATINUM | Visa | Platinum | R$ 599,90 | Cartão Platinum com concierge e acesso a salas VIP |
| NOVOCARD_CREDIT_BLACK | Mastercard | Black | R$ 0,00 | Cartão Black exclusivo por convite, com benefícios ilimitados |

### Cartões Pré-pagos

| Nome | Bandeira | Tier | Anuidade | Descrição |
|---|---|---|---|---|
| NOVOCARD_PREPAID_GIFT | Elo | Standard | R$ 0,00 | Cartão pré-pago presente de uso único |
| NOVOCARD_PREPAID_TRAVEL | Visa | Standard | R$ 19,90 | Cartão pré-pago recarregável multimoeda para viagens |
| NOVOCARD_PREPAID_CORPORATE | Mastercard | Standard | R$ 0,00 | Cartão pré-pago corporativo gerenciado pelo empregador |

---

## Insights

- **Criação condicional**: A tabela só é criada se ainda não existir no banco, garantindo segurança em execuções repetidas (idempotência).
- **Estratégia de isenção de anuidade**: Os cartões Black (crédito), Débito Standard, Gift e Corporate possuem anuidade zero, indicando que a monetização desses produtos ocorre por outros mecanismos (interchange, convite exclusivo, taxas corporativas).
- **Diversificação de bandeiras**: O portfólio distribui os produtos entre Visa, Mastercard e Elo, sem utilizar Amex ou Hipercard nos produtos iniciais — embora ambas estejam homologadas como bandeiras válidas.
- **Campos de elegibilidade opcionais**: `minimumincome` e `minimumcreditscore` não são preenchidos na carga inicial, sugerindo que as regras de elegibilidade serão configuradas posteriormente ou gerenciadas por outro módulo.
- **Benefícios em JSON**: O campo `benefits` permite flexibilidade na definição de benefícios por produto sem necessidade de tabelas auxiliares, mas exige atenção na validação pela camada de aplicação.
- **Tiers não utilizados**: O nível **INFINITE** está previsto na regra de validação, mas nenhum produto inicial o utiliza, indicando possível expansão futura do portfólio.
- **Auditoria temporal**: Os campos `createdat` e `updatedat` utilizam `DATETIMEOFFSET`, garantindo rastreabilidade com fuso horário — essencial para operações multi-região.
