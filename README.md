# ViewTube — YouTube Clone Database System

> A full-stack YouTube clone built as a Database Systems semester project, featuring a complete MySQL backend with Views, Stored Procedures, Functions, Triggers, and full normalization (1NF, 2NF, 3NF), paired with a Flask web application and a YouTube-inspired dark theme UI.

---

## Project Overview

ViewTube is a fully functional video-sharing platform built to demonstrate advanced database design principles. Every feature — from subscribing to a channel to liking a comment — is backed by a carefully normalized MySQL schema with automated trigger-based cache maintenance, reusable stored procedures, and analytical views.

---

## Features

- **User Authentication** — Register, login, logout with SHA-256 password hashing
- **Video Upload & Streaming** — Real file upload with live XHR progress bar, HTTP range-based streaming (supports seeking)
- **Video Player** — Native HTML5 player with play/pause, seek, volume, fullscreen, and picture-in-picture
- **Likes & Dislikes** — Toggle reactions, counts updated instantly via MySQL triggers
- **Comments & Replies** — Threaded comment system with nested replies
- **Subscribe / Unsubscribe** — One-click channel subscription with live subscriber count update
- **Watch History** — Tracks every video watched with percentage progress bar
- **Notifications** — Auto-generated on new uploads to subscribed channels
- **Search** — Full title + description search with category filtering
- **Channel Pages** — Per-channel video gallery with stats
- **Subscription Feed** — Personalized feed from subscribed channels
- **Profile Page** — User info, owned channels, quick links
- **Trending Algorithm** — Score = views + (5 × likes) + (3 × comments)
- **Category Filtering** — Filter home feed and search by content category
- **Responsive UI** — YouTube-style dark theme, works on desktop and mobile

---

## Database Design

### Tables (14)

| Table | Description |
|---|---|
| `Users` | Registered users with hashed passwords |
| `Channels` | User-owned channels with cached stats |
| `Videos` | Video metadata with denormalized counters |
| `Categories` | Content categories (Technology, Gaming, etc.) |
| `Tags` | Video tags |
| `Video_Tags` | Junction: Videos ↔ Tags |
| `Playlists` | User-created playlists |
| `Playlist_Videos` | Junction: Playlists ↔ Videos with position |
| `Comments` | Threaded comments with self-referencing FK |
| `Subscriptions` | User ↔ Channel subscriptions |
| `Video_Likes` | Per-user like/dislike on videos |
| `Comment_Likes` | Per-user like/dislike on comments |
| `Watch_History` | Watch events with duration tracking |
| `Notifications` | Auto-generated system notifications |

### Normalization

- **1NF** — All attributes are atomic, no repeating groups
- **2NF** — No partial dependencies; all junction tables have composite keys where every non-key attribute depends on the full composite key (e.g. `Playlist_Videos.position` depends on both `playlist_id` AND `video_id`)
- **3NF** — No transitive dependencies; category names, tag names, and usernames each live in their own tables, never duplicated in Videos or Comments

### Functional Dependencies (key examples)

```
user_id      → username, email, password_hash, first_name, last_name, country, created_at
channel_id   → user_id, channel_name, description, subscriber_count, total_views
video_id     → channel_id, category_id, title, description, duration_seconds, view_count
(video_id, user_id) → is_like, created_at          [Video_Likes]
(playlist_id, video_id) → position, added_at        [Playlist_Videos]
(user_id, channel_id) → subscribed_at               [Subscriptions]
```

### Views (6)

| View | Purpose |
|---|---|
| `vw_video_details` | Joins Videos, Channels, Users, Categories — used on every page |
| `vw_trending_videos` | Top 50 by trending score |
| `vw_channel_stats` | Channel overview with video count and formatted stats |
| `vw_comment_threads` | Top-level comments with reply counts |
| `vw_user_subscriptions` | Subscribed channels with latest upload info |
| `vw_watch_history_details` | Watch history with video info and watch percentage |

### Functions (5)

| Function | Description |
|---|---|
| `fn_format_duration(seconds)` | Converts 3661 → "1:01:01" |
| `fn_format_count(n)` | Formats 1500000 → "1.5M" |
| `fn_is_subscribed(user_id, channel_id)` | Returns 1/0 |
| `fn_get_video_like_status(user_id, video_id)` | Returns 1 (liked), -1 (disliked), 0 (none) |
| `fn_get_watch_percentage(user_id, video_id)` | Returns 0–100 |

### Triggers (11)

| Trigger | Effect |
|---|---|
| `trg_after_subscribe_insert` | Increments `Channels.subscriber_count` |
| `trg_after_subscribe_delete` | Decrements `Channels.subscriber_count` |
| `trg_after_video_like_insert` | Increments `Videos.like_count` or `dislike_count` |
| `trg_after_video_like_update` | Handles like ↔ dislike toggle |
| `trg_after_video_like_delete` | Decrements counts on reaction removal |
| `trg_after_comment_insert` | Increments `Videos.comment_count` |
| `trg_after_comment_delete` | Decrements `Videos.comment_count` |
| `trg_after_watch_insert` | Increments `Videos.view_count` + `Channels.total_views` |
| `trg_after_comment_like_insert` | Increments `Comments.like_count` or `dislike_count` |
| `trg_after_comment_like_delete` | Decrements comment like/dislike counts |
| `trg_after_video_upload_notify` | Inserts notifications for all subscribers |

### Stored Procedures (12)

`sp_register_user`, `sp_login_user`, `sp_upload_video`, `sp_toggle_subscription`, `sp_react_video`, `sp_add_comment`, `sp_record_watch`, `sp_search_videos`, `sp_get_user_feed`, `sp_create_channel`, `sp_mark_notifications_read`, `sp_get_video_page`

---

## Tech Stack

| Layer | Technology |
|---|---|
| Database | MySQL 8.0 |
| Backend | Python 3.11 + Flask 3.0 |
| Frontend | HTML5, CSS3, Vanilla JavaScript |
| Video | HTML5 `<video>` with HTTP range streaming |
| Auth | SHA-256 password hashing, Flask sessions |
| Styling | Custom dark theme CSS (YouTube-inspired) |

---

## Project Structure

```
youtube_db/
├── app.py                    # Flask application — all routes
├── requirements.txt
├── sql/
│   ├── schema.sql            # 14 CREATE TABLE statements
│   ├── functions.sql         # 5 MySQL functions
│   ├── views.sql             # 6 MySQL views
│   ├── triggers.sql          # 11 MySQL triggers
│   ├── procedures.sql        # 12 stored procedures
│   └── sample_data.sql       # 15 users, 10 channels, 15 videos
├── static/
│   ├── css/style.css         # Full dark theme stylesheet
│   ├── js/app.js             # Frontend JS
│   └── uploads/
│       ├── videos/           # Uploaded video files
│       └── thumbnails/       # Uploaded thumbnail images
└── templates/
    ├── base.html             # Master layout (navbar, sidebar)
    ├── index.html            # Home / trending
    ├── video.html            # Video watch page with HTML5 player
    ├── channel.html          # Channel page
    ├── search.html           # Search results
    ├── history.html          # Watch history
    ├── subscriptions.html    # Subscription feed
    ├── upload.html           # Video upload with real progress
    ├── notifications.html    # Notifications
    ├── profile.html          # User profile
    ├── login.html
    ├── register.html
    ├── create_channel.html
    ├── 404.html
    └── 500.html
```

---

## Setup & Installation

### Prerequisites
- Python 3.10+
- MySQL 8.0+
- MySQL Workbench (recommended for Windows)

### Step 1 — Clone or download the project

```bash
cd your-project-folder
```

### Step 2 — Create and activate virtual environment

```bash
python -m venv .venv

# Windows
.\.venv\Scripts\Activate.ps1

# Mac/Linux
source .venv/bin/activate
```

### Step 3 — Install dependencies

```bash
pip install -r requirements.txt
```

### Step 4 — Create upload directories

```
static/uploads/videos/
static/uploads/thumbnails/
```

### Step 5 — Load the database

Open MySQL Workbench, connect, and run each SQL file in order via **File → Open SQL Script → Ctrl+Shift+Enter**:

1. `sql/schema.sql`
2. `sql/functions.sql`
3. `sql/views.sql`
4. `sql/triggers.sql`
5. `sql/procedures.sql`
6. `sql/sample_data.sql`

Verify:
```sql
USE youtube_db;
SHOW TABLES;  -- should show 14 tables
SELECT COUNT(*) FROM Videos;  -- should return 15
```

### Step 6 — Configure database password

Open `app.py` and set your MySQL password:

```python
DB_CONFIG = {
    'host':     'localhost',
    'user':     'root',
    'password': 'your_password_here',
    ...
}
```

### Step 7 — Run the application

```bash
python app.py
```

Open **http://localhost:5000**

---

## Demo Accounts

| Username | Password | Role |
|---|---|---|
| `viewer_one` | `password123` | Regular viewer |
| `ali_hussain` | `password123` | Owns Islamic Knowledge Hub |
| `sarah_tech` | `password123` | Owns Tech Mastery |
| `coding_mentor` | `password123` | Owns Code Academy |
| `dr_history` | `password123` | Owns History Unveiled |

---

## Course Information

**Course:** Database Systems  
**Assignment:** Semester Project — YouTube Clone  
**Database:** MySQL 8.0  
**Concepts Demonstrated:** ER Modeling, Normalization (1NF/2NF/3NF), Functional Dependencies, Views, Stored Procedures, Functions, Triggers, Indexing, Transactions

---

## License

This project was built for academic purposes as part of a Database Systems course assignment.
