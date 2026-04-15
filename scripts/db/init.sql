DROP TABLE IF EXISTS user_favorites;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS masterclasses;

CREATE TABLE IF NOT EXISTS masterclasses (
    id BIGINT PRIMARY KEY,
    title TEXT NOT NULL,
    location TEXT NOT NULL,
    price DOUBLE PRECISION NOT NULL CHECK (price >= 0),
    website TEXT NOT NULL,
    image_url TEXT NOT NULL,
    format TEXT CHECK (format IN ('online', 'offline')),
    company TEXT CHECK (company IN ('single', 'friends')),
    category TEXT NOT NULL,
    min_age INT CHECK (min_age >= 0),
    rating DOUBLE PRECISION CHECK (rating >= 1.0 AND rating <= 5.0),
    description TEXT,
    event_date DATE,
    duration TEXT,
    organizer TEXT,
    contact_tg TEXT,
    contact_vk TEXT,
    contact_phone TEXT,
    audience TEXT,
    additional_tags TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    phone TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    full_name TEXT NOT NULL,
    telegram_nick TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_favorites (
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    masterclass_id BIGINT NOT NULL REFERENCES masterclasses(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, masterclass_id)
);
