SELECT id, title, location, price, website, image_url, format, company, category, min_age, rating,
       description, event_date::text, duration, organizer, contact_tg, contact_vk, contact_phone, audience, additional_tags
FROM masterclasses
WHERE ($1::text IS NULL OR category ~* replace($1, ',', '|'))
  AND ($2::text IS NULL OR audience ~* replace($2, ',', '|'))
  AND ($3::text IS NULL OR additional_tags ~* replace($3, ',', '|'))
  AND ($4::text IS NULL OR format = $4)
  AND ($5::text IS NULL OR company = $5)
  AND ($6::int IS NULL OR min_age <= $6)
  AND ($7::float IS NULL OR price <= $7)
  AND ($8::float IS NULL OR price >= $8)
  AND ($9::float IS NULL OR rating >= $9)
  AND ($10::bigint[] IS NULL OR id <> ALL($10))
  AND ($11::date IS NULL OR (event_date IS NOT NULL AND event_date >= $11::date))
  AND ($12::date IS NULL OR (event_date IS NOT NULL AND event_date <= $12::date))
ORDER BY id ASC LIMIT $13 OFFSET $14
