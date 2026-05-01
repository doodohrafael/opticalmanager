-- =================================================================
-- V6__create_sales.sql
--
-- Module: sales
-- Tables: service_order, service_order_history, sale, sale_item, payment
--
-- number (service_order and sale): sequential per tenant.
--   Each optical store starts at 1 — calculated by application on INSERT.
--
-- Home delivery (sale):
--   is_home_delivery: true when order is delivered to client address
--   client_address_id: FK to client_address (nullable — set to NULL if deleted)
--   delivery_*: snapshot copied from client_address at sale confirmation
--               IMMUTABLE — preserved even if client changes or deletes address
--
-- ServiceOrder state machine:
--   OPEN → AWAITING_PAYMENT → IN_PRODUCTION → READY → DELIVERED
--                           ↘ AWAITING_REWORK ↗
--   Any non-final → CANCELLED
--   Finals (immutable): DELIVERED, CANCELLED
-- =================================================================

-- ── service_order ─────────────────────────────────────────────────
CREATE TABLE service_order (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID        NOT NULL,
    branch_id           UUID        NOT NULL,
    client_id           UUID        NOT NULL,
    vendor_id           UUID        NOT NULL,
    prescription_id     UUID,
    number              INTEGER     NOT NULL,
    prescription_origin VARCHAR(16) NOT NULL,
    status              VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    observation         VARCHAR(500),
    estimated_at        DATE,
    created_at          TIMESTAMP   NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP   NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_service_order_tenant_id       FOREIGN KEY (tenant_id)       REFERENCES tenant(id),
    CONSTRAINT fk_service_order_branch_id       FOREIGN KEY (branch_id)       REFERENCES branch(id),
    CONSTRAINT fk_service_order_client_id       FOREIGN KEY (client_id)       REFERENCES client(id),
    CONSTRAINT fk_service_order_vendor_id       FOREIGN KEY (vendor_id)       REFERENCES app_user(id),
    CONSTRAINT fk_service_order_prescription_id FOREIGN KEY (prescription_id) REFERENCES prescription(id),
    CONSTRAINT uq_service_order_number          UNIQUE (tenant_id, number),
    CONSTRAINT chk_service_order_status CHECK (
        status IN (
            'OPEN', 'AWAITING_PAYMENT', 'IN_PRODUCTION',
            'AWAITING_REWORK', 'READY', 'DELIVERED', 'CANCELLED'
        )
    ),
    CONSTRAINT chk_service_order_origin CHECK (
        prescription_origin IN ('DOCTOR', 'OPTICIAN', 'CLIENT_INFORMED')
    ),
    CONSTRAINT chk_service_order_client_informed CHECK (
        prescription_origin != 'CLIENT_INFORMED' OR prescription_id IS NULL
    )
);

COMMENT ON COLUMN service_order.number
    IS 'Sequential per tenant. Each optical store starts at 1. e.g. "OS 42".';
COMMENT ON COLUMN service_order.status
    IS 'State machine. DELIVERED and CANCELLED are terminal — no further transitions allowed.';
COMMENT ON COLUMN service_order.estimated_at
    IS 'Estimated delivery date. Printed on the OS label sent to the lab.';

CREATE INDEX idx_service_order_tenant_id  ON service_order(tenant_id);
CREATE INDEX idx_service_order_branch_id  ON service_order(branch_id);
CREATE INDEX idx_service_order_client_id  ON service_order(client_id);
CREATE INDEX idx_service_order_vendor_id  ON service_order(vendor_id);
CREATE INDEX idx_service_order_status     ON service_order(status);
CREATE INDEX idx_service_order_created_at ON service_order(created_at);

-- ── service_order_history ─────────────────────────────────────────
-- Immutable audit trail. Never updated or deleted.
CREATE TABLE service_order_history (
    id               UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    service_order_id UUID         NOT NULL,
    changed_by       UUID         NOT NULL,
    status           VARCHAR(20)  NOT NULL,
    observation      VARCHAR(300),
    at               TIMESTAMP    NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_service_order_history_order_id  FOREIGN KEY (service_order_id) REFERENCES service_order(id),
    CONSTRAINT fk_service_order_history_changed_by FOREIGN KEY (changed_by)      REFERENCES app_user(id),
    CONSTRAINT chk_service_order_history_status CHECK (
        status IN (
            'OPEN', 'AWAITING_PAYMENT', 'IN_PRODUCTION',
            'AWAITING_REWORK', 'READY', 'DELIVERED', 'CANCELLED'
        )
    )
);

COMMENT ON TABLE service_order_history
    IS 'Immutable status transition log. Full audit trail — never deleted.';

CREATE INDEX idx_service_order_history_order_id ON service_order_history(service_order_id);
CREATE INDEX idx_service_order_history_at       ON service_order_history(at);

-- ── sale ──────────────────────────────────────────────────────────
-- delivery_* fields: snapshot copied from client_address at sale confirmation.
--   Immutable — never changed after sale is confirmed.
--   NULL when is_home_delivery = false (store pickup).
--
-- client_address_id: informative reference only — NOT a foreign key.
--   Stores the UUID of the address used, allowing the application to know
--   "this address still exists in client's profile" vs "already deleted".
--   No REFERENCES constraint — if client deletes the address, this UUID
--   simply becomes an orphan reference. The delivery_* snapshot is what
--   guarantees the historical record, not this field.
CREATE TABLE sale (
    id             UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id      UUID          NOT NULL,
    branch_id      UUID          NOT NULL,
    client_id      UUID          NOT NULL,
    vendor_id      UUID          NOT NULL,
    number         INTEGER       NOT NULL,
    status         VARCHAR(10)   NOT NULL DEFAULT 'QUOTE',
    payment_status VARCHAR(8)    NOT NULL DEFAULT 'PENDING',
    total_gross    NUMERIC(10,2) NOT NULL,
    discount       NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    total_net      NUMERIC(10,2) NOT NULL,
    total_paid     NUMERIC(10,2) NOT NULL DEFAULT 0.00,

    -- Home delivery
    is_home_delivery       BOOLEAN      NOT NULL DEFAULT FALSE,
    client_address_id      UUID,                  -- informative only, no FK constraint
    delivery_zip_code      CHAR(8),
    delivery_street        VARCHAR(150),
    delivery_street_number VARCHAR(10),
    delivery_complement    VARCHAR(60),
    delivery_neighborhood  VARCHAR(80),
    delivery_city          VARCHAR(80),
    delivery_state         CHAR(2),
    delivery_reference     VARCHAR(150),

    created_at     TIMESTAMP     NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMP     NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_sale_tenant_id       FOREIGN KEY (tenant_id) REFERENCES tenant(id),
    CONSTRAINT fk_sale_branch_id       FOREIGN KEY (branch_id) REFERENCES branch(id),
    CONSTRAINT fk_sale_client_id       FOREIGN KEY (client_id) REFERENCES client(id),
    CONSTRAINT fk_sale_vendor_id       FOREIGN KEY (vendor_id) REFERENCES app_user(id),
    CONSTRAINT uq_sale_number          UNIQUE (tenant_id, number),
    CONSTRAINT chk_sale_status         CHECK (status IN ('QUOTE', 'CONFIRMED', 'PAID', 'RETURNED', 'CANCELLED')),
    CONSTRAINT chk_sale_payment_status CHECK (payment_status IN ('PENDING', 'PARTIAL', 'PAID')),
    CONSTRAINT chk_sale_discount       CHECK (discount >= 0),
    CONSTRAINT chk_sale_total_net      CHECK (total_net = total_gross - discount),
    CONSTRAINT chk_sale_total_paid     CHECK (total_paid >= 0),
    -- Snapshot must be filled when is_home_delivery = true
    CONSTRAINT chk_sale_delivery_snapshot CHECK (
        is_home_delivery = FALSE OR (
            delivery_zip_code IS NOT NULL AND
            delivery_street   IS NOT NULL AND
            delivery_city     IS NOT NULL AND
            delivery_state    IS NOT NULL
        )
    )
);

COMMENT ON COLUMN sale.number
    IS 'Sequential per tenant. Each optical store starts at 1. e.g. "Venda 15".';
COMMENT ON COLUMN sale.payment_status
    IS 'PENDING: no payment. PARTIAL: down payment received. PAID: fully settled.';
COMMENT ON COLUMN sale.total_net
    IS 'total_gross - discount. Enforced by CHECK constraint.';
COMMENT ON COLUMN sale.total_paid
    IS 'Running sum of confirmed payments. Updated on each payment insert.';
COMMENT ON COLUMN sale.client_address_id
    IS 'Informative reference to the address chosen at sale time. No FK constraint — '
       'if client deletes the address this UUID becomes an orphan, but delivery_* snapshot preserves all data.';
COMMENT ON COLUMN sale.delivery_zip_code
    IS 'Snapshot copied from client_address at sale confirmation. Immutable — never changes after confirmation.';
COMMENT ON COLUMN sale.delivery_reference
    IS 'Landmark near the delivery address. e.g. "Próximo ao mercado Bom Preço".';

CREATE INDEX idx_sale_tenant_id   ON sale(tenant_id);
CREATE INDEX idx_sale_branch_id   ON sale(branch_id);
CREATE INDEX idx_sale_client_id   ON sale(client_id);
CREATE INDEX idx_sale_vendor_id   ON sale(vendor_id);
CREATE INDEX idx_sale_status      ON sale(status);
CREATE INDEX idx_sale_created_at  ON sale(created_at);
CREATE INDEX idx_sale_delivery    ON sale(tenant_id) WHERE is_home_delivery = TRUE;

-- ── sale_item ─────────────────────────────────────────────────────
-- One row per service order in the sale.
-- Prices are snapshots at sale time — preserved even if product prices change.
CREATE TABLE sale_item (
    id                 UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_id            UUID          NOT NULL,
    service_order_id   UUID          NOT NULL,
    item_type          VARCHAR(13)   NOT NULL,
    frame_sku_id       UUID,
    lens_type_id       UUID,
    contact_lens_id    UUID,
    quantity           SMALLINT      NOT NULL DEFAULT 1,
    frame_price        NUMERIC(10,2),
    lens_price         NUMERIC(10,2),
    contact_lens_price NUMERIC(10,2),

    CONSTRAINT fk_sale_item_sale_id          FOREIGN KEY (sale_id)          REFERENCES sale(id),
    CONSTRAINT fk_sale_item_service_order_id FOREIGN KEY (service_order_id) REFERENCES service_order(id),
    CONSTRAINT fk_sale_item_frame_sku_id     FOREIGN KEY (frame_sku_id)     REFERENCES frame_sku(id),
    CONSTRAINT fk_sale_item_lens_type_id     FOREIGN KEY (lens_type_id)     REFERENCES lens_type(id),
    CONSTRAINT fk_sale_item_contact_lens_id  FOREIGN KEY (contact_lens_id)  REFERENCES contact_lens(id),
    CONSTRAINT uq_sale_item_service_order_id UNIQUE (service_order_id),
    CONSTRAINT chk_sale_item_type            CHECK (item_type IN ('GLASSES', 'CONTACT_LENS')),
    CONSTRAINT chk_sale_item_glasses         CHECK (
        item_type != 'GLASSES' OR (frame_sku_id IS NOT NULL AND lens_type_id IS NOT NULL)
    ),
    CONSTRAINT chk_sale_item_contact_lens    CHECK (
        item_type != 'CONTACT_LENS' OR contact_lens_id IS NOT NULL
    )
);

COMMENT ON COLUMN sale_item.frame_price
    IS 'Snapshot at sale time. Preserved even if frame_sku price changes later.';
COMMENT ON COLUMN sale_item.quantity
    IS 'Number of pairs for CONTACT_LENS. Always 1 for GLASSES.';

CREATE INDEX idx_sale_item_sale_id          ON sale_item(sale_id);
CREATE INDEX idx_sale_item_frame_sku_id     ON sale_item(frame_sku_id)    WHERE frame_sku_id IS NOT NULL;
CREATE INDEX idx_sale_item_contact_lens_id  ON sale_item(contact_lens_id) WHERE contact_lens_id IS NOT NULL;

-- ── payment ───────────────────────────────────────────────────────
-- Multiple payments per sale (partial payments + split methods).
CREATE TABLE payment (
    id           UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_id      UUID          NOT NULL,
    method       VARCHAR(21)   NOT NULL,
    amount       NUMERIC(10,2) NOT NULL,
    installments SMALLINT      NOT NULL DEFAULT 1,
    pix_qr_code  TEXT,
    pix_status   VARCHAR(8),
    paid_at      TIMESTAMP,
    created_at   TIMESTAMP     NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_payment_sale_id     FOREIGN KEY (sale_id) REFERENCES sale(id),
    CONSTRAINT chk_payment_method     CHECK (
        method IN ('CASH', 'PIX', 'CREDIT_CARD', 'DEBIT_CARD', 'DIGITAL_PAYMENT_LINK')
    ),
    CONSTRAINT chk_payment_amount       CHECK (amount > 0),
    CONSTRAINT chk_payment_installments CHECK (installments >= 1),
    CONSTRAINT chk_payment_pix_status   CHECK (
        pix_status IS NULL OR pix_status IN ('PENDING', 'PAID', 'EXPIRED')
    )
);

COMMENT ON COLUMN payment.method
    IS 'DIGITAL_PAYMENT_LINK: Mercado Pago link (boleto digital or PIX via link).';
COMMENT ON COLUMN payment.pix_qr_code
    IS 'QR Code string from Mercado Pago API. NULL for non-PIX methods.';
COMMENT ON COLUMN payment.paid_at
    IS 'Set by Mercado Pago webhook or manual vendor confirmation.';

CREATE INDEX idx_payment_sale_id ON payment(sale_id);
CREATE INDEX idx_payment_method  ON payment(method);
