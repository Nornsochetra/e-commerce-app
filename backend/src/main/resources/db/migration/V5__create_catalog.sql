CREATE TABLE categories (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL,
    slug VARCHAR(140) NOT NULL UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE products (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID NOT NULL UNIQUE,
    category_id BIGINT NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    name VARCHAR(180) NOT NULL,
    description TEXT,
    price NUMERIC(12, 2) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    available_quantity INTEGER NOT NULL DEFAULT 0,
    rating NUMERIC(2, 1),
    image_url VARCHAR(2048),
    is_featured BOOLEAN NOT NULL DEFAULT FALSE,
    featured_rank INTEGER,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT chk_products_price CHECK (price >= 0),
    CONSTRAINT chk_products_quantity CHECK (available_quantity >= 0),
    CONSTRAINT chk_products_rating CHECK (rating IS NULL OR rating BETWEEN 0 AND 5),
    CONSTRAINT chk_products_featured_rank CHECK (
        (is_featured AND featured_rank IS NOT NULL AND featured_rank >= 0)
        OR (NOT is_featured AND featured_rank IS NULL)
    ),
    CONSTRAINT chk_products_currency CHECK (currency ~ '^[A-Z]{3}$')
);

CREATE TABLE product_badges (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    badge VARCHAR(24) NOT NULL,
    CONSTRAINT chk_product_badges_badge CHECK (badge IN ('NEW', 'BESTSELLER', 'PREMIUM_PICK')),
    CONSTRAINT uq_product_badges_product_badge UNIQUE (product_id, badge)
);

CREATE INDEX ix_categories_active_name
    ON categories (name, id)
    WHERE is_active;

CREATE INDEX ix_products_category_created
    ON products (category_id, created_at DESC, id DESC)
    WHERE is_active;

CREATE INDEX ix_products_name
    ON products (lower(name), id)
    WHERE is_active;

CREATE INDEX ix_products_featured
    ON products (featured_rank, created_at DESC, id DESC)
    WHERE is_active AND is_featured;

CREATE INDEX ix_product_badges_product ON product_badges (product_id, id);
