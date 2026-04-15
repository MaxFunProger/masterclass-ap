INSERT INTO user_favorites (user_id, masterclass_id)
VALUES ($1, $2)
ON CONFLICT DO NOTHING
