-- ============================================================
-- YOUTUBE CLONE DATABASE - SCHEMA
-- Database Systems Assignment 2
-- 14 Tables | Normalization: 1NF, 2NF, 3NF
-- ============================================================

CREATE DATABASE IF NOT EXISTS youtube_db;
USE youtube_db;

-- Drop in reverse FK order
DROP TABLE IF EXISTS Notifications;
DROP TABLE IF EXISTS Video_Tags;
DROP TABLE IF EXISTS Comment_Likes;
DROP TABLE IF EXISTS Watch_History;
DROP TABLE IF EXISTS Video_Likes;
DROP TABLE IF EXISTS Subscriptions;
DROP TABLE IF EXISTS Playlist_Videos;
DROP TABLE IF EXISTS Comments;
DROP TABLE IF EXISTS Playlists;
DROP TABLE IF EXISTS Videos;
DROP TABLE IF EXISTS Tags;
DROP TABLE IF EXISTS Categories;
DROP TABLE IF EXISTS Channels;
DROP TABLE IF EXISTS Users;

-- ============================================================
-- 1. USERS
-- FD: user_id -> {username, email, password_hash, first_name,
--     last_name, date_of_birth, country, created_at, last_login}
-- Candidate keys: username, email (both unique)
-- 3NF: No transitive dependencies
-- ============================================================
CREATE TABLE Users (
    user_id       INT           AUTO_INCREMENT PRIMARY KEY,
    username      VARCHAR(50)   UNIQUE NOT NULL,
    email         VARCHAR(100)  UNIQUE NOT NULL,
    password_hash VARCHAR(255)  NOT NULL,
    first_name    VARCHAR(50),
    last_name     VARCHAR(50),
    date_of_birth DATE,
    country       VARCHAR(50),
    created_at    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    last_login    TIMESTAMP     NULL
);

-- ============================================================
-- 2. CATEGORIES
-- FD: category_id -> {category_name, description}
-- ============================================================
CREATE TABLE Categories (
    category_id   INT          AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(50)  UNIQUE NOT NULL,
    description   TEXT
);

-- ============================================================
-- 3. TAGS
-- FD: tag_id -> {tag_name}
-- ============================================================
CREATE TABLE Tags (
    tag_id   INT         AUTO_INCREMENT PRIMARY KEY,
    tag_name VARCHAR(50) UNIQUE NOT NULL
);

-- ============================================================
-- 4. CHANNELS
-- FD: channel_id -> {user_id, channel_name, description,
--     subscriber_count, total_views, created_at, is_verified}
-- NOTE: subscriber_count & total_views are denormalized caches
--       maintained by TRIGGERS for performance.
-- ============================================================
CREATE TABLE Channels (
    channel_id       INT           AUTO_INCREMENT PRIMARY KEY,
    user_id          INT           NOT NULL,
    channel_name     VARCHAR(100)  UNIQUE NOT NULL,
    description      TEXT,
    subscriber_count INT           DEFAULT 0,
    total_views      BIGINT        DEFAULT 0,
    created_at       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    is_verified      BOOLEAN       DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- ============================================================
-- 5. VIDEOS
-- FD: video_id -> {channel_id, category_id, title, description,
--     duration_seconds, view_count, like_count, dislike_count,
--     comment_count, upload_date, is_public, allows_comments,
--     resolution, file_size_mb, thumbnail_url}
-- NOTE: view_count, like_count, dislike_count, comment_count
--       are denormalized caches maintained by TRIGGERS.
-- ============================================================
CREATE TABLE Videos (
    video_id         INT            AUTO_INCREMENT PRIMARY KEY,
    channel_id       INT            NOT NULL,
    category_id      INT,
    title            VARCHAR(200)   NOT NULL,
    description      TEXT,
    duration_seconds INT            NOT NULL DEFAULT 0,
    view_count       BIGINT         DEFAULT 0,
    like_count       INT            DEFAULT 0,
    dislike_count    INT            DEFAULT 0,
    comment_count    INT            DEFAULT 0,
    upload_date      TIMESTAMP      DEFAULT CURRENT_TIMESTAMP,
    is_public        BOOLEAN        DEFAULT TRUE,
    allows_comments  BOOLEAN        DEFAULT TRUE,
    resolution       VARCHAR(10),
    file_size_mb     DECIMAL(10,2),
    thumbnail_url    VARCHAR(500),
    FOREIGN KEY (channel_id)  REFERENCES Channels(channel_id)  ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES Categories(category_id) ON DELETE SET NULL
);

-- ============================================================
-- 6. PLAYLISTS
-- FD: playlist_id -> {user_id, playlist_name, description,
--     is_public, created_at, updated_at}
-- ============================================================
CREATE TABLE Playlists (
    playlist_id   INT          AUTO_INCREMENT PRIMARY KEY,
    user_id       INT          NOT NULL,
    playlist_name VARCHAR(100) NOT NULL,
    description   TEXT,
    is_public     BOOLEAN      DEFAULT TRUE,
    created_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- ============================================================
-- 7. PLAYLIST_VIDEOS (Junction)
-- FD: (playlist_id, video_id) -> {position, added_at}
-- 2NF: position depends on BOTH playlist_id AND video_id
-- ============================================================
CREATE TABLE Playlist_Videos (
    playlist_video_id INT       AUTO_INCREMENT PRIMARY KEY,
    playlist_id       INT       NOT NULL,
    video_id          INT       NOT NULL,
    position          INT       NOT NULL,
    added_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (playlist_id) REFERENCES Playlists(playlist_id) ON DELETE CASCADE,
    FOREIGN KEY (video_id)    REFERENCES Videos(video_id)       ON DELETE CASCADE,
    UNIQUE KEY unique_playlist_video (playlist_id, video_id)
);

-- ============================================================
-- 8. COMMENTS
-- FD: comment_id -> {video_id, user_id, parent_comment_id,
--     comment_text, like_count, dislike_count, created_at,
--     updated_at, is_edited}
-- Self-referencing FK enables threaded replies
-- ============================================================
CREATE TABLE Comments (
    comment_id        INT       AUTO_INCREMENT PRIMARY KEY,
    video_id          INT       NOT NULL,
    user_id           INT       NOT NULL,
    parent_comment_id INT       NULL,
    comment_text      TEXT      NOT NULL,
    like_count        INT       DEFAULT 0,
    dislike_count     INT       DEFAULT 0,
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_edited         BOOLEAN   DEFAULT FALSE,
    FOREIGN KEY (video_id)          REFERENCES Videos(video_id)     ON DELETE CASCADE,
    FOREIGN KEY (user_id)           REFERENCES Users(user_id)       ON DELETE CASCADE,
    FOREIGN KEY (parent_comment_id) REFERENCES Comments(comment_id) ON DELETE CASCADE
);

-- ============================================================
-- 9. SUBSCRIPTIONS
-- FD: (user_id, channel_id) -> {subscribed_at, notifications_enabled}
-- ============================================================
CREATE TABLE Subscriptions (
    subscription_id       INT       AUTO_INCREMENT PRIMARY KEY,
    user_id               INT       NOT NULL,
    channel_id            INT       NOT NULL,
    subscribed_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notifications_enabled BOOLEAN   DEFAULT TRUE,
    FOREIGN KEY (user_id)    REFERENCES Users(user_id)       ON DELETE CASCADE,
    FOREIGN KEY (channel_id) REFERENCES Channels(channel_id) ON DELETE CASCADE,
    UNIQUE KEY unique_subscription (user_id, channel_id)
);

-- ============================================================
-- 10. VIDEO_LIKES
-- FD: (video_id, user_id) -> {is_like, created_at}
-- ============================================================
CREATE TABLE Video_Likes (
    video_like_id INT       AUTO_INCREMENT PRIMARY KEY,
    video_id      INT       NOT NULL,
    user_id       INT       NOT NULL,
    is_like       BOOLEAN   NOT NULL,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (video_id) REFERENCES Videos(video_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id)  REFERENCES Users(user_id)   ON DELETE CASCADE,
    UNIQUE KEY unique_video_like (video_id, user_id)
);

-- ============================================================
-- 11. COMMENT_LIKES
-- FD: (comment_id, user_id) -> {is_like, created_at}
-- ============================================================
CREATE TABLE Comment_Likes (
    comment_like_id INT       AUTO_INCREMENT PRIMARY KEY,
    comment_id      INT       NOT NULL,
    user_id         INT       NOT NULL,
    is_like         BOOLEAN   NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (comment_id) REFERENCES Comments(comment_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id)    REFERENCES Users(user_id)       ON DELETE CASCADE,
    UNIQUE KEY unique_comment_like (comment_id, user_id)
);

-- ============================================================
-- 12. WATCH_HISTORY
-- FD: watch_id -> {user_id, video_id, watched_at,
--     watch_duration_seconds, completed}
-- Multiple rows allowed per (user_id, video_id) for rewatching
-- ============================================================
CREATE TABLE Watch_History (
    watch_id               INT       AUTO_INCREMENT PRIMARY KEY,
    user_id                INT       NOT NULL,
    video_id               INT       NOT NULL,
    watched_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    watch_duration_seconds INT       DEFAULT 0,
    completed              BOOLEAN   DEFAULT FALSE,
    FOREIGN KEY (user_id)  REFERENCES Users(user_id)   ON DELETE CASCADE,
    FOREIGN KEY (video_id) REFERENCES Videos(video_id) ON DELETE CASCADE
);

-- ============================================================
-- 13. VIDEO_TAGS (Junction)
-- FD: (video_id, tag_id) -> {} pure relationship table
-- ============================================================
CREATE TABLE Video_Tags (
    video_tag_id INT AUTO_INCREMENT PRIMARY KEY,
    video_id     INT NOT NULL,
    tag_id       INT NOT NULL,
    FOREIGN KEY (video_id) REFERENCES Videos(video_id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id)   REFERENCES Tags(tag_id)     ON DELETE CASCADE,
    UNIQUE KEY unique_video_tag (video_id, tag_id)
);

-- ============================================================
-- 14. NOTIFICATIONS
-- FD: notification_id -> {user_id, channel_id, video_id,
--     notification_type, message, is_read, created_at}
-- ============================================================
CREATE TABLE Notifications (
    notification_id   INT          AUTO_INCREMENT PRIMARY KEY,
    user_id           INT          NOT NULL,
    channel_id        INT          NULL,
    video_id          INT          NULL,
    notification_type VARCHAR(50)  NOT NULL,
    message           TEXT,
    is_read           BOOLEAN      DEFAULT FALSE,
    created_at        TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id)    REFERENCES Users(user_id)       ON DELETE CASCADE,
    FOREIGN KEY (channel_id) REFERENCES Channels(channel_id) ON DELETE CASCADE,
    FOREIGN KEY (video_id)   REFERENCES Videos(video_id)     ON DELETE CASCADE
);

-- ============================================================
-- INDEXES for query performance
-- ============================================================
CREATE INDEX idx_videos_channel  ON Videos(channel_id);
CREATE INDEX idx_videos_category ON Videos(category_id);
CREATE INDEX idx_videos_upload   ON Videos(upload_date DESC);
CREATE INDEX idx_videos_views    ON Videos(view_count DESC);
CREATE INDEX idx_comments_video  ON Comments(video_id);
CREATE INDEX idx_comments_parent ON Comments(parent_comment_id);
CREATE INDEX idx_watch_user      ON Watch_History(user_id);
CREATE INDEX idx_watch_video     ON Watch_History(video_id);
CREATE INDEX idx_notif_user      ON Notifications(user_id, is_read);
CREATE INDEX idx_subs_channel    ON Subscriptions(channel_id);
