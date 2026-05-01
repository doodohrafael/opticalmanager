-- =================================================================
-- V4__create_products.sql
--
-- Module: products
-- Tables: supplier, frame, frame_sku, lens_type,
--         lens_grade_range, contact_lens
--
-- supplier address: embedded Value Object (same as branch).
--   Supplier address has no identity of its own.
-- =================================================================

-- ── supplier ──────────────────────────────────────────────────────
CREATE TABLE supplier (
    id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id     UUID         NOT NULL,
    name          VARCHAR(100) NOT NULL,
    contact_name  VARCHAR(100),
    notes         VARCHAR(300),

    -- Address (embedded Value Object)
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

    CONSTRAINT fk_supplier_tenant_id FOREIGN KEY (tenant_id) REFERENCES tenant(id),
    CONSTRAINT chk_supplier_state    CHECK (state IS NULL OR LENGTH(state) = 2)
);

COMMENT ON TABLE  supplier              IS 'Frame and contact lens suppliers. Contacts in the contact table.';
COMMENT ON COLUMN supplier.contact_name IS 'Name of the sales representative or main contact at the supplier.';

CREATE INDEX idx_supplier_tenant_id ON supplier(tenant_id);
CREATE INDEX idx_supplier_name      ON supplier(tenant_id, name);

-- ── frame ─────────────────────────────────────────────────────────
-- Conceptual product (brand + model). Stock lives on frame_sku.
CREATE TABLE frame (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID        NOT NULL,
    supplier_id UUID,
    brand       VARCHAR(60) NOT NULL,
    model       VARCHAR(60) NOT NULL,
    notes       VARCHAR(200),
    active      BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP   NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP   NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_frame_tenant_id   FOREIGN KEY (tenant_id)   REFERENCES tenant(id),
    CONSTRAINT fk_frame_supplier_id FOREIGN KEY (supplier_id) REFERENCES supplier(id)
);

COMMENT ON TABLE frame IS 'Conceptual frame product (brand + model). Stock lives on frame_sku.';

CREATE INDEX idx_frame_tenant_id   ON frame(tenant_id);
CREATE INDEX idx_frame_brand       ON frame(tenant_id, brand);
CREATE INDEX idx_frame_supplier_id ON frame(supplier_id) WHERE supplier_id IS NOT NULL;

-- ── frame_sku ─────────────────────────────────────────────────────
-- Trackable, stockable variation of a frame (color + size).
CREATE TABLE frame_sku (
    id         UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    frame_id   UUID          NOT NULL,
    color      VARCHAR(40),
    size       VARCHAR(10),
    cost_price NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    sale_price NUMERIC(10,2) NOT NULL,
    active     BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP     NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP     NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_frame_sku_frame_id  FOREIGN KEY (frame_id) REFERENCES frame(id),
    CONSTRAINT chk_frame_sku_cost     CHECK (cost_price >= 0),
    CONSTRAINT chk_frame_sku_price    CHECK (sale_price >= 0)
);

COMMENT ON COLUMN frame_sku.cost_price IS 'Purchase cost from supplier. Used in profit calculation.';
COMMENT ON COLUMN frame_sku.sale_price IS 'Retail price charged to the client.';

CREATE INDEX idx_frame_sku_frame_id ON frame_sku(frame_id);

-- ── lens_type ─────────────────────────────────────────────────────
-- Ophthalmic lens catalog — NO physical stock.
-- Made to order at the external lab per service order.
CREATE TABLE lens_type (
    id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id     UUID          NOT NULL,
    type          VARCHAR(12)   NOT NULL,
    material      VARCHAR(15)   NOT NULL,
    treatment     VARCHAR(15)   NOT NULL,
    pricing_model VARCHAR(11)   NOT NULL DEFAULT 'FIXED',
    base_price    NUMERIC(10,2),
    notes         VARCHAR(200),
    active        BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP     NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMP     NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_lens_type_tenant_id    FOREIGN KEY (tenant_id) REFERENCES tenant(id),
    CONSTRAINT chk_lens_type_type        CHECK (type IN ('MONOFOCAL', 'BIFOCAL', 'PROGRESSIVE')),
    CONSTRAINT chk_lens_type_material    CHECK (material IN ('RESIN', 'POLYCARBONATE', 'TRIVEX')),
    CONSTRAINT chk_lens_type_treatment   CHECK (
        treatment IN ('NONE', 'ANTI_REFLECTIVE', 'UV', 'PHOTOCHROMIC', 'BLUE_LIGHT')
    ),
    CONSTRAINT chk_lens_type_pricing     CHECK (pricing_model IN ('FIXED', 'GRADE_RANGE')),
    CONSTRAINT chk_lens_type_fixed_price CHECK (pricing_model != 'FIXED' OR base_price IS NOT NULL)
);

COMMENT ON COLUMN lens_type.pricing_model
    IS 'FIXED: one price for all grades. GRADE_RANGE: price depends on prescription grade.';
COMMENT ON COLUMN lens_type.base_price
    IS 'Required when pricing_model = FIXED. NULL for GRADE_RANGE.';

CREATE INDEX idx_lens_type_tenant_id ON lens_type(tenant_id);

-- ── lens_grade_range ──────────────────────────────────────────────
CREATE TABLE lens_grade_range (
    id           UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    lens_type_id UUID          NOT NULL,
    grade_from   NUMERIC(5,2)  NOT NULL,
    grade_to     NUMERIC(5,2)  NOT NULL,
    price        NUMERIC(10,2) NOT NULL,

    CONSTRAINT fk_lens_grade_range_lens_type_id FOREIGN KEY (lens_type_id)
        REFERENCES lens_type(id) ON DELETE CASCADE,
    CONSTRAINT chk_lens_grade_range_order CHECK (grade_from <= grade_to),
    CONSTRAINT chk_lens_grade_range_price CHECK (price >= 0)
);

COMMENT ON TABLE lens_grade_range
    IS 'Price tiers by prescription grade for GRADE_RANGE lens types.';

CREATE INDEX idx_lens_grade_range_lens_type_id ON lens_grade_range(lens_type_id);

-- ── contact_lens ──────────────────────────────────────────────────
-- Physical product with stock. Sold in pairs by default.
CREATE TABLE contact_lens (
    id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id     UUID          NOT NULL,
    supplier_id   UUID,
    brand         VARCHAR(60)   NOT NULL,
    model         VARCHAR(60)   NOT NULL,
    usage_type    VARCHAR(10)   NOT NULL,
    grade         NUMERIC(5,2)  NOT NULL DEFAULT 0.00,
    colored       BOOLEAN       NOT NULL DEFAULT FALSE,
    units_per_box SMALLINT      NOT NULL DEFAULT 1,
    cost_price    NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    sale_price    NUMERIC(10,2) NOT NULL,
    active        BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP     NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMP     NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_contact_lens_tenant_id   FOREIGN KEY (tenant_id)   REFERENCES tenant(id),
    CONSTRAINT fk_contact_lens_supplier_id FOREIGN KEY (supplier_id) REFERENCES supplier(id),
    CONSTRAINT chk_contact_lens_usage      CHECK (usage_type IN ('DAILY', 'BIWEEKLY', 'MONTHLY')),
    CONSTRAINT chk_contact_lens_units      CHECK (units_per_box > 0),
    CONSTRAINT chk_contact_lens_cost       CHECK (cost_price >= 0),
    CONSTRAINT chk_contact_lens_price      CHECK (sale_price >= 0)
);

COMMENT ON COLUMN contact_lens.grade         IS '0.00 for plano/colored. Negative for myopia (e.g. -2.50).';
COMMENT ON COLUMN contact_lens.colored       IS 'True for cosmetic colored lenses, including plano.';
COMMENT ON COLUMN contact_lens.units_per_box IS 'Lenses per box (e.g. 6, 10, 30).';

CREATE INDEX idx_contact_lens_tenant_id   ON contact_lens(tenant_id);
CREATE INDEX idx_contact_lens_brand       ON contact_lens(tenant_id, brand);
CREATE INDEX idx_contact_lens_supplier_id ON contact_lens(supplier_id) WHERE supplier_id IS NOT NULL;
