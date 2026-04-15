INSERT INTO users (id, phone, full_name, telegram_nick, password_hash)
VALUES ($1, $2, $3, $4, $5)
ON CONFLICT (phone) DO NOTHING
