CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID NOT NULL UNIQUE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(24) NOT NULL,
    title VARCHAR(160) NOT NULL,
    message TEXT NOT NULL,
    read_at TIMESTAMPTZ,
    cleared_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT chk_notifications_type CHECK (type IN ('ORDER', 'OFFER', 'STOCK'))
);

CREATE INDEX ix_notifications_user_created
    ON notifications (user_id, created_at DESC, id DESC)
    WHERE cleared_at IS NULL;

CREATE INDEX ix_notifications_user_unread
    ON notifications (user_id, created_at DESC, id DESC)
    WHERE read_at IS NULL AND cleared_at IS NULL;
