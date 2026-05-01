# Migration V5 — Create Stock

## Visão Geral
Esta migration implementa o controle de estoque físico, movimentações auditáveis e o processo de compras (pedidos de compra).

- **Módulo**: `stock`
- **Tabelas**: `stock_item`, `stock_movement`, `purchase_order`, `purchase_order_item`
- **Objetivo**: Garantir a integridade do inventário e o rastreio de entradas e saídas.

---

## Convenções Adotadas
- **Invariante de Estoque**: `quantidade_total = quantidade_disponivel + quantidade_reservada`.
- **Movimentações Imutáveis**: A tabela `stock_movement` serve como um log de auditoria; registros nunca são editados ou excluídos.
- **Numeração de Pedidos**: O campo `number` em `purchase_order` é sequencial por tenant, começando em 1 para cada ótica.
- **Reserva Automática**: Abertura de ordens de serviço reserva o estoque, enquanto a entrega efetiva a saída.

---

## Tabelas Criadas

### 1. `stock_item`
Saldo atual de um produto em uma filial específica.
- **Campos Principais**:
  - `quantity`: Quantidade física total.
  - `quantity_reserved`: Quantidade vinculada a ordens de serviço abertas.
  - `minimum_quantity`: Gatilho para alertas de estoque baixo.
- **Regra**: `quantity >= quantity_reserved` (não é possível reservar mais do que o total físico).

### 2. `stock_movement`
Histórico detalhado de movimentações.
- **Tipos**: `ENTRY` (Compra), `RESERVATION` (Reserva OS), `SALE_EXIT` (Venda), `CANCELLATION` (Estorno), `ADJUSTMENT` (Ajuste Manual).
- **Referência**: Armazena o UUID do documento que gerou a movimentação (OS ou Pedido de Compra).

### 3. `purchase_order`
Cabeçalho do pedido de compra junto ao fornecedor.
- **Estados**: `DRAFT` (Rascunho) → `SENT` (Enviado) → `RECEIVED` (Recebido) ou `CANCELLED` (Cancelado).
- **Entrada Automática**: Quando o status muda para `RECEIVED`, o sistema gera automaticamente as movimentações de `ENTRY` no estoque.

### 4. `purchase_order_item`
Itens incluídos no pedido de compra.
- **Campos Principais**:
  - `total_cost`: Campo calculado (`quantity * unit_cost`) e armazenado fisicamente (`STORED`) para performance em relatórios.

---

## Índices e Constraints
- **Unicidade**: (branch_id, product_type, product_id) na `stock_item`.
- **Checks**:
  - Tipos de produto permitidos no estoque (Frame SKU, Contact Lens).
  - Quantidades não podem ser negativas.
- **Índices**: 
  - Otimização para busca de itens com estoque baixo.
  - Filtros por tenant, filial e status do pedido.
