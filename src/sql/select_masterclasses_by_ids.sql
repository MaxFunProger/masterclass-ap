SELECT id, title, location, price, website, image_url, format, company, category, min_age, rating,
       description, event_date::text, duration, organizer, contact_tg, contact_vk, contact_phone, audience, additional_tags
FROM masterclasses
WHERE id = ANY($1)
