INSERT INTO masterclasses
  (id, title, location, price, website, image_url, format, company, category, min_age, rating,
   description, event_date, duration, organizer, contact_tg, contact_vk, contact_phone, audience, additional_tags)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13::date, $14, $15, $16, $17, $18, $19, $20)
ON CONFLICT (id) DO NOTHING
