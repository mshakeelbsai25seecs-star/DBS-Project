-- ============================================================
-- YOUTUBE CLONE DATABASE - STORED PROCEDURES
-- ============================================================
USE youtube_db;

DELIMITER $$

-- ============================================================
-- PROCEDURE 1: sp_register_user
-- OUT p_result: 1=success, -1=username taken, -2=email taken
-- ============================================================
CREATE PROCEDURE sp_register_user(
    IN  p_username      VARCHAR(50),
    IN  p_email         VARCHAR(100),
    IN  p_password_hash VARCHAR(255),
    IN  p_first_name    VARCHAR(50),
    IN  p_last_name     VARCHAR(50),
    IN  p_country       VARCHAR(50),
    OUT p_user_id       INT,
    OUT p_result        INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_result  = -99;
        SET p_user_id = -1;
        ROLLBACK;
    END;

    START TRANSACTION;
    IF EXISTS (SELECT 1 FROM Users WHERE username = p_username) THEN
        SET p_result = -1; SET p_user_id = -1; ROLLBACK;
    ELSEIF EXISTS (SELECT 1 FROM Users WHERE email = p_email) THEN
        SET p_result = -2; SET p_user_id = -1; ROLLBACK;
    ELSE
        INSERT INTO Users (username, email, password_hash, first_name, last_name, country)
        VALUES (p_username, p_email, p_password_hash, p_first_name, p_last_name, p_country);
        SET p_user_id = LAST_INSERT_ID();
        SET p_result  = 1;
        COMMIT;
    END IF;
END$$

-- ============================================================
-- PROCEDURE 2: sp_login_user
-- OUT p_result: 1=success, -1=not found, -2=wrong password
-- ============================================================
CREATE PROCEDURE sp_login_user(
    IN  p_username      VARCHAR(50),
    IN  p_password_hash VARCHAR(255),
    OUT p_user_id       INT,
    OUT p_result        INT
)
BEGIN
    DECLARE v_stored_hash VARCHAR(255);
    DECLARE v_uid         INT;

    SELECT user_id, password_hash
    INTO   v_uid, v_stored_hash
    FROM   Users WHERE username = p_username LIMIT 1;

    IF v_uid IS NULL THEN
        SET p_user_id = -1; SET p_result = -1;
    ELSEIF v_stored_hash != p_password_hash THEN
        SET p_user_id = -1; SET p_result = -2;
    ELSE
        UPDATE Users SET last_login = CURRENT_TIMESTAMP WHERE user_id = v_uid;
        SET p_user_id = v_uid; SET p_result = 1;
        SELECT user_id, username, email, first_name, last_name, country, created_at, last_login
        FROM Users WHERE user_id = v_uid;
    END IF;
END$$

-- ============================================================
-- PROCEDURE 3: sp_upload_video
-- OUT p_result: 1=success, -1=not channel owner
-- ============================================================
CREATE PROCEDURE sp_upload_video(
    IN  p_user_id          INT,
    IN  p_channel_id       INT,
    IN  p_category_id      INT,
    IN  p_title            VARCHAR(200),
    IN  p_description      TEXT,
    IN  p_duration_seconds INT,
    IN  p_resolution       VARCHAR(10),
    IN  p_file_size_mb     DECIMAL(10,2),
    IN  p_thumbnail_url    VARCHAR(500),
    IN  p_is_public        BOOLEAN,
    OUT p_video_id         INT,
    OUT p_result           INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN SET p_result = -2; SET p_video_id = -1; END;

    IF NOT EXISTS (SELECT 1 FROM Channels WHERE channel_id = p_channel_id AND user_id = p_user_id) THEN
        SET p_result = -1; SET p_video_id = -1;
    ELSE
        INSERT INTO Videos (channel_id, category_id, title, description,
            duration_seconds, resolution, file_size_mb, thumbnail_url, is_public)
        VALUES (p_channel_id, p_category_id, p_title, p_description,
            p_duration_seconds, p_resolution, p_file_size_mb, p_thumbnail_url, p_is_public);
        SET p_video_id = LAST_INSERT_ID(); SET p_result = 1;
    END IF;
END$$

-- ============================================================
-- PROCEDURE 4: sp_toggle_subscription
-- OUT p_action: 'subscribed','unsubscribed','own_channel'
-- ============================================================
CREATE PROCEDURE sp_toggle_subscription(
    IN  p_user_id    INT,
    IN  p_channel_id INT,
    OUT p_action     VARCHAR(20),
    OUT p_result     INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN SET p_result = -1; SET p_action = 'error'; END;

    IF EXISTS (SELECT 1 FROM Channels WHERE channel_id = p_channel_id AND user_id = p_user_id) THEN
        SET p_action = 'own_channel'; SET p_result = -2;
    ELSEIF EXISTS (SELECT 1 FROM Subscriptions WHERE user_id = p_user_id AND channel_id = p_channel_id) THEN
        DELETE FROM Subscriptions WHERE user_id = p_user_id AND channel_id = p_channel_id;
        SET p_action = 'unsubscribed'; SET p_result = 1;
    ELSE
        INSERT INTO Subscriptions (user_id, channel_id) VALUES (p_user_id, p_channel_id);
        SET p_action = 'subscribed'; SET p_result = 1;
    END IF;
END$$

-- ============================================================
-- PROCEDURE 5: sp_react_video
-- p_reaction: 1=like, 0=dislike
-- OUT p_action: 'liked','disliked','removed','toggled'
-- ============================================================
CREATE PROCEDURE sp_react_video(
    IN  p_user_id  INT,
    IN  p_video_id INT,
    IN  p_reaction TINYINT,
    OUT p_action   VARCHAR(20),
    OUT p_result   INT
)
BEGIN
    DECLARE v_existing TINYINT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN SET p_result = -1; SET p_action = 'error'; END;

    SELECT is_like INTO v_existing
    FROM Video_Likes WHERE user_id = p_user_id AND video_id = p_video_id;

    IF v_existing IS NULL THEN
        INSERT INTO Video_Likes (video_id, user_id, is_like) VALUES (p_video_id, p_user_id, p_reaction);
        SET p_action = IF(p_reaction = 1, 'liked', 'disliked'); SET p_result = 1;
    ELSEIF v_existing = p_reaction THEN
        DELETE FROM Video_Likes WHERE user_id = p_user_id AND video_id = p_video_id;
        SET p_action = 'removed'; SET p_result = 1;
    ELSE
        UPDATE Video_Likes SET is_like = p_reaction WHERE user_id = p_user_id AND video_id = p_video_id;
        SET p_action = 'toggled'; SET p_result = 1;
    END IF;
END$$

-- ============================================================
-- PROCEDURE 6: sp_add_comment
-- OUT p_result: 1=success, -2=comments disabled
-- ============================================================
CREATE PROCEDURE sp_add_comment(
    IN  p_video_id          INT,
    IN  p_user_id           INT,
    IN  p_parent_comment_id INT,
    IN  p_comment_text      TEXT,
    OUT p_comment_id        INT,
    OUT p_result            INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN SET p_result = -1; SET p_comment_id = -1; END;

    IF NOT EXISTS (SELECT 1 FROM Videos WHERE video_id = p_video_id AND allows_comments = TRUE) THEN
        SET p_result = -2; SET p_comment_id = -1;
    ELSE
        INSERT INTO Comments (video_id, user_id, parent_comment_id, comment_text)
        VALUES (p_video_id, p_user_id, p_parent_comment_id, p_comment_text);
        SET p_comment_id = LAST_INSERT_ID(); SET p_result = 1;
    END IF;
END$$

-- ============================================================
-- PROCEDURE 7: sp_record_watch
-- ============================================================
CREATE PROCEDURE sp_record_watch(
    IN  p_user_id                INT,
    IN  p_video_id               INT,
    IN  p_watch_duration_seconds INT,
    IN  p_completed              BOOLEAN,
    OUT p_result                 INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET p_result = -1; END;
    INSERT INTO Watch_History (user_id, video_id, watch_duration_seconds, completed)
    VALUES (p_user_id, p_video_id, p_watch_duration_seconds, p_completed);
    SET p_result = 1;
END$$

-- ============================================================
-- PROCEDURE 8: sp_search_videos
-- ============================================================
CREATE PROCEDURE sp_search_videos(
    IN p_query       VARCHAR(200),
    IN p_category_id INT,
    IN p_limit       INT,
    IN p_offset      INT
)
BEGIN
    SET @q = CONCAT('%', p_query, '%');
    IF p_category_id IS NULL OR p_category_id = 0 THEN
        SELECT vd.video_id, vd.title, vd.channel_name, vd.category_name,
               vd.view_count_formatted, vd.duration_formatted,
               vd.like_count, vd.comment_count, vd.upload_date,
               vd.thumbnail_url, vd.is_verified
        FROM vw_video_details vd
        WHERE vd.title LIKE @q OR vd.description LIKE @q
        ORDER BY vd.view_count DESC LIMIT p_limit OFFSET p_offset;
    ELSE
        SELECT vd.video_id, vd.title, vd.channel_name, vd.category_name,
               vd.view_count_formatted, vd.duration_formatted,
               vd.like_count, vd.comment_count, vd.upload_date,
               vd.thumbnail_url, vd.is_verified
        FROM vw_video_details vd
        WHERE (vd.title LIKE @q OR vd.description LIKE @q)
          AND vd.category_id = p_category_id
        ORDER BY vd.view_count DESC LIMIT p_limit OFFSET p_offset;
    END IF;
END$$

-- ============================================================
-- PROCEDURE 9: sp_get_user_feed
-- Returns videos from subscribed channels
-- ============================================================
CREATE PROCEDURE sp_get_user_feed(
    IN p_user_id INT,
    IN p_limit   INT,
    IN p_offset  INT
)
BEGIN
    SELECT vd.video_id, vd.title, vd.channel_id, vd.channel_name,
           vd.view_count_formatted, vd.duration_formatted,
           vd.upload_date, vd.thumbnail_url, vd.is_verified, vd.like_count
    FROM vw_video_details vd
    WHERE vd.channel_id IN (
        SELECT channel_id FROM Subscriptions WHERE user_id = p_user_id
    )
    ORDER BY vd.upload_date DESC
    LIMIT p_limit OFFSET p_offset;
END$$

-- ============================================================
-- PROCEDURE 10: sp_create_channel
-- OUT p_result: 1=success, -2=name taken
-- ============================================================
CREATE PROCEDURE sp_create_channel(
    IN  p_user_id      INT,
    IN  p_channel_name VARCHAR(100),
    IN  p_description  TEXT,
    OUT p_channel_id   INT,
    OUT p_result       INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN SET p_result = -1; SET p_channel_id = -1; END;

    IF EXISTS (SELECT 1 FROM Channels WHERE channel_name = p_channel_name) THEN
        SET p_result = -2; SET p_channel_id = -1;
    ELSE
        INSERT INTO Channels (user_id, channel_name, description)
        VALUES (p_user_id, p_channel_name, p_description);
        SET p_channel_id = LAST_INSERT_ID(); SET p_result = 1;
    END IF;
END$$

-- ============================================================
-- PROCEDURE 11: sp_mark_notifications_read
-- ============================================================
CREATE PROCEDURE sp_mark_notifications_read(IN p_user_id INT)
BEGIN
    UPDATE Notifications
    SET is_read = TRUE
    WHERE user_id = p_user_id AND is_read = FALSE;
END$$

-- ============================================================
-- PROCEDURE 12: sp_get_video_page
-- Returns video details + comments + suggested
-- ============================================================
CREATE PROCEDURE sp_get_video_page(
    IN p_video_id INT,
    IN p_user_id  INT
)
BEGIN
    SELECT vd.*,
           fn_get_video_like_status(p_user_id, p_video_id) AS user_reaction,
           fn_is_subscribed(p_user_id, vd.channel_id)      AS user_subscribed
    FROM vw_video_details vd WHERE vd.video_id = p_video_id;

    SELECT * FROM vw_comment_threads WHERE video_id = p_video_id
    ORDER BY like_count DESC, created_at DESC LIMIT 50;

    SELECT video_id, title, channel_name, view_count_formatted,
           duration_formatted, thumbnail_url, is_verified
    FROM vw_video_details WHERE video_id != p_video_id
    ORDER BY view_count DESC LIMIT 10;
END$$

DELIMITER ;
