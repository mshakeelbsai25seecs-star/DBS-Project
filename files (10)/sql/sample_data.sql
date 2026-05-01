-- ============================================================
-- YOUTUBE CLONE DATABASE - SAMPLE DATA
-- ============================================================
USE youtube_db;

-- USERS (password = SHA256 of 'password123')
INSERT INTO Users (username, email, password_hash, first_name, last_name, date_of_birth, country, created_at, last_login) VALUES
('ali_hussain',      'ali.hussain@email.com',   'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', 'Ali',      'Hussain',  '1990-05-15', 'Pakistan',       '2023-01-10 08:00:00', '2024-04-15 10:30:00'),
('sarah_tech',       'sarah.tech@email.com',     'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', 'Sarah',    'Ahmed',    '1995-08-22', 'United States',  '2023-02-14 09:15:00', '2024-04-17 14:20:00'),
('umar_gamer',       'umar.games@email.com',     'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', 'Umar',     'Khan',     '1998-11-03', 'United Kingdom', '2023-03-20 11:00:00', '2024-04-18 09:45:00'),
('dr_history',       'history.prof@email.com',   'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', 'Muhammad', 'Farooq',   '1985-03-12', 'Egypt',          '2023-01-25 07:30:00', '2024-04-16 16:00:00'),
('productivity_pro', 'prod.master@email.com',    'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', 'Fatima',   'Zahra',    '1992-07-19', 'Canada',         '2023-04-05 10:45:00', '2024-04-17 11:15:00'),
('tech_reviewer',    'tech.review@email.com',    'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', 'Ahmed',    'Malik',    '1994-12-08', 'Pakistan',       '2023-02-28 12:00:00', '2024-04-18 08:30:00'),
('islamic_scholar',  'scholar@email.com',        'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', 'Yusuf',    'Ibrahim',  '1988-06-25', 'Saudi Arabia',   '2023-01-15 06:00:00', '2024-04-15 17:00:00'),
('coding_mentor',    'code.teach@email.com',     'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', 'Zainab',   'Ali',      '1996-09-30', 'Pakistan',       '2023-03-10 13:30:00', '2024-04-16 12:45:00'),
('strategy_gamer',   'strategy.pro@email.com',   'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', 'Hassan',   'Raza',     '1997-04-17', 'Turkey',         '2023-04-12 15:00:00', '2024-04-17 19:30:00'),
('world_history',    'world.hist@email.com',     'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', 'Aisha',    'Siddiqui', '1991-10-11', 'India',          '2023-02-20 08:45:00', '2024-04-18 07:15:00'),
('viewer_one',       'viewer1@email.com',        'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', 'Omar',     'Abdullah', '2000-01-05', 'Pakistan',       '2023-05-01 10:00:00', '2024-04-18 11:00:00'),
('viewer_two',       'viewer2@email.com',        'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', 'Maryam',   'Noor',     '1999-03-14', 'Malaysia',       '2023-05-15 11:30:00', '2024-04-17 13:45:00'),
('viewer_three',     'viewer3@email.com',        'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', 'Ibrahim',  'Yousuf',   '2001-07-22', 'Indonesia',      '2023-06-01 09:00:00', '2024-04-16 15:20:00'),
('viewer_four',      'viewer4@email.com',        'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', 'Khadija',  'Hassan',   '1998-11-28', 'Pakistan',       '2023-06-20 14:15:00', '2024-04-18 10:10:00'),
('viewer_five',      'viewer5@email.com',        'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', 'Bilal',    'Iqbal',    '2002-02-09', 'UAE',            '2023-07-10 16:45:00', '2024-04-17 12:30:00');

-- CATEGORIES
INSERT INTO Categories (category_name, description) VALUES
('Technology',     'Technology reviews, tutorials, and news'),
('Productivity',   'Time management, organization, and efficiency tips'),
('Gaming',         'Video game content, tutorials, and reviews'),
('Islamic Studies','Islamic teachings, Quran, Hadith, and Islamic history'),
('History',        'Historical events, civilizations, and documentaries'),
('Education',      'Educational content and tutorials'),
('Science',        'Scientific discoveries and explanations'),
('Programming',    'Coding tutorials and software development');

-- TAGS
INSERT INTO Tags (tag_name) VALUES
('tutorial'),('beginner'),('advanced'),('review'),('tips'),
('quran'),('hadith'),('islamic-history'),('ottoman-empire'),('world-war'),
('python'),('javascript'),('productivity-hacks'),('time-management'),
('strategy-games'),('fps'),('tech-review'),('smartphone'),('ai'),('machine-learning');

-- CHANNELS
INSERT INTO Channels (user_id, channel_name, description, subscriber_count, total_views, is_verified) VALUES
(1,  'Islamic Knowledge Hub',  'Authentic Islamic teachings, Quran tafsir, and hadith explanations', 125000, 5400000, TRUE),
(2,  'Tech Mastery',           'In-depth technology reviews and tutorials',                          89000,  3200000, TRUE),
(3,  'Pro Gaming Strategies',  'Advanced gaming tactics and competitive gameplay',                   156000, 7800000, TRUE),
(4,  'History Unveiled',       'Exploring world history with detailed documentaries',                203000, 9500000, TRUE),
(5,  'Productivity Blueprint', 'Master your time and achieve your goals',                            67000,  2100000, FALSE),
(6,  'Tech Reviews Daily',     'Latest gadget reviews and tech news',                                45000,  1800000, FALSE),
(7,  'Quranic Reflections',    'Deep dive into Quranic verses and their meanings',                   98000,  4300000, TRUE),
(8,  'Code Academy',           'Learn programming from scratch to advanced',                         112000, 5600000, TRUE),
(9,  'Strategy Masters',       'Strategy game tutorials and competitive play',                       78000,  3400000, FALSE),
(10, 'World History Archive',  'Comprehensive world history documentary series',                     145000, 6700000, TRUE);

-- VIDEOS
INSERT INTO Videos (channel_id, category_id, title, description, duration_seconds, view_count, like_count, dislike_count, comment_count, resolution, file_size_mb, is_public, allows_comments) VALUES
(1,  4, 'Understanding Surah Al-Fatiha - Complete Tafsir',       'A comprehensive explanation of the opening chapter of the Quran',              2340, 245000, 18500,  320, 1240, '1080p',  892.50, TRUE, TRUE),
(1,  4, 'The Life of Prophet Muhammad (PBUH) - Part 1',          'Detailed biography covering the early life and prophethood',                   3120, 189000, 15200,  280,  980, '1080p', 1205.30, TRUE, TRUE),
(2,  1, 'Python for Data Science - Complete Tutorial 2024',      'Learn Python programming for data science applications',                       4560, 156000, 12400,  450, 2100, '1080p', 1680.75, TRUE, TRUE),
(2,  8, 'Machine Learning Fundamentals Explained Simply',        'Breaking down complex ML concepts into easy segments',                         1920,  98000,  8900,  210,  760, '1080p',  745.20, TRUE, TRUE),
(3,  3, 'Age of Empires IV - Advanced Strategy Guide',           'Master civilization management and military tactics',                          2880, 234000, 19800,  520, 1890, '1080p', 1125.40, TRUE, TRUE),
(3,  3, 'Counter-Strike 2 - Aim Training and Map Control',       'Improve your aim and learn map positioning',                                   1680, 167000, 14200,  380, 1450, '1080p',  680.90, TRUE, TRUE),
(4,  5, 'The Ottoman Empire - Rise and Fall',                    'Complete documentary on the 600-year Ottoman Empire history',                  5400, 432000, 34500,  890, 3200, '1080p', 2140.60, TRUE, TRUE),
(4,  5, 'World War II - The Eastern Front Explained',            'Detailed analysis of the Eastern Front battles and strategies',                4200, 389000, 31200,  720, 2890, '1080p', 1678.30, TRUE, TRUE),
(5,  2, 'Time Blocking Method - Get 10x More Done',             'Learn the time blocking technique used by successful entrepreneurs',             960,  78000,  7200,  150,  540, '1080p',  385.20, TRUE, TRUE),
(5,  2, 'Building a Second Brain - Complete System',            'Organize your digital life and never forget important information',             2160,  92000,  8500,  180,  680, '1080p',  845.70, TRUE, TRUE),
(6,  1, 'iPhone 15 Pro Max - Honest Review After 3 Months',     'Real-world usage review covering performance, camera, and battery',            1440,  67000,  5800,  420,  890, '1080p',  562.40, TRUE, TRUE),
(7,  4, 'Tafsir of Surah Yaseen - Heart of the Quran',          'Verse-by-verse explanation with spiritual lessons',                            2760, 178000, 16800,  240, 1120, '1080p', 1085.90, TRUE, TRUE),
(8,  8, 'JavaScript Full Course - Beginner to Advanced',         'Complete JavaScript tutorial covering ES6+ and modern development',            6240, 234000, 21400,  680, 3450, '1080p', 2456.80, TRUE, TRUE),
(9,  3, 'Civilization VI - Science Victory Complete Guide',      'Step-by-step guide to achieving science victory',                             2520, 145000, 13200,  340, 1260, '1080p',  990.50, TRUE, TRUE),
(10, 5, 'The Islamic Golden Age - Scientific Achievements',      'Exploring scientific contributions of the Islamic Golden Age',                 3360, 267000, 24500,  410, 1890, '1080p', 1345.20, TRUE, TRUE);

-- PLAYLISTS
INSERT INTO Playlists (user_id, playlist_name, description, is_public) VALUES
(11, 'Learn Islamic History',     'Collection of Islamic history and civilization videos', TRUE),
(11, 'Programming Journey',       'My learning path for software development',             TRUE),
(12, 'Productivity Master Class', 'Videos to improve productivity and time management',   TRUE),
(13, 'Gaming Tutorials',          'Best strategy game tutorials and guides',               TRUE),
(14, 'Tech Reviews Compilation',  'Latest technology reviews and comparisons',             TRUE),
(15, 'World History Deep Dive',   'Comprehensive historical documentaries',                TRUE);

-- PLAYLIST_VIDEOS
INSERT INTO Playlist_Videos (playlist_id, video_id, position) VALUES
(1, 2, 1),(1, 15, 2),(1, 12, 3),
(2, 3, 1),(2, 4,  2),(2, 13, 3),
(3, 9, 1),(3, 10, 2),
(4, 5, 1),(4, 6,  2),(4, 14, 3),
(5, 11,1),
(6, 7, 1),(6, 8,  2),(6, 15, 3);

-- COMMENTS
INSERT INTO Comments (video_id, user_id, parent_comment_id, comment_text, like_count) VALUES
(1,  11, NULL, 'MashaAllah, excellent explanation of Surah Al-Fatiha. This helped me understand the deeper meanings.', 450),
(1,  12, 1,    'I agree! The linguistic breakdown was particularly enlightening. JazakAllah khair.', 89),
(3,  13, NULL, 'This is exactly what I needed to start my data science journey. Crystal clear explanations!', 320),
(3,  14, NULL, 'Best Python tutorial I have found. The practical examples make it easy to understand.', 267),
(5,  15, NULL, 'Applied these tactics and my win rate improved significantly!', 198),
(7,  11, NULL, 'This documentary on the Ottoman Empire is incredibly well-researched. Outstanding!', 542),
(7,  12, NULL, 'As a history student, I appreciate the academic rigor. Excellent sources cited.', 234),
(9,  13, NULL, 'Time blocking changed my life! Went from constant overwhelm to completing my goals.', 178),
(10, 14, NULL, 'The Second Brain system is a game-changer for students. Wish I learned this earlier.', 156),
(13, 15, NULL, 'Most comprehensive JavaScript course I have seen. Worth every minute of the 6+ hours!', 412),
(13, 11, 10,   'Absolutely! The ES6+ coverage is particularly strong. Great for modern web development.', 67),
(15, 12, NULL, 'Islamic Golden Age contributions are often overlooked. Thank you for highlighting these.', 389),
(6,  13, NULL, 'Your aim training routine actually works! Went from Silver to Gold rank in 3 weeks.', 145),
(11, 14, NULL, 'Honest review without the usual hype. This is why I trust this channel.', 98),
(2,  15, NULL, 'The story of the Prophet (PBUH) is beautifully presented with accurate historical context.', 567);

-- SUBSCRIPTIONS
INSERT INTO Subscriptions (user_id, channel_id, notifications_enabled) VALUES
(11, 1, TRUE),(11, 4, TRUE),(11, 7, TRUE),
(12, 2, TRUE),(12, 5, TRUE),(12, 8, TRUE),
(13, 3, TRUE),(13, 9, TRUE),(13, 2, FALSE),
(14, 5, TRUE),(14, 6, TRUE),(14, 10, TRUE),
(15, 1, TRUE),(15, 4, TRUE),(15, 7, TRUE);

-- VIDEO_LIKES
INSERT INTO Video_Likes (video_id, user_id, is_like) VALUES
(1, 11, TRUE),(1, 12, TRUE),(2, 15, TRUE),
(3, 13, TRUE),(3, 14, TRUE),(5, 15, TRUE),
(5, 13, TRUE),(7, 11, TRUE),(7, 12, TRUE),
(9, 13, TRUE),(10,14, TRUE),(13,15, TRUE),
(13,11, TRUE),(15,12, TRUE),(6, 13, TRUE);

-- COMMENT_LIKES
INSERT INTO Comment_Likes (comment_id, user_id, is_like) VALUES
(1, 12, TRUE),(1, 13, TRUE),(2, 11, TRUE),
(3, 14, TRUE),(3, 15, TRUE),(5, 11, TRUE),
(6, 13, TRUE),(6, 14, TRUE),(8, 15, TRUE),
(10,12, TRUE),(12,13, TRUE),(15,14, TRUE);

-- WATCH_HISTORY
INSERT INTO Watch_History (user_id, video_id, watch_duration_seconds, completed) VALUES
(11, 1,  2340, TRUE),(11, 2,  1850, FALSE),(11, 7,  5400, TRUE),
(12, 3,  4560, TRUE),(12, 4,  1920, TRUE), (13, 5,  2880, TRUE),
(13, 6,  1680, TRUE),(13, 3,  2100, FALSE),(14, 9,   960, TRUE),
(14, 10, 2160, TRUE),(15, 13, 6240, TRUE), (15, 5,  1450, FALSE),
(11, 15, 3360, TRUE),(12, 11, 1440, TRUE), (13, 14, 2520, TRUE);

-- VIDEO_TAGS
INSERT INTO Video_Tags (video_id, tag_id) VALUES
(1, 6),(1, 1),(2, 8),(2, 1),(3, 11),(3, 1),(3, 19),
(4, 19),(4, 20),(4, 1),(5, 15),(5, 3),(6, 16),(6, 1),
(7, 9),(7, 8),(8, 10),(9, 5),(9, 13),(10, 14),(10, 5),
(11, 17),(11, 18),(11, 4),(12, 6),(12, 1),(13, 12),(13, 1),
(13, 3),(14, 15),(14, 3),(15, 8),(15, 2);

-- NOTIFICATIONS
INSERT INTO Notifications (user_id, channel_id, video_id, notification_type, message, is_read) VALUES
(11, 1,    2, 'new_video',   'Islamic Knowledge Hub uploaded: The Life of Prophet Muhammad (PBUH) - Part 1', FALSE),
(12, 2,    4, 'new_video',   'Tech Mastery uploaded: Machine Learning Fundamentals Explained Simply',         TRUE),
(13, 3,    6, 'new_video',   'Pro Gaming Strategies uploaded: Counter-Strike 2 - Aim Training',              FALSE),
(14, 5,   10, 'new_video',   'Productivity Blueprint uploaded: Building a Second Brain - Complete System',   TRUE),
(15, 7,   12, 'new_video',   'Quranic Reflections uploaded: Tafsir of Surah Yaseen',                         FALSE),
(11, NULL, 1, 'new_comment', 'Someone replied to your comment on Understanding Surah Al-Fatiha',             TRUE),
(13, NULL, 3, 'new_comment', 'Your comment received 100 likes!',                                             FALSE),
(12, 4,  NULL,'milestone',   'History Unveiled just hit 200K subscribers!',                                  TRUE);
