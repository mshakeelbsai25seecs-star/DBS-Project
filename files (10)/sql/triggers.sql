-- ============================================================
-- YOUTUBE CLONE DATABASE - TRIGGERS
-- Automatically maintain denormalized counter caches
-- ============================================================
USE youtube_db;

DELIMITER $$

-- TRIGGER 1: After SUBSCRIBE -> increment subscriber_count
CREATE TRIGGER trg_after_subscribe_insert
AFTER INSERT ON Subscriptions
FOR EACH ROW
BEGIN
    UPDATE Channels
    SET subscriber_count = subscriber_count + 1
    WHERE channel_id = NEW.channel_id;
END$$

-- TRIGGER 2: After UNSUBSCRIBE -> decrement subscriber_count
CREATE TRIGGER trg_after_subscribe_delete
AFTER DELETE ON Subscriptions
FOR EACH ROW
BEGIN
    UPDATE Channels
    SET subscriber_count = GREATEST(0, subscriber_count - 1)
    WHERE channel_id = OLD.channel_id;
END$$

-- TRIGGER 3: After VIDEO LIKE/DISLIKE inserted
CREATE TRIGGER trg_after_video_like_insert
AFTER INSERT ON Video_Likes
FOR EACH ROW
BEGIN
    IF NEW.is_like = TRUE THEN
        UPDATE Videos SET like_count    = like_count    + 1 WHERE video_id = NEW.video_id;
    ELSE
        UPDATE Videos SET dislike_count = dislike_count + 1 WHERE video_id = NEW.video_id;
    END IF;
END$$

-- TRIGGER 4: After VIDEO LIKE/DISLIKE toggled (like <-> dislike)
CREATE TRIGGER trg_after_video_like_update
AFTER UPDATE ON Video_Likes
FOR EACH ROW
BEGIN
    IF OLD.is_like != NEW.is_like THEN
        IF NEW.is_like = TRUE THEN
            UPDATE Videos
            SET like_count    = like_count    + 1,
                dislike_count = GREATEST(0, dislike_count - 1)
            WHERE video_id = NEW.video_id;
        ELSE
            UPDATE Videos
            SET dislike_count = dislike_count + 1,
                like_count    = GREATEST(0, like_count - 1)
            WHERE video_id = NEW.video_id;
        END IF;
    END IF;
END$$

-- TRIGGER 5: After VIDEO LIKE/DISLIKE removed
CREATE TRIGGER trg_after_video_like_delete
AFTER DELETE ON Video_Likes
FOR EACH ROW
BEGIN
    IF OLD.is_like = TRUE THEN
        UPDATE Videos SET like_count    = GREATEST(0, like_count    - 1) WHERE video_id = OLD.video_id;
    ELSE
        UPDATE Videos SET dislike_count = GREATEST(0, dislike_count - 1) WHERE video_id = OLD.video_id;
    END IF;
END$$

-- TRIGGER 6: After COMMENT inserted -> increment comment_count
CREATE TRIGGER trg_after_comment_insert
AFTER INSERT ON Comments
FOR EACH ROW
BEGIN
    UPDATE Videos
    SET comment_count = comment_count + 1
    WHERE video_id = NEW.video_id;
END$$

-- TRIGGER 7: After COMMENT deleted -> decrement comment_count
CREATE TRIGGER trg_after_comment_delete
AFTER DELETE ON Comments
FOR EACH ROW
BEGIN
    UPDATE Videos
    SET comment_count = GREATEST(0, comment_count - 1)
    WHERE video_id = OLD.video_id;
END$$

-- TRIGGER 8: After WATCH inserted -> increment view_count + channel total_views
CREATE TRIGGER trg_after_watch_insert
AFTER INSERT ON Watch_History
FOR EACH ROW
BEGIN
    UPDATE Videos
    SET view_count = view_count + 1
    WHERE video_id = NEW.video_id;

    UPDATE Channels c
    JOIN Videos v ON v.channel_id = c.channel_id
    SET c.total_views = c.total_views + 1
    WHERE v.video_id = NEW.video_id;
END$$

-- TRIGGER 9: After COMMENT_LIKE inserted
CREATE TRIGGER trg_after_comment_like_insert
AFTER INSERT ON Comment_Likes
FOR EACH ROW
BEGIN
    IF NEW.is_like = TRUE THEN
        UPDATE Comments SET like_count    = like_count    + 1 WHERE comment_id = NEW.comment_id;
    ELSE
        UPDATE Comments SET dislike_count = dislike_count + 1 WHERE comment_id = NEW.comment_id;
    END IF;
END$$

-- TRIGGER 10: After COMMENT_LIKE deleted
CREATE TRIGGER trg_after_comment_like_delete
AFTER DELETE ON Comment_Likes
FOR EACH ROW
BEGIN
    IF OLD.is_like = TRUE THEN
        UPDATE Comments SET like_count    = GREATEST(0, like_count    - 1) WHERE comment_id = OLD.comment_id;
    ELSE
        UPDATE Comments SET dislike_count = GREATEST(0, dislike_count - 1) WHERE comment_id = OLD.comment_id;
    END IF;
END$$

-- TRIGGER 11: After VIDEO uploaded -> notify all subscribers
CREATE TRIGGER trg_after_video_upload_notify
AFTER INSERT ON Videos
FOR EACH ROW
BEGIN
    INSERT INTO Notifications (user_id, channel_id, video_id, notification_type, message)
    SELECT s.user_id,
           NEW.channel_id,
           NEW.video_id,
           'new_video',
           CONCAT((SELECT channel_name FROM Channels WHERE channel_id = NEW.channel_id),
                  ' uploaded: ', NEW.title)
    FROM Subscriptions s
    WHERE s.channel_id = NEW.channel_id
      AND s.notifications_enabled = TRUE;
END$$

DELIMITER ;
