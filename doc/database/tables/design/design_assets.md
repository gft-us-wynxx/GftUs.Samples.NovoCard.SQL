# design.designassets

## Descrição Geral

Tabela de registro de ativos digitais (assets) vinculados a templates de design de cartões na aplicação **NovoCard**. Cada template de cartão é composto por múltiplas camadas visuais (fundo, logotipo, ícone, holograma, etc.) armazenadas em object storage e referenciadas nesta estrutura com suas dimensões, formato, perfil de cor e papel na renderização.

---

## Estrutura de Dados

### Colunas

| Coluna | Tipo | Nulável | Padrão | Descrição |
|--------|------|---------|--------|-----------|
| assetid | UNIQUEIDENTIFIER | Não | NEWID() | Identificador único do ativo |
| templateid | UNIQUEIDENTIFIER | Não | — | Referência ao template de design ao qual o ativo pertence |
| assetname | NVARCHAR(100) | Não | — | Nome descritivo do ativo |
| assettype | NVARCHAR(30) | Não | — | Tipo/papel do ativo na composição visual |
| asseturl | NVARCHAR(500) | Não | — | URL de origem do arquivo no object storage |
| cdnurl | NVARCHAR(500) | Sim | — | URL de distribuição via CDN para entrega otimizada |
| fileformat | NVARCHAR(10) | Não | — | Formato do arquivo de imagem |
| widthpx | SMALLINT | Sim | — | Largura em pixels |
| heightpx | SMALLINT | Sim | — | Altura em pixels |
| filesizekb | INT | Sim | — | Tamanho do arquivo em kilobytes |
| dpi | SMALLINT | Não | 300 | Resolução em pontos por polegada |
| colorprofile | NVARCHAR(10) | Não | sRGB | Perfil de cor aplicado ao ativo |
| zorder | SMALLINT | Não | 0 | Ordem de empilhamento na renderização (valores maiores ficam acima) |
| isprintready | BIT | Não | 0 | Indica se o ativo passou na validação de qualidade pré-impressão |
| checksumsha256 | NCHAR(64) | Sim | — | Hash SHA-256 para verificação de integridade do arquivo |
| uploadedby | NVARCHAR(100) | Sim | — | Identificação do usuário que realizou o upload |
| createdat | DATETIMEOFFSET | Não | SYSDATETIMEOFFSET() | Data/hora de criação do registro |
| updatedat | DATETIMEOFFSET | Não | SYSDATETIMEOFFSET() | Data/hora da última atualização |

---

### Valores Permitidos

| Coluna | Valores Aceitos |
|--------|----------------|
| assettype | BACKGROUND, LOGO, ICON, OVERLAY, TEXTURE, SIGNATURESTRIP, CHIPAREA, HOLOGRAM |
| fileformat | PNG, SVG, JPEG, WEBP, PDF |
| colorprofile | sRGB, CMYK, P3 |

---

### Restrições e Relacionamentos

| Tipo | Nome | Detalhes |
|------|------|----------|
| Primary Key | pkdesignassets | assetid |
| Foreign Key | fkassetstemplate | templateid → design.designtemplates(templateid), com exclusão em cascata |
| Check | chkassettype | Restringe valores de assettype |
| Check | chkassetformat | Restringe valores de fileformat |
| Check | chkassetcolorprofile | Restringe valores de colorprofile |

---

### Índices

| Nome | Coluna | Finalidade |
|------|--------|-----------|
| idxdesignassetstemplateid | templateid | Otimiza consultas por template |
| idxdesignassetsassettype | assettype | Otimiza consultas por tipo de ativo |

---

## Regras de Negócio

| Regra | Descrição |
|-------|-----------|
| Resolução mínima para impressão | Cartões físicos exigem no mínimo 300 DPI |
| Validação pré-impressão | O campo `isprintready` só é marcado como verdadeiro após o ativo passar por validação de qualidade para impressão |
| Perfil de cor por canal | **sRGB** para cartões digitais/virtuais; **CMYK** para impressão física; **P3** para displays premium |
| Ordem de renderização | O campo `zorder` define a camada de exibição — valores maiores são renderizados sobre valores menores |
| Integridade de arquivo | O checksum SHA-256 permite verificar se o ativo não foi corrompido ou alterado após upload |
| Exclusão em cascata | Ao remover um template, todos os ativos associados são automaticamente excluídos |

---

## Insights

- A estrutura suporta composição visual em camadas, permitindo que um único template de cartão seja montado a partir de múltiplos ativos independentes, facilitando reutilização e personalização.
- A presença de `cdnurl` separada da `asseturl` indica uma arquitetura com camada de cache/distribuição para otimizar a entrega dos ativos em canais digitais.
- O suporte a múltiplos perfis de cor (sRGB, CMYK, P3) demonstra que a plataforma atende simultaneamente cartões virtuais e físicos, com possibilidade de variantes premium.
- Os tipos de ativo incluem elementos específicos de cartões de pagamento (CHIPAREA, SIGNATURESTRIP, HOLOGRAM), evidenciando conformidade com padrões visuais da indústria de meios de pagamento.
- A combinação de `checksumsha256` com `isprintready` sugere um fluxo de governança onde os ativos passam por validação automatizada antes de serem liberados para produção gráfica.
