-- =================================================================
-- V2__create_identity.sql
--
-- Module: identity
-- Tables: permission, role, role_permission, app_user, refresh_token
--
-- Note: table named app_user (not user) — user is a reserved word
--       in PostgreSQL and would require quoting everywhere.
--
-- Pattern: RBAC — Role-Based Access Control
--   Permission slug format: resource:action  (e.g. sales:create)
--   role_permission stores slugs directly — no join needed on auth
--   token_version: incremented on permission change → forces re-login
-- =================================================================

-- ── permission ────────────────────────────────────────────────────
CREATE TABLE permission (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    slug        VARCHAR(50)  NOT NULL,
    description VARCHAR(150) NOT NULL,

    CONSTRAINT uq_permission_slug UNIQUE (slug)
);

COMMENT ON TABLE  permission      IS 'Global permission catalog. Shared across all tenants.';
COMMENT ON COLUMN permission.slug IS 'Format: resource:action. e.g. sales:create, cash:open.';

INSERT INTO permission (slug, description) VALUES
    ('sales:create',         'Open a sale or service order'),
    ('sales:view',           'View sales and service orders'),
    ('sales:cancel',         'Cancel a sale or service order'),
    ('sales:discount',       'Apply discount on a sale'),
    ('clients:create',       'Register new clients'),
    ('clients:view',         'View client data and prescriptions'),
    ('clients:edit',         'Edit client data and prescriptions'),
    ('stock:view',           'View stock levels and movements'),
    ('stock:edit',           'Adjust stock manually'),
    ('stock:purchase-order', 'Create and manage purchase orders'),
    ('cash:open',            'Open the daily cash register'),
    ('cash:close',           'Close the daily cash register'),
    ('cash:view',            'View cash register and transactions'),
    ('reports:view',         'Access financial and operational reports'),
    ('labels:print',         'Print OS and product labels'),
    ('ai:read-prescription', 'Use AI to read prescription from photo'),
    ('users:manage',         'Create, edit and deactivate users'),
    ('roles:configure',      'Configure roles and their permissions'),
    ('notifications:view',   'View notification history');

-- ── role ──────────────────────────────────────────────────────────
-- Defaults (OWNER, MANAGER, VENDOR) created by the application
-- on tenant registration — not seeded here, they are per-tenant.
CREATE TABLE role (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID         NOT NULL,
    name        VARCHAR(50)  NOT NULL,
    description VARCHAR(150),
    created_at  TIMESTAMP    NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_role_tenant_id   FOREIGN KEY (tenant_id) REFERENCES tenant(id),
    CONSTRAINT uq_role_tenant_name UNIQUE (tenant_id, name)
);

COMMENT ON TABLE role IS 'Named permission sets per tenant. Defaults: OWNER, MANAGER, VENDOR.';

CREATE INDEX idx_role_tenant_id ON role(tenant_id);

-- ── role_permission ───────────────────────────────────────────────
-- Slugs stored directly — avoids join to permission on every auth check.
CREATE TABLE role_permission (
    role_id         UUID        NOT NULL,
    permission_slug VARCHAR(50) NOT NULL,

    CONSTRAINT pk_role_permission          PRIMARY KEY (role_id, permission_slug),
    CONSTRAINT fk_role_permission_role_id  FOREIGN KEY (role_id) REFERENCES role(id) ON DELETE CASCADE
);

COMMENT ON TABLE  role_permission                IS 'Permissions assigned to a role. Slug stored directly for auth performance.';
COMMENT ON COLUMN role_permission.permission_slug IS 'Must match a slug in the permission table — enforced by application.';

CREATE INDEX idx_role_permission_role_id ON role_permission(role_id);

-- ── app_user ──────────────────────────────────────────────────────
-- Named app_user to avoid conflict with PostgreSQL reserved word user.
-- JPA entity: @Table(name = "app_user")
CREATE TABLE app_user (
    id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id     UUID         NOT NULL,
    branch_id     UUID         NOT NULL,
    role_id       UUID         NOT NULL,
    name          VARCHAR(100) NOT NULL,
    email         VARCHAR(100) NOT NULL,
    password_hash CHAR(60)     NOT NULL,
    active        BOOLEAN      NOT NULL DEFAULT TRUE,
    token_version INTEGER      NOT NULL DEFAULT 0,
    created_at    TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMP    NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_app_user_tenant_id  FOREIGN KEY (tenant_id) REFERENCES tenant(id),
    CONSTRAINT fk_app_user_branch_id  FOREIGN KEY (branch_id) REFERENCES branch(id),
    CONSTRAINT fk_app_user_role_id    FOREIGN KEY (role_id)   REFERENCES role(id),
    -- Email unique per tenant — same email allowed in different tenants
    CONSTRAINT uq_app_user_tenant_email UNIQUE (tenant_id, email)
);

COMMENT ON TABLE  app_user              IS 'System users. Named app_user to avoid PostgreSQL reserved word conflict.';
COMMENT ON COLUMN app_user.password_hash IS 'BCrypt(12) hash. Always exactly 60 characters.';
COMMENT ON COLUMN app_user.token_version IS 'Incremented when permissions change. JWT must match or be rejected.';
COMMENT ON COLUMN app_user.active        IS 'Soft deactivation — data preserved, authentication blocked.';

CREATE INDEX idx_app_user_tenant_id ON app_user(tenant_id);
CREATE INDEX idx_app_user_branch_id ON app_user(branch_id);
CREATE INDEX idx_app_user_role_id   ON app_user(role_id);
CREATE INDEX idx_app_user_email     ON app_user(email);

-- ── refresh_token ─────────────────────────────────────────────────
-- SHA-256 hash stored — never the raw token.
-- Rotated on every use: old record deleted, new one created.
CREATE TABLE refresh_token (
    id         UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID      NOT NULL,
    token_hash CHAR(64)  NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_refresh_token_user_id  FOREIGN KEY (user_id) REFERENCES app_user(id) ON DELETE CASCADE,
    CONSTRAINT uq_refresh_token_hash     UNIQUE (token_hash)
);

COMMENT ON TABLE  refresh_token            IS 'Server-side refresh tokens. Rotated on every use.';
COMMENT ON COLUMN refresh_token.token_hash IS 'SHA-256 hex of raw token. CHAR(64) = exact SHA-256 hex output length.';

CREATE INDEX idx_refresh_token_user_id    ON refresh_token(user_id);
CREATE INDEX idx_refresh_token_expires_at ON refresh_token(expires_at);
