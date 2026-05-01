-- =================================================================
-- V5__create_stock.sql
--
-- Module: stock
-- Tables: stock_item, stock_movement, purchase_order, purchase_order_item
--
-- Stock invariant: quantity = quantity_available + quantity_reserved
--
-- purchase_order.number: sequential per tenant.
--   Each tenant's orders start at 1. Calculated on INSERT by application.
-- =================================================================

-- ── stock_item ────────────────────────────────────────────────────
CREATE TABLE stock_item (
    id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id         UUID        NOT NULL,
    branch_id         UUID        NOT NULL,
    product_type      VARCHAR(13) NOT NULL,
    product_id        UUID        NOT NULL,
    quantity          INTEGER     NOT NULL DEFAULT 0,
    quantity_reserved INTEGER     NOT NULL DEFAULT 0,
    minimum_quantity  INTEGER     NOT NULL DEFAULT 1,

    CONSTRAINT fk_stock_item_tenant_id FOREIGN KEY (tenant_id) REFERENCES tenant(id),
    CONSTRAINT fk_stock_item_branch_id FOREIGN KEY (branch_id) REFERENCES branch(id),
    CONSTRAINT uq_stock_item_product   UNIQUE (branch_id, product_type, product_id),
    CONSTRAINT chk_stock_item_type     CHECK (product_type IN ('FRAME_SKU', 'CONTACT_LENS')),
    CONSTRAINT chk_stock_item_qty      CHECK (quantity >= 0),
    CONSTRAINT chk_stock_item_reserved CHECK (quantity_reserved >= 0),
    CONSTRAINT chk_stock_item_available CHECK (quantity >= quantity_reserved),
    CONSTRAINT chk_stock_item_minimum  CHECK (minimum_quantity >= 0)
);

COMMENT ON COLUMN stock_item.quantity
    IS 'Total physical quantity. quantity_available = quantity - quantity_reserved.';
COMMENT ON COLUMN stock_item.quantity_reserved
    IS 'Reserved by open service orders. Released on cancellation.';
COMMENT ON COLUMN stock_item.minimum_quantity
    IS 'Alert threshold. Items at or below this appear in the low-stock report.';

CREATE INDEX idx_stock_item_tenant_id ON stock_item(tenant_id);
CREATE INDEX idx_stock_item_branch_id ON stock_item(branch_id);
CREATE INDEX idx_stock_item_product   ON stock_item(product_type, product_id);
CREATE INDEX idx_stock_item_low       ON stock_item(tenant_id, branch_id)
    WHERE quantity <= minimum_quantity;

-- ── stock_movement ────────────────────────────────────────────────
-- Immutable audit log. Never updated or deleted.
CREATE TABLE stock_movement (
    id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id     UUID         NOT NULL,
    stock_item_id UUID         NOT NULL,
    user_id       UUID         NOT NULL,
    type          VARCHAR(13)  NOT NULL,
    quantity      INTEGER      NOT NULL,
    reason        VARCHAR(150) NOT NULL,
    reference_id  UUID,
    at            TIMESTAMP    NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_stock_movement_tenant_id     FOREIGN KEY (tenant_id)     REFERENCES tenant(id),
    CONSTRAINT fk_stock_movement_stock_item_id FOREIGN KEY (stock_item_id) REFERENCES stock_item(id),
    CONSTRAINT fk_stock_movement_user_id       FOREIGN KEY (user_id)       REFERENCES app_user(id),
    CONSTRAINT chk_stock_movement_type     CHECK (
        type IN ('ENTRY', 'RESERVATION', 'SALE_EXIT', 'CANCELLATION', 'ADJUSTMENT')
    ),
    CONSTRAINT chk_stock_movement_quantity CHECK (quantity != 0)
);

COMMENT ON COLUMN stock_movement.type
    IS 'ENTRY: purchase received. RESERVATION: OS opened. SALE_EXIT: OS delivered. '
       'CANCELLATION: OS cancelled. ADJUSTMENT: manual (OWNER/MANAGER).';
COMMENT ON COLUMN stock_movement.reference_id
    IS 'UUID of the triggering document (service_order or purchase_order).';

CREATE INDEX idx_stock_movement_tenant_id ON stock_movement(tenant_id);
CREATE INDEX idx_stock_movement_item_id   ON stock_movement(stock_item_id);
CREATE INDEX idx_stock_movement_type      ON stock_movement(type);
CREATE INDEX idx_stock_movement_at        ON stock_movement(at);

-- ── purchase_order ────────────────────────────────────────────────
CREATE TABLE purchase_order (
    id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id    UUID         NOT NULL,
    branch_id    UUID         NOT NULL,
    supplier_id  UUID         NOT NULL,
    created_by   UUID         NOT NULL,
    number       INTEGER      NOT NULL,
    status       VARCHAR(10)  NOT NULL DEFAULT 'DRAFT',
    total_amount NUMERIC(10,2),
    notes        VARCHAR(300),
    ordered_at   TIMESTAMP,
    received_at  TIMESTAMP,
    created_at   TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMP    NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_purchase_order_tenant_id   FOREIGN KEY (tenant_id)   REFERENCES tenant(id),
    CONSTRAINT fk_purchase_order_branch_id   FOREIGN KEY (branch_id)   REFERENCES branch(id),
    CONSTRAINT fk_purchase_order_supplier_id FOREIGN KEY (supplier_id) REFERENCES supplier(id),
    CONSTRAINT fk_purchase_order_created_by  FOREIGN KEY (created_by)  REFERENCES app_user(id),
    CONSTRAINT uq_purchase_order_number      UNIQUE (tenant_id, number),
    CONSTRAINT chk_purchase_order_status     CHECK (status IN ('DRAFT', 'SENT', 'RECEIVED', 'CANCELLED')),
    CONSTRAINT chk_purchase_order_ordered_at CHECK (status = 'DRAFT' OR ordered_at IS NOT NULL),
    CONSTRAINT chk_purchase_order_received_at CHECK (status != 'RECEIVED' OR received_at IS NOT NULL)
);

COMMENT ON COLUMN purchase_order.number
    IS 'Sequential per tenant. Each optical store starts at 1. Calculated by application on INSERT.';
COMMENT ON COLUMN purchase_order.status
    IS 'DRAFT → SENT → RECEIVED | CANCELLED. RECEIVED triggers automatic ENTRY stock movements.';

CREATE INDEX idx_purchase_order_tenant_id   ON purchase_order(tenant_id);
CREATE INDEX idx_purchase_order_supplier_id ON purchase_order(supplier_id);
CREATE INDEX idx_purchase_order_status      ON purchase_order(status);
CREATE INDEX idx_purchase_order_created_at  ON purchase_order(created_at);

-- ── purchase_order_item ───────────────────────────────────────────
CREATE TABLE purchase_order_item (
    id                UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_order_id UUID          NOT NULL,
    product_type      VARCHAR(13)   NOT NULL,
    product_id        UUID          NOT NULL,
    quantity          INTEGER       NOT NULL,
    unit_cost         NUMERIC(10,2) NOT NULL,
    total_cost        NUMERIC(10,2) GENERATED ALWAYS AS (quantity * unit_cost) STORED,

    CONSTRAINT fk_purchase_order_item_order_id FOREIGN KEY (purchase_order_id)
        REFERENCES purchase_order(id) ON DELETE CASCADE,
    CONSTRAINT chk_purchase_order_item_type    CHECK (product_type IN ('FRAME_SKU', 'CONTACT_LENS')),
    CONSTRAINT chk_purchase_order_item_qty     CHECK (quantity > 0),
    CONSTRAINT chk_purchase_order_item_cost    CHECK (unit_cost >= 0)
);

COMMENT ON COLUMN purchase_order_item.total_cost
    IS 'Computed: quantity * unit_cost. STORED for report query performance.';

CREATE INDEX idx_purchase_order_item_order_id ON purchase_order_item(purchase_order_id);
