# Migration V4 — Create Products

## Visão Geral
Esta migration define o catálogo de produtos, incluindo armações (frames), lentes oftálmicas e lentes de contato, além da gestão de fornecedores.

- **Módulo**: `products`
- **Tabelas**: `supplier`, `frame`, `frame_sku`, `lens_type`, `lens_grade_range`, `contact_lens`
- **Objetivo**: Estruturar o catálogo de itens comercializados e seus respectivos fornecedores.

---

## Convenções Adotadas
- **Endereço de Fornecedor**: Embutido como *Value Object* (`@Embeddable`), seguindo o padrão das filiais.
- **Armações vs SKUs**: O modelo separa o conceito do produto (`frame` - marca/modelo) da sua variação física estocável (`frame_sku` - cor/tamanho).
- **Lentes Oftálmicas**: Tratadas como serviço sob demanda (não possuem estoque físico), com precificação fixa ou baseada em faixas de grau.
- **Lentes de Contato**: Tratadas como produto físico com estoque, categorizadas por tipo de descarte e graduação.

---

## Tabelas Criadas

### 1. `supplier`
Cadastro de fornecedores de armações e lentes.
- **Campos Principais**:
  - `name`: Nome da empresa.
  - `contact_name`: Nome do representante/contato principal.
  - Endereço completo embutido.

### 2. `frame`
Produto conceitual (Marca + Modelo).
- **Relacionamento**: Vinculado a um fornecedor.

### 3. `frame_sku`
Variação comercial da armação (cor, tamanho, preço).
- **Estoque**: É nesta tabela que o estoque físico é controlado.

### 4. `lens_type`
Catálogo de lentes de óculos (resina, policarbonato, tratamentos).
- **Precificação**: Pode ser `FIXED` (preço único) ou `GRADE_RANGE` (preço varia conforme o grau).

### 5. `lens_grade_range`
Tabela de preços por faixa de grau para lentes oftálmicas.
- **Uso**: Aplicado apenas quando o `pricing_model` da lente é `GRADE_RANGE`.

### 6. `contact_lens`
Catálogo de lentes de contato.
- **Campos Principais**:
  - `usage_type`: Diário, quinzenal ou mensal.
  - `grade`: Grau esférico da lente.
  - `units_per_box`: Quantidade de lentes na caixa.

---

## Índices e Constraints
- **Checks**:
  - Tipos de lente (Monofocal, Bifocal, Progressiva).
  - Materiais e tratamentos permitidos.
  - Tipos de descarte de lentes de contato.
- **Índices**: Buscas otimizadas por marca, modelo, fornecedor e tenant.
