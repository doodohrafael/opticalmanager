# Migration V6 — Create Sales

## Visão Geral
Esta migration define o coração operacional do sistema: o fluxo de Ordens de Serviço (OS), Vendas e Pagamentos.

- **Módulo**: `sales`
- **Tabelas**: `service_order`, `service_order_history`, `sale`, `sale_item`, `payment`
- **Objetivo**: Gerenciar o ciclo de vida completo de uma venda, desde o orçamento e produção laboratorial até a entrega e liquidação financeira.

---

## Convenções Adotadas
- **Máquina de Estados (OS)**: A OS percorre estados como `OPEN` → `AWAITING_PAYMENT` → `IN_PRODUCTION` → `READY` → `DELIVERED`.
- **Snapshots de Endereço**: Para entregas em domicílio, os dados do endereço são copiados para a venda no momento da confirmação. Isso garante a integridade histórica mesmo que o cliente altere seu cadastro posteriormente.
- **Snapshots de Preço**: Preços de armações e lentes são fixados no item da venda (`sale_item`) no momento do fechamento.
- **Numeração Sequencial**: OS e Vendas possuem numeração sequencial por tenant (ex: cada ótica começa na OS 1).

---

## Tabelas Criadas

### 1. `service_order`
Documento técnico da venda (foco na produção e laboratório).
- **Campos Principais**:
  - `status`: Controla o fluxo de produção.
  - `estimated_at`: Data prevista para entrega ao cliente.
  - `prescription_id`: Vínculo opcional com a receita (obrigatório se não for informado verbalmente).

### 2. `service_order_history`
Log de auditoria imutável das mudanças de status da OS.
- **Uso**: Rastreia quem mudou o status e quando.

### 3. `sale`
Documento comercial e financeiro da transação.
- **Campos Principais**:
  - `total_gross`, `discount`, `total_net`: Valores financeiros.
  - `payment_status`: `PENDING`, `PARTIAL` ou `PAID`.
  - Campos de entrega (`is_home_delivery` e endereço).

### 4. `sale_item`
Vínculo entre a Venda e a Ordem de Serviço.
- **Estrutura**: Define se o item é um óculos (`GLASSES`) — exigindo armação e lente — ou lente de contato (`CONTACT_LENS`).

### 5. `payment`
Registros de pagamentos vinculados a uma venda.
- **Métodos**: `CASH`, `PIX`, `CREDIT_CARD`, `DEBIT_CARD`, `DIGITAL_PAYMENT_LINK`.
- **Mercado Pago**: Campos para QR Code PIX e status de processamento digital.

---

## Índices e Constraints
- **Unicidade**: Numeração sequencial (`number`) única por tenant nas tabelas `sale` e `service_order`.
- **Checks**:
  - Validação de estados da máquina de estados.
  - `total_net` deve ser sempre `total_gross - discount`.
  - Obrigatoriedade de dados de endereço se `is_home_delivery` for verdadeiro.
- **Índices**: 
  - Filtros por status de venda e OS.
  - Buscas por vendedor, cliente e data de criação.
