SELECT id, password_hash, full_name, telegram_nick
FROM users
WHERE regexp_replace(phone, '[^0-9]', '', 'g') = $1
