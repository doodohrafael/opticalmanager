# Regras de Negócio e Domínios — Optical Manager

### 1. Clientes e Contatos
- **Contatos**: Entidade polimórfica associada a Clientes e Fornecedores. Tipos: `MOBILE`, `PHONE`, `EMAIL`, `WHATSAPP`.
- **Principal**: Cada tipo pode ter um contato marcado como principal. O `WHATSAPP` principal é usado para notificações automáticas.
- **Isolamento**: Email é único **por tenant**, não globalmente.

---

## 2. Cadastro do Tenant e Trial

### Cadastro em Duas Fases
1. **Fase 1 (Auto-cadastro)**: `trade_name`, `responsible_name`, `responsible_phone`, `email`, senha. Acesso bloqueado até confirmação de email.
2. **Fase 2 (Onboarding)**: `company_name`, `cnpj`, `responsible_cpf`, `logo`.
- **Email Único**: O email é a identidade global (login + faturamento).
- **Responsible Phone**: Sempre o WhatsApp do dono da ótica.

### Trial e Assinatura
- **Trial**: 14 dias grátis, sem cartão. Alertas nos dias 12 e 13. Bloqueio no dia 14.
- **Assinatura**: Obrigatória para uso após trial. `responsible_cpf` é mandatório para integração com Mercado Pago.
- **Plano Free**: Inexistente. O modelo é focado em SaaS de baixo custo (R$ 149/mês).

---

## 3. Receita Médica

- **Eixo (Axis)**: Deve estar entre 0 e 180 (validado no Value Object).
- **Adição**: Usada apenas para lentes bifocais ou progressivas.
- **Origem**: `DOCTOR` (Médico), `OPTICIAN` (Optometrista) ou `CLIENT_INFORMED` (Informado pelo cliente). No caso de `CLIENT_INFORMED`, o campo de observação é obrigatório.
- **Tipos**: `GLASSES` (Óculos) ou `CONTACT_LENS` (Lente de Contato).

### 3. Produtos e Estoque

#### Armações (Frame)
- **Estrutura**: O estoque é controlado por `FrameSku` (variação de cor e tamanho), não pelo modelo base.
- **Reserva**: Ao abrir uma OS, o produto é **reservado** (`quantity_reserved`).
- **Baixa**: A baixa definitiva ocorre apenas no status `DELIVERED`.
- **Cancelamento**: Se a OS for cancelada, a reserva é liberada automaticamente.

#### Lentes Oftálmicas (LensType)
- **Natureza**: Catálogo de opções sob demanda, **sem estoque físico**.
- **Precificação**:
  - `FIXED`: Preço único.
  - `GRADE_RANGE`: Preço varia conforme a faixa de grau da receita.

#### Lentes de Contato (ContactLens)
- **Controle**: Produto físico com estoque e validade (lote).
- **Modo de Venda**:
  - **PAR (Padrão)**: Estoque contado em pares.
  - **UNIDADE**: Habilitável por tenant. Ao habilitar, o sistema converte automaticamente `quantidade * 2`.
- **Tipos**: `GLASSES` (Óculos) ou `CONTACT_LENS` (Lente de Contato).

### 4. Numeração Sequencial por Tenant
- **Campos**: `service_order.number`, `sale.number`, `purchase_order.number`.
- **Lógica**: Cada ótica começa do número 1. Calculado no `INSERT` via: `MAX(number) + 1` filtrado pelo `tenant_id`.

---

## 5. Ordem de Serviço (OS) e Vendas

### Máquina de Estados (Fluxo Configurável)
O tenant escolhe o momento do pagamento:

**A. PAYMENT_BEFORE_PRODUCTION (Padrão):**
`OPEN → AWAITING_PAYMENT → IN_PRODUCTION → READY → DELIVERED`

**B. PAYMENT_BEFORE_DELIVERY:**
`OPEN → IN_PRODUCTION → READY → AWAITING_PAYMENT → DELIVERED`

**Estados Especiais:**
- `AWAITING_REWORK`: Quando há defeito detectado no laboratório (pode vir de `IN_PRODUCTION` ou `READY`).
- `CANCELLED`: Pode ser atingido de qualquer estado (exceto finais).
- **Imutabilidade**: Estados `DELIVERED` e `CANCELLED` são finais e nunca podem ser alterados.

### Pagamento Parcial (Entrada Mínima)
- `minimum_down_payment_percent`: Configurável por tenant (Padrão: 0.50).
- **Avanço**: A OS avança automaticamente para `IN_PRODUCTION` quando `total_paid >= total_net * percent`.

---

## 6. Produtos e Estoque

### Lógica de Movimentação
- `quantity = quantity_available + quantity_reserved`
- **RESERVATION**: Reservado ao abrir a OS.
- **SALE_EXIT**: Baixa definitiva ao entregar a OS (`DELIVERED`).
- **CANCELLATION**: Libera reserva ao cancelar OS.
- **ENTRY**: Entrada automática ao receber pedido de compra.

### Lentes de Contato (PAR vs UNIDADE)
- **PAIR (Padrão)**: 1 venda par = -1 estoque.
- **UNIT**: 1 venda par = -2 estoque.
- **Conversão**: Ao trocar para `UNIT`, o sistema converte a quantidade atual (`quantidade * 2`).

### Pedido de Compra
- **Fluxo**: `DRAFT → SENT → RECEIVED | CANCELLED`.
- **Recebimento**: Status `RECEIVED` dispara movimentações de `ENTRY` no estoque automaticamente.

---

## 7. Filiais e Fiscal (CNPJ)
- **Branch CNPJ**: Cada filial pode ter seu próprio CNPJ. Se for `NULL`, utiliza-se o CNPJ do `Tenant` (matriz).
- **Fase 2**: Obrigatório preencher CNPJ da filial para habilitar emissão de NF-e por estabelecimento.

---

## 8. Vendas e Financeiro

### Venda Domiciliar (PWA)
- Vendedor utiliza o sistema via celular.
- Abre OS normalmente; o sistema gera um **Comprovante PDF** com QR Code para rastreio e dados da ótica.

### Pagamentos e Caixa
- **Caixa**: Apenas um caixa aberto por vez por filial/tenant.
- **Imutabilidade**: Uma vez fechado, o caixa é imutável para fins de auditoria.
- **Lançamentos**: Toda venda confirmada gera um lançamento automático no caixa via evento.
- **Formas**: `CASH`, `PIX`, `CREDIT_CARD`, `DEBIT_CARD`.
- **PIX**: Gerado via QR Code na tela através da integração com Mercado Pago.

---

## AI — Spring AI
- **Leitura de Receita**: Backend envia foto para AI (Claude/Gemini) e recebe JSON estruturado.
- **Confirmação Humana**: A AI apenas sugere; o vendedor **sempre** deve validar e confirmar os graus antes de salvar.
- **Alerta de Vencimento**: Job diário (8h) que notifica clientes com receitas vencendo em 30 dias.
