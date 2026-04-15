DELETE FROM user_favorites
WHERE user_id = $1 AND masterclass_id = $2
