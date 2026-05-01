# Migration V7 — Create Financial

## Visão Geral
Esta migration implementa a gestão financeira básica, focada no controle de frente de caixa (PDV) e fluxo de caixa diário.

- **Módulo**: `financial`
- **Tabelas**: `cash_register`, `transaction`
- **Objetivo**: Controlar o fluxo de dinheiro (entradas e saídas) por filial, garantindo o fechamento de caixa auditável.

---

## Convenções Adotadas
- **Caixa Único**: Apenas um caixa pode estar aberto por filial em um determinado momento (garantido via índice único parcial).
- **Categorização**: Transações são classificadas como Receita (`REVENUE`) ou Despesa (`EXPENSE`).
- **Vínculo com Vendas**: Receitas do tipo `SALE` são geradas automaticamente e obrigatoriamente vinculadas a uma venda (`sale_id`).
- **Integridade de Fechamento**: O fechamento do caixa exige data, usuário responsável e saldo final preenchidos simultaneamente.

---

## Tabelas Criadas

### 1. `cash_register`
Representa uma sessão de abertura e fechamento de caixa.
- **Campos Principais**:
  - `opening_balance`: Valor físico contado na abertura da gaveta.
  - `closing_balance`: Valor físico contado no fechamento.
  - `opened_at` / `closed_at`: Período de vigência do caixa.

### 2. `transaction`
Registro individual de entrada ou saída de valores.
- **Campos Principais**:
  - `type`: `REVENUE` ou `EXPENSE`.
  - `category`: Origem/Destino do valor (`SALE`, `RENT`, `SALARY`, `LAB`, `SUPPLIER`, `TAX`, `OTHER`).
  - `amount`: Valor da transação (sempre positivo).
- **Automação**: Transações da categoria `SALE` são criadas pelo sistema no momento da confirmação de pagamento de uma venda.

---

## Índices e Constraints
- **Unicidade**: `idx_cash_register_one_open` garante que não existam dois caixas abertos simultaneamente na mesma filial.
- **Checks**:
  - `chk_cash_register_closed`: Garante consistência nos dados de fechamento.
  - `chk_transaction_sale_ref`: Obriga o vínculo com `sale_id` apenas para transações da categoria `SALE`.
- **Índices**: 
  - Otimizados para buscas por tenant, filial e data da transação.
  - Índice parcial para localizar rapidamente transações vinculadas a vendas.
