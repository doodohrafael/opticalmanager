-- =================================================================
-- V7__create_financial.sql
--
-- Module: financial
-- Tables: cash_register, transaction
-- =================================================================

-- ── cash_register ─────────────────────────────────────────────────
CREATE TABLE cash_register (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID          NOT NULL,
    branch_id       UUID          NOT NULL,
    opened_by       UUID          NOT NULL,
    closed_by       UUID,
    opening_balance NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    closing_balance NUMERIC(10,2),
    opened_at       TIMESTAMP     NOT NULL DEFAULT NOW(),
    closed_at       TIMESTAMP,

    CONSTRAINT fk_cash_register_tenant_id   FOREIGN KEY (tenant_id) REFERENCES tenant(id),
    CONSTRAINT fk_cash_register_branch_id   FOREIGN KEY (branch_id) REFERENCES branch(id),
    CONSTRAINT fk_cash_register_opened_by   FOREIGN KEY (opened_by) REFERENCES app_user(id),
    CONSTRAINT fk_cash_register_closed_by   FOREIGN KEY (closed_by) REFERENCES app_user(id),
    CONSTRAINT chk_cash_register_balance    CHECK (opening_balance >= 0),
    CONSTRAINT chk_cash_register_closed     CHECK (
        (closed_at IS NULL AND closed_by IS NULL AND closing_balance IS NULL) OR
        (closed_at IS NOT NULL AND closed_by IS NOT NULL AND closing_balance IS NOT NULL)
    )
);

COMMENT ON COLUMN cash_register.opening_balance
    IS 'Cash physically counted in drawer when register was opened.';
COMMENT ON COLUMN cash_register.closing_balance
    IS 'Cash counted on close. Expected = opening + revenues - expenses.';

-- Only one open register per branch at a time — database-level guarantee.
CREATE UNIQUE INDEX idx_cash_register_one_open
    ON cash_register(branch_id)
    WHERE closed_at IS NULL;

CREATE INDEX idx_cash_register_tenant_id  ON cash_register(tenant_id);
CREATE INDEX idx_cash_register_branch_id  ON cash_register(branch_id);
CREATE INDEX idx_cash_register_opened_at  ON cash_register(opened_at);

-- ── transaction ───────────────────────────────────────────────────
CREATE TABLE transaction (
    id               UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id        UUID          NOT NULL,
    cash_register_id UUID          NOT NULL,
    sale_id          UUID,
    created_by       UUID          NOT NULL,
    type             VARCHAR(7)    NOT NULL,
    category         VARCHAR(10)   NOT NULL,
    amount           NUMERIC(10,2) NOT NULL,
    description      VARCHAR(200)  NOT NULL,
    at               TIMESTAMP     NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_transaction_tenant_id        FOREIGN KEY (tenant_id)        REFERENCES tenant(id),
    CONSTRAINT fk_transaction_cash_register_id FOREIGN KEY (cash_register_id) REFERENCES cash_register(id),
    CONSTRAINT fk_transaction_sale_id          FOREIGN KEY (sale_id)          REFERENCES sale(id),
    CONSTRAINT fk_transaction_created_by       FOREIGN KEY (created_by)       REFERENCES app_user(id),
    CONSTRAINT chk_transaction_type            CHECK (type IN ('REVENUE', 'EXPENSE')),
    CONSTRAINT chk_transaction_amount          CHECK (amount > 0),
    CONSTRAINT chk_transaction_category        CHECK (
        category IN ('SALE', 'RENT', 'SALARY', 'LAB', 'SUPPLIER', 'TAX', 'OTHER')
    ),
    CONSTRAINT chk_transaction_sale_ref CHECK (
        (category = 'SALE' AND sale_id IS NOT NULL) OR
        (category != 'SALE' AND sale_id IS NULL)
    )
);

COMMENT ON COLUMN transaction.type
    IS 'REVENUE: money in. EXPENSE: money out.';
COMMENT ON COLUMN transaction.category
    IS 'SALE: auto-created on sale confirmation. Others: manual (OWNER/MANAGER only).';

CREATE INDEX idx_transaction_tenant_id        ON transaction(tenant_id);
CREATE INDEX idx_transaction_cash_register_id ON transaction(cash_register_id);
CREATE INDEX idx_transaction_type             ON transaction(type);
CREATE INDEX idx_transaction_category         ON transaction(category);
CREATE INDEX idx_transaction_at               ON transaction(at);
CREATE INDEX idx_transaction_sale_id          ON transaction(sale_id) WHERE sale_id IS NOT NULL;
