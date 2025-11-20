CREATE TABLE IF NOT EXISTS masterclasses (
    id BIGINT PRIMARY KEY,
    title TEXT NOT NULL,
    location TEXT NOT NULL,
    price DOUBLE PRECISION NOT NULL CHECK (price >= 0),
    website TEXT NOT NULL,
    image_url TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

