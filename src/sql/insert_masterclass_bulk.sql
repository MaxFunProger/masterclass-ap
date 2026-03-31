INSERT INTO masterclasses (id, title, location, price, website, image_url)
VALUES ($1, $2, $3, $4, $5, $6)
ON CONFLICT (id) DO NOTHING
