INSERT INTO users (email, password_hash, name, role, is_active, created_at, updated_at)
VALUES
    ('customer@example.com', '$2y$10$RhJsogsfjpSP1cz65jXaL.m9KPH//NGRyLHr1MyTWj/suNNpK4Ul6', 'Local Customer', 'CUSTOMER', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('admin@example.com', '$2y$10$RhJsogsfjpSP1cz65jXaL.m9KPH//NGRyLHr1MyTWj/suNNpK4Ul6', 'Local Admin', 'ADMIN', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT DO NOTHING;
