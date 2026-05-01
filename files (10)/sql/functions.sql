-- ============================================================
-- YOUTUBE CLONE DATABASE - FUNCTIONS
-- ============================================================
USE youtube_db;

DELIMITER $$

-- ============================================================
-- FUNCTION 1: fn_format_duration
-- Converts seconds to H:MM:SS or M:SS
-- Example: 3661 -> "1:01:01", 245 -> "4:05"
-- ============================================================
CREATE FUNCTION fn_format_duration(seconds INT)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE h INT;
    DECLARE m INT;
    DECLARE s INT;
    SET h = FLOOR(seconds / 3600);
    SET m = FLOOR((seconds MOD 3600) / 60);
    SET s = seconds MOD 60;
    IF h > 0 THEN
        RETURN CONCAT(h, ':', LPAD(m, 2, '0'), ':', LPAD(s, 2, '0'));
    ELSE
        RETURN CONCAT(m, ':', LPAD(s, 2, '0'));
    END IF;
END$$

-- ============================================================
-- FUNCTION 2: fn_is_subscribed
-- Returns 1 if user is subscribed to channel, else 0
-- ============================================================
CREATE FUNCTION fn_is_subscribed(p_user_id INT, p_channel_id INT)
RETURNS TINYINT(1)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE result TINYINT(1);
    SELECT COUNT(*) INTO result
    FROM Subscriptions
    WHERE user_id = p_user_id AND channel_id = p_channel_id;
    RETURN result;
END$$

-- ============================================================
-- FUNCTION 3: fn_get_watch_percentage
-- Returns 0-100 percentage of video watched by user
-- ============================================================
CREATE FUNCTION fn_get_watch_percentage(p_user_id INT, p_video_id INT)
RETURNS DECIMAL(5,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE watched INT;
    DECLARE total   INT;
    SELECT watch_duration_seconds INTO watched
    FROM Watch_History
    WHERE user_id = p_user_id AND video_id = p_video_id
    ORDER BY watched_at DESC LIMIT 1;
    SELECT duration_seconds INTO total
    FROM Videos WHERE video_id = p_video_id;
    IF total IS NULL OR total = 0 OR watched IS NULL THEN
        RETURN 0.00;
    END IF;
    RETURN LEAST(100.00, ROUND((watched / total) * 100, 2));
END$$

-- ============================================================
-- FUNCTION 4: fn_format_count
-- Formats large numbers: 1500000 -> "1.5M", 23000 -> "23K"
-- ============================================================
CREATE FUNCTION fn_format_count(n BIGINT)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    IF n >= 1000000000 THEN
        RETURN CONCAT(ROUND(n / 1000000000, 1), 'B');
    ELSEIF n >= 1000000 THEN
        RETURN CONCAT(ROUND(n / 1000000, 1), 'M');
    ELSEIF n >= 1000 THEN
        RETURN CONCAT(ROUND(n / 1000, 1), 'K');
    ELSE
        RETURN CAST(n AS CHAR);
    END IF;
END$$

-- ============================================================
-- FUNCTION 5: fn_get_video_like_status
-- Returns: 1=liked, -1=disliked, 0=no reaction
-- ============================================================
CREATE FUNCTION fn_get_video_like_status(p_user_id INT, p_video_id INT)
RETURNS TINYINT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE liked TINYINT;
    SELECT is_like INTO liked
    FROM Video_Likes
    WHERE user_id = p_user_id AND video_id = p_video_id
    LIMIT 1;
    IF liked IS NULL THEN RETURN 0;
    ELSEIF liked = 1 THEN RETURN 1;
    ELSE RETURN -1;
    END IF;
END$$

DELIMITER ;
