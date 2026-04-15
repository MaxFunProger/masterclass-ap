SELECT id, phone, full_name, telegram_nick
FROM users
WHERE id = $1
