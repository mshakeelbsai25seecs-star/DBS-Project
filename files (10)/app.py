"""
YouTube Clone - Flask Application
Database Systems Assignment 2
Full video upload + streaming support
"""

from flask import (Flask, render_template, request, redirect,
                   url_for, session, jsonify, flash,
                   send_from_directory, Response)
import mysql.connector
import hashlib
import os
import uuid
from datetime import datetime
from functools import wraps
from werkzeug.utils import secure_filename

app = Flask(__name__)
app.secret_key = 'youtube_db_secret_key_2024'

# ── Upload config ─────────────────────────────────────────────
BASE_DIR        = os.path.dirname(os.path.abspath(__file__))
UPLOAD_FOLDER   = os.path.join(BASE_DIR, 'static', 'uploads')
VIDEO_FOLDER    = os.path.join(UPLOAD_FOLDER, 'videos')
THUMB_FOLDER    = os.path.join(UPLOAD_FOLDER, 'thumbnails')
ALLOWED_VIDEO   = {'mp4', 'webm', 'ogg', 'mov', 'avi', 'mkv'}
ALLOWED_IMAGE   = {'jpg', 'jpeg', 'png', 'gif', 'webp'}
MAX_VIDEO_MB    = 500          # 500 MB limit
MAX_THUMB_MB    = 5

# Create folders if they don't exist
os.makedirs(VIDEO_FOLDER, exist_ok=True)
os.makedirs(THUMB_FOLDER, exist_ok=True)

app.config['MAX_CONTENT_LENGTH'] = (MAX_VIDEO_MB + MAX_THUMB_MB + 10) * 1024 * 1024

# ── DB config ─────────────────────────────────────────────────
DB_CONFIG = {
    'host':     'localhost',
    'user':     'root',
    'password': '',
    'database': 'youtube_db',
    'charset':  'utf8mb4',
    'autocommit': False,
}

def get_db():
    return mysql.connector.connect(**DB_CONFIG)

def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()

def query(sql: str, params=None, fetch='all'):
    conn = get_db()
    cur  = conn.cursor(dictionary=True)
    try:
        cur.execute(sql, params or ())
        result = cur.fetchone() if fetch == 'one' else cur.fetchall()
    finally:
        cur.close()
        conn.close()
    return result

def execute(sql: str, params=None):
    conn = get_db()
    cur  = conn.cursor()
    try:
        cur.execute(sql, params or ())
        conn.commit()
        lid = cur.lastrowid
    finally:
        cur.close()
        conn.close()
    return lid

def call_proc(proc_name: str, args: tuple):
    conn = get_db()
    cur  = conn.cursor(dictionary=True)
    try:
        cur.callproc(proc_name, args)
        results = [rs.fetchall() for rs in cur.stored_results()]
        conn.commit()
    finally:
        cur.close()
        conn.close()
    return results

def allowed_file(filename, allowed_set):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in allowed_set

def get_extension(filename):
    return filename.rsplit('.', 1)[1].lower() if '.' in filename else ''

def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'user_id' not in session:
            flash('Please sign in to continue.', 'warning')
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated

# ── HOME ──────────────────────────────────────────────────────
@app.route('/')
def home():
    cat_filter = request.args.get('category', 0, type=int)
    categories = query("SELECT * FROM Categories ORDER BY category_name")
    if cat_filter:
        videos = query(
            "SELECT * FROM vw_video_details WHERE category_id=%s "
            "ORDER BY view_count DESC LIMIT 24", (cat_filter,))
    else:
        videos = query("SELECT * FROM vw_trending_videos LIMIT 24")
    return render_template('index.html', videos=videos,
                           categories=categories, cat_filter=cat_filter)

# ── REGISTER ──────────────────────────────────────────────────
@app.route('/register', methods=['GET', 'POST'])
def register():
    if 'user_id' in session:
        return redirect(url_for('home'))
    if request.method == 'POST':
        username = request.form['username'].strip()
        email    = request.form['email'].strip()
        password = request.form['password']
        first    = request.form.get('first_name', '').strip()
        last     = request.form.get('last_name',  '').strip()
        country  = request.form.get('country',    '').strip()

        if len(password) < 6:
            flash('Password must be at least 6 characters.', 'danger')
            return render_template('register.html')
        if query("SELECT user_id FROM Users WHERE username=%s", (username,), fetch='one'):
            flash('Username already taken.', 'danger')
            return render_template('register.html')
        if query("SELECT user_id FROM Users WHERE email=%s", (email,), fetch='one'):
            flash('Email already registered. Try signing in.', 'danger')
            return render_template('register.html')
        try:
            pw_hash = hash_password(password)
            user_id = execute(
                "INSERT INTO Users (username,email,password_hash,first_name,last_name,country) "
                "VALUES (%s,%s,%s,%s,%s,%s)",
                (username, email, pw_hash, first, last, country))
            session['user_id']    = user_id
            session['username']   = username
            session['first_name'] = first or username
            flash(f'Welcome to ViewTube, {username}!', 'success')
            return redirect(url_for('home'))
        except Exception:
            flash('Registration failed. Please try again.', 'danger')
    return render_template('register.html')

# ── LOGIN ─────────────────────────────────────────────────────
@app.route('/login', methods=['GET', 'POST'])
def login():
    if 'user_id' in session:
        return redirect(url_for('home'))
    if request.method == 'POST':
        username = request.form['username'].strip()
        password = request.form['password']
        pw_hash  = hash_password(password)
        user = query(
            "SELECT user_id,username,email,first_name,password_hash "
            "FROM Users WHERE username=%s LIMIT 1", (username,), fetch='one')
        if not user:
            flash('Username not found.', 'danger')
        elif user['password_hash'] != pw_hash:
            flash('Incorrect password.', 'danger')
        else:
            execute("UPDATE Users SET last_login=NOW() WHERE user_id=%s", (user['user_id'],))
            session['user_id']    = user['user_id']
            session['username']   = user['username']
            session['first_name'] = user['first_name'] or user['username']
            flash(f"Welcome back, {session['first_name']}!", 'success')
            return redirect(request.args.get('next') or url_for('home'))
    return render_template('login.html')

# ── LOGOUT ────────────────────────────────────────────────────
@app.route('/logout')
def logout():
    session.clear()
    flash('You have been signed out.', 'info')
    return redirect(url_for('home'))

# ── VIDEO WATCH PAGE ──────────────────────────────────────────
@app.route('/video/<int:video_id>')
def video(video_id):
    user_id = session.get('user_id', 0)
    vid = query("SELECT * FROM vw_video_details WHERE video_id=%s",
                (video_id,), fetch='one')
    if not vid:
        flash('Video not found.', 'danger')
        return redirect(url_for('home'))

    reaction   = 0
    subscribed = False
    if user_id:
        r = query("SELECT fn_get_video_like_status(%s,%s) AS r", (user_id, video_id), fetch='one')
        reaction = r['r'] if r else 0
        s = query("SELECT fn_is_subscribed(%s,%s) AS s", (user_id, vid['channel_id']), fetch='one')
        subscribed = bool(s['s']) if s else False
        try:
            execute("INSERT INTO Watch_History (user_id,video_id,watch_duration_seconds,completed) "
                    "VALUES (%s,%s,0,FALSE)", (user_id, video_id))
        except Exception:
            pass

    comments = query(
        "SELECT * FROM vw_comment_threads WHERE video_id=%s "
        "ORDER BY like_count DESC, created_at DESC LIMIT 50", (video_id,))

    replies_map = {}
    if comments:
        ids = tuple(c['comment_id'] for c in comments)
        placeholders = ','.join(['%s'] * len(ids))
        replies = query(
            f"SELECT c.*,u.username FROM Comments c "
            f"JOIN Users u ON c.user_id=u.user_id "
            f"WHERE c.parent_comment_id IN ({placeholders}) ORDER BY c.created_at ASC", ids)
        for rep in replies:
            pid = rep['parent_comment_id']
            replies_map.setdefault(pid, []).append(rep)

    suggested = query(
        "SELECT video_id,title,channel_name,view_count_formatted,"
        "duration_formatted,thumbnail_url,is_verified,upload_date "
        "FROM vw_video_details WHERE video_id!=%s "
        "ORDER BY view_count DESC LIMIT 12", (video_id,))

    # Check if actual video file exists on disk
    video_src = None
    for ext in ALLOWED_VIDEO:
        candidate = os.path.join(VIDEO_FOLDER, f"{video_id}.{ext}")
        if os.path.exists(candidate):
            video_src = url_for('serve_video', video_id=video_id, ext=ext)
            break

    return render_template('video.html', vid=vid, comments=comments,
                           replies_map=replies_map, suggested=suggested,
                           reaction=reaction, subscribed=subscribed,
                           user_id=user_id, video_src=video_src)

# ── SERVE VIDEO FILE (with range/streaming support) ───────────
@app.route('/stream/<int:video_id>/<ext>')
def serve_video(video_id, ext):
    filename = f"{video_id}.{ext}"
    filepath = os.path.join(VIDEO_FOLDER, filename)

    if not os.path.exists(filepath):
        return "Video file not found", 404

    file_size = os.path.getsize(filepath)
    range_header = request.headers.get('Range', None)

    # MIME type map
    mime_types = {
        'mp4': 'video/mp4', 'webm': 'video/webm', 'ogg': 'video/ogg',
        'mov': 'video/quicktime', 'avi': 'video/x-msvideo', 'mkv': 'video/x-matroska'
    }
    mime = mime_types.get(ext.lower(), 'video/mp4')

    if not range_header:
        # Serve full file
        def generate_full():
            with open(filepath, 'rb') as f:
                while chunk := f.read(65536):
                    yield chunk
        return Response(generate_full(), mimetype=mime,
                        headers={'Content-Length': str(file_size),
                                 'Accept-Ranges': 'bytes'})

    # Handle Range request (for seeking in the video player)
    byte_start, byte_end = 0, file_size - 1
    range_match = range_header.replace('bytes=', '').split('-')
    if range_match[0]:
        byte_start = int(range_match[0])
    if len(range_match) > 1 and range_match[1]:
        byte_end = int(range_match[1])

    chunk_size = byte_end - byte_start + 1

    def generate_chunk():
        with open(filepath, 'rb') as f:
            f.seek(byte_start)
            remaining = chunk_size
            while remaining > 0:
                data = f.read(min(65536, remaining))
                if not data:
                    break
                remaining -= len(data)
                yield data

    headers = {
        'Content-Range':  f'bytes {byte_start}-{byte_end}/{file_size}',
        'Accept-Ranges':  'bytes',
        'Content-Length': str(chunk_size),
        'Content-Type':   mime,
    }
    return Response(generate_chunk(), status=206, headers=headers, mimetype=mime)

# ── SERVE THUMBNAIL ───────────────────────────────────────────
@app.route('/thumbnail/<int:video_id>/<ext>')
def serve_thumbnail(video_id, ext):
    filename = f"{video_id}.{ext}"
    return send_from_directory(THUMB_FOLDER, filename)

# ── CHANNEL PAGE ──────────────────────────────────────────────
@app.route('/channel/<int:channel_id>')
def channel(channel_id):
    user_id = session.get('user_id', 0)
    ch = query("SELECT * FROM vw_channel_stats WHERE channel_id=%s", (channel_id,), fetch='one')
    if not ch:
        flash('Channel not found.', 'danger')
        return redirect(url_for('home'))
    videos = query("SELECT * FROM vw_video_details WHERE channel_id=%s ORDER BY upload_date DESC",
                   (channel_id,))
    subscribed = False
    is_owner   = False
    if user_id:
        s = query("SELECT fn_is_subscribed(%s,%s) AS s", (user_id, channel_id), fetch='one')
        subscribed = bool(s['s']) if s else False
        is_owner   = (ch['user_id'] == user_id)
    return render_template('channel.html', ch=ch, videos=videos,
                           subscribed=subscribed, is_owner=is_owner)

# ── SEARCH ────────────────────────────────────────────────────
@app.route('/search')
def search():
    q          = request.args.get('q', '').strip()
    category   = request.args.get('category', 0, type=int)
    categories = query("SELECT * FROM Categories ORDER BY category_name")
    videos     = []
    if q:
        results = call_proc('sp_search_videos', (q, category or None, 24, 0))
        videos  = results[0] if results else []
    return render_template('search.html', videos=videos, q=q,
                           categories=categories, cat_filter=category)

# ── WATCH HISTORY ─────────────────────────────────────────────
@app.route('/history')
@login_required
def history():
    user_id = session['user_id']
    items = query("SELECT * FROM vw_watch_history_details "
                  "WHERE user_id=%s ORDER BY watched_at DESC LIMIT 50", (user_id,))
    return render_template('history.html', items=items)

# ── SUBSCRIPTIONS FEED ────────────────────────────────────────
@app.route('/subscriptions')
@login_required
def subscriptions():
    user_id  = session['user_id']
    channels = query("SELECT * FROM vw_user_subscriptions "
                     "WHERE user_id=%s ORDER BY last_upload_date DESC", (user_id,))
    results = call_proc('sp_get_user_feed', (user_id, 24, 0))
    videos  = results[0] if results else []
    return render_template('subscriptions.html', channels=channels, videos=videos)

# ── UPLOAD VIDEO ──────────────────────────────────────────────
@app.route('/upload', methods=['GET', 'POST'])
@login_required
def upload():
    user_id    = session['user_id']
    categories = query("SELECT * FROM Categories ORDER BY category_name")
    channels   = query("SELECT channel_id,channel_name FROM Channels WHERE user_id=%s", (user_id,))

    if request.method == 'POST':
        channel_id  = request.form.get('channel_id', type=int)
        category_id = request.form.get('category_id', type=int) or None
        title       = request.form['title'].strip()
        description = request.form.get('description', '').strip()
        resolution  = request.form.get('resolution', '1080p')
        is_public   = 1 if 'is_public' in request.form else 0
        video_file  = request.files.get('video_file')
        thumb_file  = request.files.get('thumbnail_file')

        # Validation
        if not title:
            flash('Title is required.', 'danger')
            return render_template('upload.html', categories=categories, channels=channels)
        if not channel_id:
            flash('Please select a channel.', 'danger')
            return render_template('upload.html', categories=categories, channels=channels)
        if not video_file or video_file.filename == '':
            flash('Please select a video file to upload.', 'danger')
            return render_template('upload.html', categories=categories, channels=channels)
        if not allowed_file(video_file.filename, ALLOWED_VIDEO):
            flash(f'Invalid video format. Allowed: {", ".join(ALLOWED_VIDEO)}', 'danger')
            return render_template('upload.html', categories=categories, channels=channels)

        owns = query("SELECT channel_id FROM Channels WHERE channel_id=%s AND user_id=%s",
                     (channel_id, user_id), fetch='one')
        if not owns:
            flash('You do not own that channel.', 'danger')
            return render_template('upload.html', categories=categories, channels=channels)

        try:
            video_ext = get_extension(video_file.filename)

            # Insert DB record first to get video_id
            video_id = execute(
                "INSERT INTO Videos (channel_id,category_id,title,description,"
                "duration_seconds,resolution,is_public) VALUES (%s,%s,%s,%s,%s,%s,%s)",
                (channel_id, category_id, title, description, 0, resolution, is_public))

            # Save video file as {video_id}.{ext}
            video_filename = f"{video_id}.{video_ext}"
            video_path     = os.path.join(VIDEO_FOLDER, video_filename)
            video_file.save(video_path)

            # Get actual file size
            file_size_mb = round(os.path.getsize(video_path) / (1024 * 1024), 2)

            # Save thumbnail if provided
            thumb_url = None
            if thumb_file and thumb_file.filename != '' and allowed_file(thumb_file.filename, ALLOWED_IMAGE):
                thumb_ext      = get_extension(thumb_file.filename)
                thumb_filename = f"{video_id}.{thumb_ext}"
                thumb_file.save(os.path.join(THUMB_FOLDER, thumb_filename))
                thumb_url = url_for('serve_thumbnail', video_id=video_id, ext=thumb_ext)

            # Update video record with file size and thumbnail
            execute("UPDATE Videos SET file_size_mb=%s, thumbnail_url=%s WHERE video_id=%s",
                    (file_size_mb, thumb_url, video_id))

            flash('Video uploaded successfully! 🎉', 'success')
            return redirect(url_for('video', video_id=video_id))

        except Exception as e:
            flash(f'Upload failed: {str(e)}', 'danger')

    return render_template('upload.html', categories=categories, channels=channels)

# ── CREATE CHANNEL ────────────────────────────────────────────
@app.route('/create-channel', methods=['GET', 'POST'])
@login_required
def create_channel():
    user_id = session['user_id']
    if request.method == 'POST':
        name = request.form['channel_name'].strip()
        desc = request.form.get('description', '').strip()
        if not name:
            flash('Channel name is required.', 'danger')
            return render_template('create_channel.html')
        existing = query("SELECT channel_id FROM Channels WHERE channel_name=%s",
                         (name,), fetch='one')
        if existing:
            flash('That channel name is already taken.', 'danger')
            return render_template('create_channel.html')
        try:
            ch_id = execute("INSERT INTO Channels (user_id,channel_name,description) VALUES (%s,%s,%s)",
                            (user_id, name, desc))
            flash(f'Channel "{name}" created!', 'success')
            return redirect(url_for('channel', channel_id=ch_id))
        except Exception:
            flash('Could not create channel. Please try again.', 'danger')
    return render_template('create_channel.html')

# ── NOTIFICATIONS ─────────────────────────────────────────────
@app.route('/notifications')
@login_required
def notifications():
    user_id = session['user_id']
    notifs  = query(
        "SELECT n.*,c.channel_name,v.title AS video_title "
        "FROM Notifications n "
        "LEFT JOIN Channels c ON n.channel_id=c.channel_id "
        "LEFT JOIN Videos   v ON n.video_id=v.video_id "
        "WHERE n.user_id=%s ORDER BY n.created_at DESC LIMIT 30", (user_id,))
    try:
        execute("UPDATE Notifications SET is_read=TRUE WHERE user_id=%s AND is_read=FALSE", (user_id,))
    except Exception:
        pass
    return render_template('notifications.html', notifs=notifs)

# ── PROFILE ───────────────────────────────────────────────────
@app.route('/profile')
@login_required
def profile():
    user_id  = session['user_id']
    user     = query("SELECT * FROM Users WHERE user_id=%s", (user_id,), fetch='one')
    channels = query("SELECT * FROM vw_channel_stats WHERE user_id=%s", (user_id,))
    return render_template('profile.html', user=user, channels=channels)

# ── AJAX: LIKE / DISLIKE ──────────────────────────────────────
@app.route('/api/react_video', methods=['POST'])
@login_required
def api_react_video():
    user_id  = session['user_id']
    data     = request.get_json()
    video_id = data.get('video_id')
    reaction = data.get('reaction')
    existing = query("SELECT is_like FROM Video_Likes WHERE user_id=%s AND video_id=%s",
                     (user_id, video_id), fetch='one')
    try:
        if existing is None:
            execute("INSERT INTO Video_Likes (video_id,user_id,is_like) VALUES (%s,%s,%s)",
                    (video_id, user_id, reaction))
            action = 'liked' if reaction == 1 else 'disliked'
        elif existing['is_like'] == bool(reaction):
            execute("DELETE FROM Video_Likes WHERE user_id=%s AND video_id=%s", (user_id, video_id))
            action = 'removed'
        else:
            execute("UPDATE Video_Likes SET is_like=%s WHERE user_id=%s AND video_id=%s",
                    (reaction, user_id, video_id))
            action = 'toggled'
        vid = query("SELECT like_count,dislike_count FROM Videos WHERE video_id=%s",
                    (video_id,), fetch='one')
        return jsonify({'status':'ok','action':action,
                        'likes':vid['like_count'],'dislikes':vid['dislike_count']})
    except Exception:
        return jsonify({'status':'error'}), 400

# ── AJAX: SUBSCRIBE ───────────────────────────────────────────
@app.route('/api/subscribe', methods=['POST'])
@login_required
def api_subscribe():
    user_id    = session['user_id']
    data       = request.get_json()
    channel_id = data.get('channel_id')
    if query("SELECT channel_id FROM Channels WHERE channel_id=%s AND user_id=%s",
             (channel_id, user_id), fetch='one'):
        return jsonify({'status':'error','action':'own_channel'}), 400
    existing = query("SELECT subscription_id FROM Subscriptions WHERE user_id=%s AND channel_id=%s",
                     (user_id, channel_id), fetch='one')
    try:
        if existing:
            execute("DELETE FROM Subscriptions WHERE user_id=%s AND channel_id=%s",
                    (user_id, channel_id))
            action = 'unsubscribed'
        else:
            execute("INSERT INTO Subscriptions (user_id,channel_id) VALUES (%s,%s)",
                    (user_id, channel_id))
            action = 'subscribed'
        ch      = query("SELECT subscriber_count FROM Channels WHERE channel_id=%s",
                        (channel_id,), fetch='one')
        sub_fmt = query("SELECT fn_format_count(%s) AS f", (ch['subscriber_count'],), fetch='one')
        return jsonify({'status':'ok','action':action,
                        'sub_count': sub_fmt['f'] if sub_fmt else ch['subscriber_count']})
    except Exception:
        return jsonify({'status':'error'}), 400

# ── AJAX: ADD COMMENT ─────────────────────────────────────────
@app.route('/api/comment', methods=['POST'])
@login_required
def api_comment():
    user_id   = session['user_id']
    data      = request.get_json()
    video_id  = data.get('video_id')
    parent_id = data.get('parent_comment_id')
    text      = data.get('comment_text', '').strip()
    if not text:
        return jsonify({'status':'error','message':'Empty comment'}), 400
    if not query("SELECT video_id FROM Videos WHERE video_id=%s AND allows_comments=TRUE",
                 (video_id,), fetch='one'):
        return jsonify({'status':'error','message':'Comments disabled'}), 400
    try:
        cid = execute(
            "INSERT INTO Comments (video_id,user_id,parent_comment_id,comment_text) "
            "VALUES (%s,%s,%s,%s)", (video_id, user_id, parent_id, text))
        return jsonify({'status':'ok','comment_id':cid,
                        'username':session.get('username','You'),
                        'text':text,
                        'created_at':datetime.now().strftime('%b %d, %Y')})
    except Exception:
        return jsonify({'status':'error','message':'Could not post comment'}), 400

# ── AJAX: NOTIFICATION COUNT ──────────────────────────────────
@app.route('/api/notif_count')
@login_required
def api_notif_count():
    user_id = session['user_id']
    row = query("SELECT COUNT(*) AS c FROM Notifications WHERE user_id=%s AND is_read=FALSE",
                (user_id,), fetch='one')
    return jsonify({'count': row['c'] if row else 0})

# ── ERROR HANDLERS ────────────────────────────────────────────
@app.errorhandler(404)
def not_found(e):
    return render_template('404.html'), 404

@app.errorhandler(413)
def file_too_large(e):
    flash(f'File too large. Maximum video size is {MAX_VIDEO_MB}MB.', 'danger')
    return redirect(url_for('upload'))

@app.errorhandler(500)
def server_error(e):
    return render_template('500.html', error=str(e)), 500

if __name__ == '__main__':
    app.run(debug=True, port=5000)
