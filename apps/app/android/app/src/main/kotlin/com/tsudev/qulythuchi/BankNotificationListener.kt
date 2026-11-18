package com.tsudev.qulythuchi

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

/**
 * Nghe thông báo, CHỈ giữ thông báo của app ngân hàng người dùng đã chọn (ADR-0006). Thông báo của mọi app khác
 * bị bỏ qua ngay, không đọc nội dung. Phân tích thành giao dịch làm ở phía Dart khi app mở khóa.
 */
class BankNotificationListener : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        val n = sbn ?: return
        if (n.packageName == packageName) return
        if (n.packageName !in NotificationQueue.watched(this)) return
        val notification = n.notification ?: return
        if (notification.flags and Notification.FLAG_GROUP_SUMMARY != 0) return
        if (notification.flags and Notification.FLAG_ONGOING_EVENT != 0) return
        val extras = notification.extras ?: return
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = (extras.getCharSequence(Notification.EXTRA_BIG_TEXT) ?: extras.getCharSequence(Notification.EXTRA_TEXT))
            ?.toString() ?: ""
        if (title.isBlank() && text.isBlank()) return
        try {
            NotificationQueue.append(this, n.packageName, title, text, n.postTime)
        } catch (_: Exception) {
            // Keystore lỗi: bỏ thông báo này, không ghi log nội dung.
        }
    }
}
