CREATE TABLE IF NOT EXISTS user_requests (
    user_id TEXT PRIMARY KEY,
    request_count BIGINT NOT NULL DEFAULT 0
);

