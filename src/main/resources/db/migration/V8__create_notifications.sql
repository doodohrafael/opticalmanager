-- =================================================================
-- V8__create_notifications.sql
--
-- Module: notifications
-- Tables: notification_log
-- =================================================================

CREATE TABLE notification_log (
    id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id        UUID        NOT NULL,
    client_id        UUID        NOT NULL,
    prescription_id  UUID,
    service_order_id UUID,
    type             VARCHAR(20) NOT NULL,
    channel          VARCHAR(10) NOT NULL DEFAULT 'EMAIL',
    status           VARCHAR(8)  NOT NULL DEFAULT 'SENT',
    error_message    VARCHAR(300),
    sent_at          TIMESTAMP   NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_notification_log_tenant_id        FOREIGN KEY (tenant_id)       REFERENCES tenant(id),
    CONSTRAINT fk_notification_log_client_id        FOREIGN KEY (client_id)       REFERENCES client(id),
    CONSTRAINT fk_notification_log_prescription_id  FOREIGN KEY (prescription_id) REFERENCES prescription(id),
    CONSTRAINT fk_notification_log_service_order_id FOREIGN KEY (service_order_id) REFERENCES service_order(id),
    CONSTRAINT chk_notification_log_type CHECK (
        type IN (
            'PRESCRIPTION_EXPIRY',
            'OS_READY',
            'TRIAL_EXPIRING',
            'TRIAL_EXPIRED',
            'SALE_CONFIRMED'
        )
    ),
    CONSTRAINT chk_notification_log_channel CHECK (channel IN ('EMAIL', 'WHATSAPP', 'SMS')),
    CONSTRAINT chk_notification_log_status  CHECK (status IN ('SENT', 'FAILED', 'SKIPPED')),
    CONSTRAINT chk_notification_log_prescription_ref CHECK (
        type != 'PRESCRIPTION_EXPIRY' OR prescription_id IS NOT NULL
    ),
    CONSTRAINT chk_notification_log_os_ref CHECK (
        type != 'OS_READY' OR service_order_id IS NOT NULL
    )
);

COMMENT ON TABLE notification_log
    IS 'Audit log of every notification attempt. Used to prevent duplicate sends.';
COMMENT ON COLUMN notification_log.status
    IS 'SENT: delivered. FAILED: provider error (error_message set). SKIPPED: duplicate guard triggered.';

CREATE INDEX idx_notification_log_tenant_id       ON notification_log(tenant_id);
CREATE INDEX idx_notification_log_client_id       ON notification_log(client_id);
CREATE INDEX idx_notification_log_prescription_id ON notification_log(prescription_id)
    WHERE prescription_id IS NOT NULL;
CREATE INDEX idx_notification_log_sent_at         ON notification_log(sent_at);

-- Prevents sending the same PRESCRIPTION_EXPIRY notification
-- for the same prescription more than once per day.
CREATE UNIQUE INDEX idx_notification_log_no_duplicate
    ON notification_log(prescription_id, type, DATE(sent_at))
    WHERE prescription_id IS NOT NULL AND status = 'SENT';
