# Regras de Negócio e Domínios — Optical Manager

## Domínios Principais e Regras

### 1. Clientes e Contatos
- **Contatos**: Entidade polimórfica associada a Clientes e Fornecedores. Tipos: `MOBILE`, `PHONE`, `EMAIL`, `WHATSAPP`.
- **Principal**: Cada tipo pode ter um contato marcado como principal. O `WHATSAPP` principal é usado para notificações automáticas.
- **Isolamento**: Email é único **por tenant**, não globalmente.

### 2. Receita Médica
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

---

## Ordem de Serviço (OS)

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

---

## Vendas e Financeiro

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
