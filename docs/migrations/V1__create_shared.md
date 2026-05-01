# Migration V1 — Create Shared

## Visão Geral
Esta migration inicial cria o alicerce do sistema multi-tenant, definindo as entidades que gerenciam a conta do cliente 
(Tenant), suas unidades físicas (Branch) e suas configurações personalizadas (Tenant Setting).

- **Módulo**: `shared`
- **Tabelas**: `tenant`, `branch`, `tenant_setting`
- **Objetivo**: Implementar o isolamento de dados, a identidade comercial e as configurações globais de comportamento do sistema.

---

## Convenções Adotadas
### Padrões de Nomenclatura
- **Nomes Singulares**: Tabelas nomeadas no singular para alinhamento com entidades JPA.
- **FKs**: `fk_{tabela_origem}_{coluna_fk}`
- **Checks**: `chk_{tabela}_{regra}`
- **Unicidade**: `uq_{tabela}_{coluna}`
- **Índices**: `idx_{tabela}_{coluna}`

### Design das Entidades
- **Tenant**:
  - `trade_name` vs `company_name`: Distinção entre nome comercial (recibos) e razão social (fiscal).
  - `responsible_*`: Dados de contato direto do dono da ótica para suporte e cobrança.
  - `email`: Chave de identidade global (login e comunicação).
- **Branch**:
  - **Value Object**: O endereço é embutido diretamente na tabela (`@Embeddable` no JPA). 
  - Não existe uma tabela de endereços separada; o endereço da filial não possui identidade própria e vive/morre com a filial.

---

## Tabelas Criadas

### 1. `tenant`
Registro completo do cliente SaaS (dono da ótica).
- **Campos Principais**:
  - `trade_name`: Nome comercial exibido em recibos e etiquetas.
  - `email`: Único globalmente, usado para login e comunicação.
  - `plan`: PRO (MVP - R$149/mês) ou MAX (Fase 2).
  - `trial_active` & `trial_expires_at`: Controle do período gratuito de 14 dias.
  - `subscription_active` & `mp_subscription_id`: Integração com Mercado Pago.
  - `active`: Flag mestre de acesso.
- **Regras**: Criada durante o auto-cadastro do cliente.

### 2. `branch`
Unidades físicas (filiais) da ótica. O endereço é embutido diretamente (Value Object @Embeddable).
- **Campos Principais**:
  - `tenant_id`: FK para isolamento.
  - `cnpj`: Pode ser diferente do CNPJ do Tenant (importante para NF-e por estabelecimento).
  - `zip_code`, `street`, etc.: Dados de localização.
  - `active`: Permite desativar uma filial.
- **MVP**: Cada tenant nasce com uma filial padrão. Multi-filial exige `branches_enabled = true`.

### 3. `tenant_setting`
Configurações de comportamento de negócio por tenant. Exatamente uma linha por tenant.
- **Financeiro**: `payment_flow` (`BEFORE_PRODUCTION` ou `BEFORE_DELIVERY`).
- **Vendas**: `minimum_down_payment_percent` (Padrão: 50%) e `quote_expiration_days`.
- **Estoque**: `contact_lens_stock_unit` (`PAIR` ou `UNIT`) e `allow_single_lens_sale`.
- **Alertas**: `prescription_expiry_alert_days` (Padrão: 30 dias).
- **NF-e**: `nfe_enabled` e token de API (Fase 2).

---

## Índices e Constraints
- **Unicidade**: Email e CNPJ no `tenant`.
- **FKs**: 
  - `branch -> tenant`
  - `tenant_setting -> tenant` (com Unique constraint para garantir 1:1).
- **Checks**:
  - `chk_tenant_plan`: PRO, MAX.
  - `chk_tenant_setting_flow`: BEFORE_PRODUCTION, BEFORE_DELIVERY.
  - `chk_tenant_setting_lens_unit`: PAIR, UNIT.
  - `chk_tenant_setting_down_pmt`: Entre 0.00 e 1.00.
- **Índices**:
  - `idx_tenant_email`
  - `idx_tenant_cnpj` (filtrado para não-nulos).
  - `idx_branch_tenant_id`

---

## Comentários
As tabelas e colunas foram comentadas extensivamente no banco de dados (via `COMMENT ON`) para facilitar a manutenção e futuras análises via ferramentas de BI.
