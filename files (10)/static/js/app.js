/* ============================================================
   VIEWTUBE — Main Frontend JavaScript
   ============================================================ */

/* ── Sidebar toggle ─────────────────────────────────────────── */
function toggleSidebar() {
  const sidebar = document.getElementById('sidebar');
  const main    = document.getElementById('main-content');
  if (window.innerWidth <= 900) {
    sidebar.classList.toggle('open');
  } else {
    sidebar.classList.toggle('collapsed');
    main.classList.toggle('full');
  }
}

/* ── Avatar dropdown ────────────────────────────────────────── */
function toggleMenu(avatarEl) {
  const dropdown = avatarEl.nextElementSibling;
  dropdown.classList.toggle('open');
}

// Close dropdown when clicking outside
document.addEventListener('click', function (e) {
  document.querySelectorAll('.dropdown.open').forEach(function (d) {
    if (!d.previousElementSibling.contains(e.target) && !d.contains(e.target)) {
      d.classList.remove('open');
    }
  });
});

/* ── Auto-dismiss flash messages ───────────────────────────── */
document.addEventListener('DOMContentLoaded', function () {
  const flashes = document.querySelectorAll('.flash');
  flashes.forEach(function (f) {
    setTimeout(function () {
      f.style.transition = 'opacity .4s';
      f.style.opacity = '0';
      setTimeout(function () { f.remove(); }, 400);
    }, 5000);
  });
});

/* ── Notification badge (poll every 60s if logged in) ──────── */
function fetchNotifCount() {
  fetch('/api/notif_count')
    .then(function (r) { return r.json(); })
    .then(function (data) {
      const badge = document.getElementById('notif-badge');
      if (!badge) return;
      if (data.count > 0) {
        badge.textContent = data.count > 99 ? '99+' : data.count;
        badge.style.display = 'flex';
      } else {
        badge.style.display = 'none';
      }
    })
    .catch(function () {}); // silently fail
}

(function () {
  const notifBtn = document.getElementById('notif-btn');
  if (notifBtn) {
    fetchNotifCount();
    setInterval(fetchNotifCount, 60000);
  }
})();

/* ── Textarea auto-resize ───────────────────────────────────── */
function autoResize(el) {
  el.style.height = 'auto';
  el.style.height = el.scrollHeight + 'px';
}

/* ── Search form — focus shortcut (press /) ─────────────────── */
document.addEventListener('keydown', function (e) {
  const searchInput = document.querySelector('.search-input');
  if (!searchInput) return;
  const active = document.activeElement;
  const isTyping = active && (
    active.tagName === 'INPUT' ||
    active.tagName === 'TEXTAREA' ||
    active.isContentEditable
  );
  if (e.key === '/' && !isTyping) {
    e.preventDefault();
    searchInput.focus();
    searchInput.select();
  }
});

/* ── Scroll to top button (appears after 400px scroll) ─────── */
(function () {
  const btn = document.createElement('button');
  btn.className = 'scroll-top-btn';
  btn.innerHTML = '<i class="fa fa-arrow-up"></i>';
  btn.title     = 'Back to top';
  btn.style.cssText = [
    'position:fixed', 'bottom:1.5rem', 'right:1.5rem',
    'width:42px', 'height:42px', 'border-radius:50%',
    'background:var(--bg-secondary)', 'border:1px solid var(--border-light)',
    'color:var(--text-primary)', 'font-size:1rem',
    'display:none', 'align-items:center', 'justify-content:center',
    'cursor:pointer', 'z-index:200',
    'box-shadow:var(--shadow)',
    'transition:background .18s ease'
  ].join(';');
  btn.addEventListener('click', function () {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  });
  document.body.appendChild(btn);

  window.addEventListener('scroll', function () {
    btn.style.display = window.scrollY > 400 ? 'flex' : 'none';
  });
})();

/* ── Video card hover: preload thumbnail ─────────────────────── */
document.addEventListener('DOMContentLoaded', function () {
  document.querySelectorAll('.video-card').forEach(function (card) {
    card.addEventListener('mouseenter', function () {
      const img = card.querySelector('.thumbnail');
      if (img && img.dataset.src) {
        img.src = img.dataset.src;
      }
    });
  });
});

/* ── Confirm before logout ──────────────────────────────────── */
document.addEventListener('DOMContentLoaded', function () {
  const logoutLink = document.querySelector('.logout-link');
  if (logoutLink) {
    logoutLink.addEventListener('click', function (e) {
      if (!confirm('Sign out of ViewTube?')) {
        e.preventDefault();
      }
    });
  }
});

/* ── Time-relative formatting for comment timestamps ────────── */
function timeAgo(dateStr) {
  if (!dateStr) return '';
  const date  = new Date(dateStr);
  const now   = new Date();
  const diff  = Math.floor((now - date) / 1000); // seconds
  if (diff < 60)   return 'just now';
  if (diff < 3600) return Math.floor(diff / 60)   + ' minutes ago';
  if (diff < 86400) return Math.floor(diff / 3600) + ' hours ago';
  if (diff < 2592000) return Math.floor(diff / 86400) + ' days ago';
  if (diff < 31536000) return Math.floor(diff / 2592000) + ' months ago';
  return Math.floor(diff / 31536000) + ' years ago';
}

/* ── Apply timeAgo to all .comment-time spans ───────────────── */
document.addEventListener('DOMContentLoaded', function () {
  document.querySelectorAll('.comment-time').forEach(function (el) {
    const raw = el.textContent.trim();
    if (raw) el.textContent = timeAgo(raw) || raw;
  });
});

/* ── Close sidebar on mobile when clicking outside ──────────── */
document.addEventListener('click', function (e) {
  if (window.innerWidth > 900) return;
  const sidebar = document.getElementById('sidebar');
  if (!sidebar) return;
  const hamburger = document.querySelector('.hamburger');
  if (sidebar.classList.contains('open') &&
      !sidebar.contains(e.target) &&
      !hamburger.contains(e.target)) {
    sidebar.classList.remove('open');
  }
});
