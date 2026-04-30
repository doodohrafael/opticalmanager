-- =================================================================
-- V1__create_shared.sql
--
-- Module: shared
-- Tables: tenant, branch, tenant_setting
--
-- Conventions:
--   Singular table names — aligned with JPA entities
--   FK naming: fk_{table}_{column}
--   CHK naming: chk_{table}_{rule}
--   UQ naming: uq_{table}_{column}
--   IDX naming: idx_{table}_{column}
--
-- tenant:
--   Complete registration data for SaaS owner visibility.
--   trade_name  → commercial name shown to clients
--   company_name → legal name used in fiscal documents (NF-e future)
--   responsible_* → owner contact for support, billing, communication
--   email is unique globally — same as login, used for all communication
--
-- branch:
--   Address embedded directly (Value Object — @Embeddable in JPA).
--   No separate address table — branch address has no identity of its own.
-- =================================================================

-- ── tenant ────────────────────────────────────────────────────────
CREATE TABLE tenant (
    id                   UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    trade_name           VARCHAR(60)  NOT NULL,
    company_name         VARCHAR(100),
    cnpj                 CHAR(14),
    responsible_name     VARCHAR(100) NOT NULL,
    responsible_cpf      CHAR(11),
    responsible_phone    VARCHAR(20)  NOT NULL,
    email                VARCHAR(100) NOT NULL,
    logo_url             VARCHAR(500),
    plan                 VARCHAR(10)  NOT NULL DEFAULT 'PRO',
    branches_enabled     BOOLEAN      NOT NULL DEFAULT FALSE,
    trial_active         BOOLEAN      NOT NULL DEFAULT TRUE,
    trial_started_at     DATE         NOT NULL DEFAULT CURRENT_DATE,
    trial_expires_at     DATE         NOT NULL DEFAULT (CURRENT_DATE + INTERVAL '14 days'),
    subscription_active  BOOLEAN      NOT NULL DEFAULT FALSE,
    mp_subscription_id   VARCHAR(100),
    active               BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at           TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMP    NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_tenant_email        UNIQUE (email),
    CONSTRAINT uq_tenant_cnpj         UNIQUE (cnpj),
    CONSTRAINT chk_tenant_plan        CHECK (plan IN ('PRO', 'MAX'))
);

COMMENT ON TABLE  tenant                     IS 'One record per optical store (SaaS customer).';
COMMENT ON COLUMN tenant.trade_name          IS 'Commercial name shown to clients, on receipts and labels.';
COMMENT ON COLUMN tenant.company_name        IS 'Legal company name. Used in NF-e (Phase 2).';
COMMENT ON COLUMN tenant.responsible_name    IS 'Full name of the store owner.';
COMMENT ON COLUMN tenant.responsible_cpf     IS 'CPF of the responsible person. Required for Mercado Pago billing.';
COMMENT ON COLUMN tenant.responsible_phone   IS 'WhatsApp of the owner. Used for support and critical alerts.';
COMMENT ON COLUMN tenant.email               IS 'Unique globally. Used for login, billing, and all communication.';
COMMENT ON COLUMN tenant.logo_url            IS 'Cloudflare R2 URL. Shown on receipts and labels.';
COMMENT ON COLUMN tenant.plan                IS 'PRO: MVP plan (R$149/mo). MAX: Phase 2 plan.';
COMMENT ON COLUMN tenant.branches_enabled    IS 'Unlocks multi-branch feature. Pro 2 only.';
COMMENT ON COLUMN tenant.trial_active        IS 'True during the 14-day free trial.';
COMMENT ON COLUMN tenant.subscription_active IS 'True when Mercado Pago recurring subscription is active.';
COMMENT ON COLUMN tenant.mp_subscription_id  IS 'Mercado Pago subscription ID for webhook reconciliation.';
COMMENT ON COLUMN tenant.active              IS 'False = access fully blocked (trial expired or subscription cancelled).';

CREATE INDEX idx_tenant_email ON tenant(email);
CREATE INDEX idx_tenant_cnpj  ON tenant(cnpj) WHERE cnpj IS NOT NULL;

-- ── branch ────────────────────────────────────────────────────────
-- Auto-created on tenant registration (1 default branch, MVP).
-- Additional branches require branches_enabled = true (Pro 2 only).
--
-- Address is embedded as a Value Object (DDD @Embeddable pattern).
-- Branch address has no identity of its own — it lives and dies with the branch.
-- For delivery addresses (client-owned, multiple, historical) see V9.
CREATE TABLE branch (
    id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id     UUID         NOT NULL,
    name          VARCHAR(60)  NOT NULL,
    cnpj          CHAR(14),
    phone         VARCHAR(20),
    whatsapp      VARCHAR(20),
    email         VARCHAR(100),
    opening_hours VARCHAR(200),
    zip_code      CHAR(8),
    street        VARCHAR(150),
    street_number VARCHAR(10),
    complement    VARCHAR(60),
    neighborhood  VARCHAR(80),
    city          VARCHAR(80),
    state         CHAR(2),
    active        BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMP    NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_branch_tenant_id FOREIGN KEY (tenant_id) REFERENCES tenant(id),
    CONSTRAINT chk_branch_state    CHECK (state IS NULL OR LENGTH(state) = 2)
);

COMMENT ON TABLE  branch               IS 'Physical store locations. MVP: 1 per tenant. Pro 2: up to 3.';
COMMENT ON COLUMN branch.cnpj          IS 'CNPJ of this establishment. NULL if same as tenant CNPJ. Each branch may have its own for NF-e (Phase 2).';
COMMENT ON COLUMN branch.opening_hours IS 'Free text. e.g. "Seg-Sex 9h-18h, Sáb 9h-13h".';
COMMENT ON COLUMN branch.zip_code      IS 'Brazilian CEP — 8 digits, no dash.';
COMMENT ON COLUMN branch.state         IS 'Brazilian UF — 2 letters. e.g. SP, RJ, PE.';

CREATE INDEX idx_branch_tenant_id ON branch(tenant_id);

-- ── tenant_setting ────────────────────────────────────────────────
-- Exactly one row per tenant — created alongside the tenant.
-- All columns have safe defaults — customized by OWNER via UI.
CREATE TABLE tenant_setting (
    id                             UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id                      UUID         NOT NULL,
    payment_flow                   VARCHAR(25)  NOT NULL DEFAULT 'BEFORE_PRODUCTION',
    quote_expiration_days          SMALLINT     NOT NULL DEFAULT 7,
    minimum_down_payment_percent   NUMERIC(5,2) NOT NULL DEFAULT 0.50,
    contact_lens_stock_unit        VARCHAR(4)   NOT NULL DEFAULT 'PAIR',
    allow_single_lens_sale         BOOLEAN      NOT NULL DEFAULT FALSE,
    prescription_expiry_alert      BOOLEAN      NOT NULL DEFAULT TRUE,
    prescription_expiry_alert_days SMALLINT     NOT NULL DEFAULT 30,
    nfe_enabled                    BOOLEAN      NOT NULL DEFAULT FALSE,
    nfe_api_token                  VARCHAR(200),
    updated_at                     TIMESTAMP    NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_tenant_setting_tenant_id  FOREIGN KEY (tenant_id) REFERENCES tenant(id),
    CONSTRAINT uq_tenant_setting_tenant_id  UNIQUE (tenant_id),
    CONSTRAINT chk_tenant_setting_flow      CHECK (payment_flow IN ('BEFORE_PRODUCTION', 'BEFORE_DELIVERY')),
    CONSTRAINT chk_tenant_setting_lens_unit CHECK (contact_lens_stock_unit IN ('PAIR', 'UNIT')),
    CONSTRAINT chk_tenant_setting_down_pmt  CHECK (minimum_down_payment_percent BETWEEN 0.00 AND 1.00),
    CONSTRAINT chk_tenant_setting_quote     CHECK (quote_expiration_days > 0),
    CONSTRAINT chk_tenant_setting_expiry    CHECK (prescription_expiry_alert_days > 0)
);

COMMENT ON COLUMN tenant_setting.payment_flow
    IS 'BEFORE_PRODUCTION: pay first then produce (default). BEFORE_DELIVERY: produce first, pay on pickup.';
COMMENT ON COLUMN tenant_setting.minimum_down_payment_percent
    IS 'Fraction of total_net required before OS moves to IN_PRODUCTION. 0.50 = 50%.';
COMMENT ON COLUMN tenant_setting.contact_lens_stock_unit
    IS 'PAIR: 1 sale = -1 stock (default). UNIT: 1 pair sale = -2, 1 single lens = -1.';
COMMENT ON COLUMN tenant_setting.prescription_expiry_alert_days
    IS 'Days before expiry to send alert email. Default: 30.';
