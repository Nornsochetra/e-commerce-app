-- Development-only seed credentials:
-- Email: user@example.com
-- Password: Demo123!
INSERT INTO users (email, password_hash, name, role, is_active, created_at, updated_at)
VALUES
    ('user@example.com', '$2y$10$5j0FNfiTXBjdmtw1Ly49heZv9zcsZlvqGGkrkFJ/nAIx0aw3fRCiC', 'Local User', 'USER', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT DO NOTHING;
