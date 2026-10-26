-- Development-only catalog seed (loaded only by the dev profile: see application-dev.yml).
-- Same categories and products as the Flutter mock data and the HTML prototype, with the same UUIDs,
-- so the app looks the same before and after it is connected to the API.
-- Repeatable migration: Flyway re-runs it whenever this file changes. Existing rows are updated
-- back to these values (this also restores stock that orders have used up).

INSERT INTO categories (uuid, name, slug, is_active, created_at, updated_at)
VALUES
    ('a0000000-0000-4000-8000-000000000001', 'Accessories', 'accessories', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('a0000000-0000-4000-8000-000000000002', 'Footwear', 'footwear', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('a0000000-0000-4000-8000-000000000003', 'Bags', 'bags', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('a0000000-0000-4000-8000-000000000004', 'Electronics', 'electronics', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (uuid) DO UPDATE
    SET name = EXCLUDED.name, slug = EXCLUDED.slug, is_active = TRUE, updated_at = CURRENT_TIMESTAMP;

INSERT INTO products (uuid, category_id, name, description, price, currency, available_quantity, rating, image_url,
                      is_featured, featured_rank, is_active, created_at, updated_at)
SELECT p.uuid::uuid, c.id, p.name, p.description, p.price, 'USD', p.quantity, p.rating, p.image_url,
       p.featured_rank IS NOT NULL, p.featured_rank, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM (VALUES
    ('11111111-1111-4111-8111-111111111111', 'accessories', 'Minimal Watch',
     'A quiet, refined watch designed for everyday wear.', 89.00, 8, 4.8,
     'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=800&q=80', 0),
    ('22222222-2222-4222-8222-222222222222', 'footwear', 'Cloud Sneakers',
     NULL, 74.00, 12, 4.6,
     'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=800&q=80', 1),
    ('33333333-3333-4333-8333-333333333333', 'bags', 'Canvas Backpack',
     'Durable canvas storage with a comfortable everyday silhouette.', 58.00, 5, 4.7,
     'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?auto=format&fit=crop&w=800&q=80', 2),
    ('44444444-4444-4444-8444-444444444444', 'electronics', 'Studio Headphones',
     'Immersive sound with a lightweight over-ear design.', 129.00, 0, 4.9,
     'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=800&q=80', NULL),
    ('55555555-5555-4555-8555-555555555555', 'accessories', 'Classic Sunglasses',
     NULL, 42.00, 16, 4.5,
     'https://images.unsplash.com/photo-1511499767150-a48a237f0083?auto=format&fit=crop&w=800&q=80', NULL),
    ('66666666-6666-4666-8666-666666666666', 'electronics', 'Everyday Camera',
     'A compact camera for documenting the moments that matter.', 245.00, 3, 4.7,
     'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=800&q=80', 3)
) AS p (uuid, category_slug, name, description, price, quantity, rating, image_url, featured_rank)
JOIN categories c ON c.slug = p.category_slug
ON CONFLICT (uuid) DO UPDATE
    SET category_id = EXCLUDED.category_id, name = EXCLUDED.name, description = EXCLUDED.description,
        price = EXCLUDED.price, available_quantity = EXCLUDED.available_quantity, rating = EXCLUDED.rating,
        image_url = EXCLUDED.image_url, is_featured = EXCLUDED.is_featured, featured_rank = EXCLUDED.featured_rank,
        is_active = TRUE, updated_at = CURRENT_TIMESTAMP;

INSERT INTO product_badges (product_id, badge)
SELECT pr.id, b.badge
FROM (VALUES
    ('11111111-1111-4111-8111-111111111111', 'NEW'),
    ('11111111-1111-4111-8111-111111111111', 'PREMIUM_PICK'),
    ('22222222-2222-4222-8222-222222222222', 'BESTSELLER'),
    ('33333333-3333-4333-8333-333333333333', 'BESTSELLER'),
    ('44444444-4444-4444-8444-444444444444', 'PREMIUM_PICK'),
    ('66666666-6666-4666-8666-666666666666', 'NEW')
) AS b (product_uuid, badge)
JOIN products pr ON pr.uuid = b.product_uuid::uuid
ON CONFLICT (product_id, badge) DO NOTHING;
