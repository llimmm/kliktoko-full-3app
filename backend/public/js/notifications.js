// Fungsi untuk memuat notifikasi
function loadNotifications() {
    fetch('/notifications')
        .then(response => response.json())
        .then(data => {
            updateNotificationBadge(data.unread_count);
            updateNotificationList(data.notifications);
        })
        .catch(error => console.error('Error:', error));
}

// Fungsi untuk memperbarui badge notifikasi
function updateNotificationBadge(count) {
    const badge = document.querySelector('.notification-badge');
    const countElement = document.querySelector('.notification-count');

    if (count > 0) {
        badge.classList.remove('d-none');
        countElement.textContent = count;
    } else {
        badge.classList.add('d-none');
    }
}

// Fungsi untuk memperbarui daftar notifikasi
function updateNotificationList(notifications) {
    const container = document.querySelector('.notification-list');
    container.innerHTML = '';

    if (notifications.length === 0) {
        container.innerHTML = '<div class="p-3 text-center text-muted">Tidak ada notifikasi</div>';
        return;
    }

    notifications.forEach(notification => {
        const item = document.createElement('div');
        item.className = `notification-item p-3 border-bottom ${!notification.is_read ? 'bg-light' : ''}`;

        const iconClass = getNotificationIcon(notification.type);

        item.innerHTML = `
            <div class="d-flex align-items-start gap-2">
                <div class="notification-icon">
                    <i class="${iconClass} fs-5"></i>
                </div>
                <div class="flex-grow-1">
                    <h6 class="mb-1">${notification.title}</h6>
                    <p class="mb-1 text-muted">${notification.message}</p>
                    <small class="text-muted">${notification.created_at}</small>
                </div>
                ${!notification.is_read ? `
                <button class="btn btn-link btn-sm p-0" onclick="markAsRead(${notification.id})">
                    <i class="bi bi-check2-circle"></i>
                </button>` : ''}
            </div>
        `;

        container.appendChild(item);
    });
}

// Fungsi untuk mendapatkan ikon berdasarkan tipe notifikasi
function getNotificationIcon(type) {
    switch (type) {
        case 'low_stock':
            return 'bi bi-box-seam text-warning';
        case 'attendance':
            return 'bi bi-person-check text-primary';
        case 'leave':
            return 'bi bi-calendar-event text-info';
        case 'monthly_summary':
            return 'bi bi-graph-up text-success';
        default:
            return 'bi bi-bell text-secondary';
    }
}

// Fungsi untuk menandai notifikasi sebagai telah dibaca
function markAsRead(notificationId) {
    fetch(`/notifications/${notificationId}/mark-as-read`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content
        }
    })
        .then(() => loadNotifications())
        .catch(error => console.error('Error:', error));
}

// Fungsi untuk menandai semua notifikasi sebagai telah dibaca
function markAllNotificationsAsRead() {
    fetch('/notifications/mark-all-as-read', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content
        }
    })
        .then(() => loadNotifications())
        .catch(error => console.error('Error:', error));
}

// Memuat notifikasi saat halaman dimuat
document.addEventListener('DOMContentLoaded', () => {
    loadNotifications();
    // Memperbarui notifikasi setiap 30 detik
    setInterval(loadNotifications, 30000);
});