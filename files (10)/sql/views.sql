-- ============================================================
-- YOUTUBE CLONE DATABASE - VIEWS
-- ============================================================
USE youtube_db;

-- ============================================================
-- VIEW 1: vw_video_details
-- Joins Videos with Channels, Categories, owner Users
-- Used by: Home page, Video page, Search results
-- ============================================================
CREATE OR REPLACE VIEW vw_video_details AS
SELECT
    v.video_id,
    v.title,
    v.description,
    v.duration_seconds,
    fn_format_duration(v.duration_seconds)  AS duration_formatted,
    v.view_count,
    fn_format_count(v.view_count)           AS view_count_formatted,
    v.like_count,
    v.dislike_count,
    v.comment_count,
    v.upload_date,
    v.is_public,
    v.allows_comments,
    v.resolution,
    v.file_size_mb,
    v.thumbnail_url,
    v.channel_id,
    c.channel_name,
    c.subscriber_count,
    fn_format_count(c.subscriber_count)     AS sub_count_formatted,
    c.is_verified,
    c.user_id                               AS owner_user_id,
    u.username                              AS owner_username,
    v.category_id,
    cat.category_name
FROM Videos v
JOIN Channels   c   ON v.channel_id  = c.channel_id
JOIN Users      u   ON c.user_id     = u.user_id
LEFT JOIN Categories cat ON v.category_id = cat.category_id
WHERE v.is_public = TRUE;

-- ============================================================
-- VIEW 2: vw_trending_videos
-- Top 50 videos by trending score: views + 5*likes + 3*comments
-- Used by: Home/Trending page
-- ============================================================
CREATE OR REPLACE VIEW vw_trending_videos AS
SELECT
    vd.*,
    (vd.view_count + (5 * vd.like_count) + (3 * vd.comment_count)) AS trending_score
FROM vw_video_details vd
ORDER BY trending_score DESC
LIMIT 50;

-- ============================================================
-- VIEW 3: vw_channel_stats
-- Channel overview with video count and owner info
-- Used by: Channel page, Subscription list
-- ============================================================
CREATE OR REPLACE VIEW vw_channel_stats AS
SELECT
    c.channel_id,
    c.channel_name,
    c.description,
    c.subscriber_count,
    fn_format_count(c.subscriber_count)  AS sub_count_formatted,
    c.total_views,
    fn_format_count(c.total_views)       AS total_views_formatted,
    c.created_at,
    c.is_verified,
    c.user_id,
    u.username,
    u.first_name,
    u.last_name,
    COUNT(v.video_id)                    AS video_count,
    MAX(v.upload_date)                   AS last_upload_date
FROM Channels c
JOIN Users  u ON c.user_id    = u.user_id
LEFT JOIN Videos v ON v.channel_id = c.channel_id AND v.is_public = TRUE
GROUP BY c.channel_id, c.channel_name, c.description,
         c.subscriber_count, c.total_views, c.created_at, c.is_verified,
         c.user_id, u.username, u.first_name, u.last_name;

-- ============================================================
-- VIEW 4: vw_comment_threads
-- Top-level comments with reply counts
-- Used by: Video page comment section
-- ============================================================
CREATE OR REPLACE VIEW vw_comment_threads AS
SELECT
    c.comment_id,
    c.video_id,
    c.user_id,
    u.username,
    c.parent_comment_id,
    c.comment_text,
    c.like_count,
    c.dislike_count,
    c.created_at,
    c.updated_at,
    c.is_edited,
    COUNT(r.comment_id) AS reply_count
FROM Comments c
JOIN Users u ON c.user_id = u.user_id
LEFT JOIN Comments r ON r.parent_comment_id = c.comment_id
WHERE c.parent_comment_id IS NULL
GROUP BY c.comment_id, c.video_id, c.user_id, u.username,
         c.parent_comment_id, c.comment_text, c.like_count,
         c.dislike_count, c.created_at, c.updated_at, c.is_edited;

-- ============================================================
-- VIEW 5: vw_user_subscriptions
-- All channels a user subscribed to with latest video info
-- Used by: Subscriptions page
-- ============================================================
CREATE OR REPLACE VIEW vw_user_subscriptions AS
SELECT
    s.user_id,
    s.channel_id,
    s.subscribed_at,
    s.notifications_enabled,
    cs.channel_name,
    cs.sub_count_formatted,
    cs.is_verified,
    cs.video_count,
    cs.last_upload_date,
    cs.username AS owner_username
FROM Subscriptions s
JOIN vw_channel_stats cs ON s.channel_id = cs.channel_id;

-- ============================================================
-- VIEW 6: vw_watch_history_details
-- User watch history enriched with video and channel info
-- Used by: Watch History page
-- ============================================================
CREATE OR REPLACE VIEW vw_watch_history_details AS
SELECT
    wh.watch_id,
    wh.user_id,
    wh.watched_at,
    wh.watch_duration_seconds,
    wh.completed,
    v.video_id,
    v.title,
    v.duration_seconds,
    fn_format_duration(v.duration_seconds) AS duration_formatted,
    v.thumbnail_url,
    c.channel_id,
    c.channel_name,
    c.is_verified,
    LEAST(100.00,
        CASE WHEN v.duration_seconds > 0
             THEN ROUND((wh.watch_duration_seconds / v.duration_seconds) * 100, 1)
             ELSE 0 END
    ) AS watch_percentage
FROM Watch_History wh
JOIN Videos   v ON wh.video_id  = v.video_id
JOIN Channels c ON v.channel_id = c.channel_id;
