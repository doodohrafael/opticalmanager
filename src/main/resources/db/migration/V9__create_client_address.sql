-- =================================================================
-- V9__create_client_address.sql
--
-- Module: clients (Phase 2 — home delivery)
-- Tables: client_address
--
-- client_address has its own identity because:
--   1. A client can have N addresses (home, work, family...)
--   2. Each sale references WHICH address was used
--   3. Client may delete an address after a sale — sale must preserve data
--
-- The sale table references client_address_id (nullable, ON DELETE SET NULL)
-- AND stores a delivery_* snapshot for permanent historical record.
-- The snapshot is what guarantees immutability — not the FK.
-- =================================================================

CREATE TABLE client_address (
    id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id     UUID         NOT NULL,
    client_id     UUID         NOT NULL,

    -- Label chosen by vendor or client for identification
    label         VARCHAR(60)  NOT NULL DEFAULT 'Principal',

    -- Address fields
    zip_code      CHAR(8)      NOT NULL,
    street        VARCHAR(150) NOT NULL,
    street_number VARCHAR(10)  NOT NULL,
    complement    VARCHAR(60),
    neighborhood  VARCHAR(80)  NOT NULL,
    city          VARCHAR(80)  NOT NULL,
    state         CHAR(2)      NOT NULL,
    reference     VARCHAR(150),

    is_default    BOOLEAN      NOT NULL DEFAULT FALSE,
    active        BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMP    NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_client_address_tenant_id FOREIGN KEY (tenant_id) REFERENCES tenant(id),
    CONSTRAINT fk_client_address_client_id FOREIGN KEY (client_id) REFERENCES client(id),
    CONSTRAINT chk_client_address_state    CHECK (LENGTH(state) = 2)
);

COMMENT ON TABLE  client_address           IS 'Delivery addresses per client. Multiple allowed. One is_default per client.';
COMMENT ON COLUMN client_address.label     IS 'Human-friendly label. e.g. "Casa", "Trabalho", "Mãe".';
COMMENT ON COLUMN client_address.reference IS 'Landmark near the address. e.g. "Próximo ao mercado Bom Preço".';
COMMENT ON COLUMN client_address.is_default IS 'One default per client — enforced at application layer.';
COMMENT ON COLUMN client_address.active    IS 'Soft delete — inactive addresses hidden from selection but preserved in sale history.';

CREATE INDEX idx_client_address_tenant_id ON client_address(tenant_id);
CREATE INDEX idx_client_address_client_id ON client_address(client_id);
CREATE INDEX idx_client_address_default   ON client_address(client_id)
    WHERE is_default = TRUE AND active = TRUE;
