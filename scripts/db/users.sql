CREATE TABLE IF NOT EXISTS user_requests (
    user_id TEXT PRIMARY KEY,
    phone TEXT NOT NULL,
    full_name TEXT NOT NULL,
    telegram_nick TEXT NOT NULL,
    request_count BIGINT NOT NULL DEFAULT 0
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'user_requests' AND column_name = 'phone'
    ) THEN
        ALTER TABLE user_requests ADD COLUMN phone TEXT;
        UPDATE user_requests SET phone = '' WHERE phone IS NULL;
        ALTER TABLE user_requests ALTER COLUMN phone SET NOT NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'user_requests' AND column_name = 'full_name'
    ) THEN
        ALTER TABLE user_requests ADD COLUMN full_name TEXT;
        UPDATE user_requests SET full_name = '' WHERE full_name IS NULL;
        ALTER TABLE user_requests ALTER COLUMN full_name SET NOT NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'user_requests' AND column_name = 'telegram_nick'
    ) THEN
        ALTER TABLE user_requests ADD COLUMN telegram_nick TEXT;
        UPDATE user_requests SET telegram_nick = '' WHERE telegram_nick IS NULL;
        ALTER TABLE user_requests ALTER COLUMN telegram_nick SET NOT NULL;
    END IF;
END $$;

