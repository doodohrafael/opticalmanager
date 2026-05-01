-- =================================================================
-- V3__create_clients.sql
--
-- Module: clients
-- Tables: client, contact, prescription, prescription_grade
-- =================================================================

-- ── client ────────────────────────────────────────────────────────
CREATE TABLE client (
    id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id  UUID         NOT NULL,
    name       VARCHAR(100) NOT NULL,
    cpf        CHAR(11),
    birth_date DATE,
    notes      VARCHAR(300),
    created_at TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP    NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_client_tenant_id FOREIGN KEY (tenant_id) REFERENCES tenant(id)
);

COMMENT ON TABLE  client       IS 'End customers of the optical store.';
COMMENT ON COLUMN client.cpf   IS 'Optional — not all clients provide CPF.';
COMMENT ON COLUMN client.notes IS 'Internal notes visible only to the store.';

CREATE INDEX idx_client_tenant_id ON client(tenant_id);
CREATE INDEX idx_client_name      ON client(tenant_id, name);
CREATE INDEX idx_client_cpf       ON client(cpf) WHERE cpf IS NOT NULL;

-- ── contact ───────────────────────────────────────────────────────
-- Polymorphic: one table for contacts of CLIENT and SUPPLIER.
-- owner_type + owner_id identify the owning entity.
-- One principal = true per (owner, type) — enforced at application layer.
CREATE TABLE contact (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID         NOT NULL,
    owner_type  VARCHAR(10)  NOT NULL,
    owner_id    UUID         NOT NULL,
    type        VARCHAR(10)  NOT NULL,
    value       VARCHAR(100) NOT NULL,
    principal   BOOLEAN      NOT NULL DEFAULT FALSE,
    observation VARCHAR(100),

    CONSTRAINT fk_contact_tenant_id    FOREIGN KEY (tenant_id) REFERENCES tenant(id),
    CONSTRAINT chk_contact_owner_type  CHECK (owner_type IN ('CLIENT', 'SUPPLIER')),
    CONSTRAINT chk_contact_type        CHECK (type IN ('MOBILE', 'PHONE', 'EMAIL', 'WHATSAPP'))
);

COMMENT ON COLUMN contact.owner_type IS 'CLIENT or SUPPLIER.';
COMMENT ON COLUMN contact.owner_id   IS 'UUID of the owning entity.';
COMMENT ON COLUMN contact.principal  IS 'Primary contact of this type for the owner. Used for notifications.';

CREATE INDEX idx_contact_tenant_id ON contact(tenant_id);
CREATE INDEX idx_contact_owner     ON contact(owner_type, owner_id);
CREATE INDEX idx_contact_whatsapp  ON contact(owner_id)
    WHERE type = 'WHATSAPP' AND principal = TRUE;

-- ── prescription ──────────────────────────────────────────────────
CREATE TABLE prescription (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID         NOT NULL,
    client_id   UUID         NOT NULL,
    type        VARCHAR(13)  NOT NULL DEFAULT 'GLASSES',
    doctor_name VARCHAR(100),
    issued_at   DATE         NOT NULL,
    expires_at  DATE,
    origin      VARCHAR(16)  NOT NULL,
    observation VARCHAR(300),
    photo_url   VARCHAR(500),
    created_at  TIMESTAMP    NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_prescription_tenant_id FOREIGN KEY (tenant_id) REFERENCES tenant(id),
    CONSTRAINT fk_prescription_client_id FOREIGN KEY (client_id) REFERENCES client(id),
    CONSTRAINT chk_prescription_type     CHECK (type IN ('GLASSES', 'CONTACT_LENS')),
    CONSTRAINT chk_prescription_origin   CHECK (origin IN ('DOCTOR', 'OPTICIAN', 'CLIENT_INFORMED')),
    CONSTRAINT chk_prescription_client_informed CHECK (
        origin != 'CLIENT_INFORMED' OR observation IS NOT NULL
    ),
    CONSTRAINT chk_prescription_expires CHECK (
        expires_at IS NULL OR expires_at > issued_at
    )
);

COMMENT ON COLUMN prescription.origin
    IS 'DOCTOR: client brought doc. OPTICIAN: store did exam. CLIENT_INFORMED: verbal — observation required.';
COMMENT ON COLUMN prescription.photo_url
    IS 'Cloudflare R2 URL. Populated when AI prescription reading is used.';

CREATE INDEX idx_prescription_tenant_id ON prescription(tenant_id);
CREATE INDEX idx_prescription_client_id ON prescription(client_id);
CREATE INDEX idx_prescription_expires   ON prescription(tenant_id, expires_at)
    WHERE expires_at IS NOT NULL;

-- ── prescription_grade ────────────────────────────────────────────
-- Value object: always 2 rows per prescription (OD and OE).
-- axis validated by CHECK (0-180) and by PrescriptionGrade record constructor.
CREATE TABLE prescription_grade (
    id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    prescription_id UUID         NOT NULL,
    eye             CHAR(2)      NOT NULL,
    spherical       NUMERIC(5,2),
    cylindrical     NUMERIC(5,2),
    axis            SMALLINT,
    addition        NUMERIC(5,2),
    dp              NUMERIC(4,1),

    CONSTRAINT fk_prescription_grade_prescription_id FOREIGN KEY (prescription_id)
        REFERENCES prescription(id) ON DELETE CASCADE,
    CONSTRAINT uq_prescription_grade_eye UNIQUE (prescription_id, eye),
    CONSTRAINT chk_prescription_grade_eye      CHECK (eye IN ('OD', 'OE')),
    CONSTRAINT chk_prescription_grade_axis     CHECK (axis IS NULL OR axis BETWEEN 0 AND 180),
    CONSTRAINT chk_prescription_grade_addition CHECK (addition IS NULL OR addition >= 0),
    CONSTRAINT chk_prescription_grade_dp       CHECK (dp IS NULL OR dp BETWEEN 40.0 AND 80.0)
);

COMMENT ON COLUMN prescription_grade.eye      IS 'OD = right eye (Oculus Dexter). OE = left eye (Oculus Sinister).';
COMMENT ON COLUMN prescription_grade.addition IS 'Near-vision add. Only for bifocal/progressive. NULL for monofocal.';
COMMENT ON COLUMN prescription_grade.dp       IS 'Pupillary distance in mm. Normal adult range: 40–80mm.';

CREATE INDEX idx_prescription_grade_prescription_id ON prescription_grade(prescription_id);
