SELECT 1 FROM users
WHERE regexp_replace(phone, '[^0-9]', '', 'g') = $1
LIMIT 1
