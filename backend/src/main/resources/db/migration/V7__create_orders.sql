CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID NOT NULL UNIQUE,
    reference VARCHAR(32) NOT NULL UNIQUE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    status VARCHAR(24) NOT NULL DEFAULT 'PENDING',
    recipient_name VARCHAR(120) NOT NULL,
    delivery_email VARCHAR(255) NOT NULL,
    delivery_address TEXT NOT NULL,
    delivery_method VARCHAR(24) NOT NULL DEFAULT 'STANDARD',
    payment_method VARCHAR(32) NOT NULL,
    subtotal NUMERIC(12, 2) NOT NULL,
    delivery_fee NUMERIC(12, 2) NOT NULL,
    total NUMERIC(12, 2) NOT NULL,
    currency CHAR(3) NOT NULL,
    idempotency_key VARCHAR(128) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT uq_orders_user_idempotency UNIQUE (user_id, idempotency_key),
    CONSTRAINT chk_orders_status
        CHECK (status IN ('PENDING', 'CONFIRMED', 'SHIPPED', 'DELIVERED')),
    CONSTRAINT chk_orders_payment_method CHECK (payment_method IN ('CASH_ON_DELIVERY')),
    CONSTRAINT chk_orders_delivery_method CHECK (delivery_method IN ('STANDARD')),
    CONSTRAINT chk_orders_amounts
        CHECK (subtotal >= 0 AND delivery_fee >= 0 AND total = subtotal + delivery_fee),
    CONSTRAINT chk_orders_currency CHECK (currency ~ '^[A-Z]{3}$')
);

CREATE TABLE order_items (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE RESTRICT,
    product_id BIGINT REFERENCES products(id) ON DELETE SET NULL,
    product_uuid UUID NOT NULL,
    product_name VARCHAR(180) NOT NULL,
    image_url VARCHAR(2048),
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(12, 2) NOT NULL,
    line_total NUMERIC(12, 2) NOT NULL,
    currency CHAR(3) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT chk_order_items_quantity CHECK (quantity > 0),
    CONSTRAINT chk_order_items_amounts
        CHECK (unit_price >= 0 AND line_total = quantity * unit_price),
    CONSTRAINT chk_order_items_currency CHECK (currency ~ '^[A-Z]{3}$')
);

CREATE INDEX ix_orders_user_created ON orders (user_id, created_at DESC, id DESC);

CREATE INDEX ix_order_items_order ON order_items (order_id, id);
