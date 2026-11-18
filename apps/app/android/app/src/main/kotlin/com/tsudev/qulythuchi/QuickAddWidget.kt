package com.tsudev.qulythuchi

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

/**
 * Widget "Ghi nhanh" trên màn hình chính: ba nút mở app ở chế độ gõ / nói / quét hóa đơn. KHÔNG hiển thị số dư hay
 * bất kỳ dữ liệu tài chính nào (widget nằm ngoài khóa app). App vẫn đòi mở khóa trước khi ghi.
 */
class QuickAddWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val views = RemoteViews(context.packageName, R.layout.quick_add_widget)
        views.setOnClickPendingIntent(R.id.qt_widget_type, link(context, "type", 1))
        views.setOnClickPendingIntent(R.id.qt_widget_voice, link(context, "voice", 2))
        views.setOnClickPendingIntent(R.id.qt_widget_scan, link(context, "scan", 3))
        for (id in ids) manager.updateAppWidget(id, views)
    }

    private fun link(context: Context, mode: String, code: Int): PendingIntent {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("com.tsudev.qulythuchi:/quick?mode=$mode"))
            .setClass(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        return PendingIntent.getActivity(
            context,
            code,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
