package com.tsudev.qulythuchi

import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * FlutterFragmentActivity: local_auth cần FragmentActivity để hiện hộp thoại sinh trắc.
 * FLAG_SECURE: chặn chụp/ghi màn hình và ảnh xem trước trong màn đa nhiệm (dữ liệu tài chính D3).
 * Kênh `com.tsudev.qulythuchi/notifications`: cài đặt và lấy hàng đợi thông báo ngân hàng (ADR-0012).
 */
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.tsudev.qulythuchi/notifications")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "isEnabled" -> result.success(
                            NotificationManagerCompat.getEnabledListenerPackages(this).contains(packageName),
                        )
                        "openSettings" -> {
                            val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                            if (android.os.Build.VERSION.SDK_INT >= 30) {
                                val detail = Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS)
                                    .putExtra(
                                        Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME,
                                        ComponentName(this, BankNotificationListener::class.java).flattenToString(),
                                    )
                                if (detail.resolveActivity(packageManager) != null) {
                                    startActivity(detail)
                                    result.success(null)
                                    return@setMethodCallHandler
                                }
                            }
                            startActivity(intent)
                            result.success(null)
                        }
                        "installedApps" -> {
                            val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
                            val apps = packageManager.queryIntentActivities(launcher, 0)
                                .map { it.activityInfo.packageName to it.loadLabel(packageManager).toString() }
                                .filter { it.first != packageName }
                                .distinctBy { it.first }
                                .map { mapOf("package" to it.first, "label" to it.second) }
                            result.success(apps)
                        }
                        "setWatched" -> {
                            val list = (call.arguments as? List<*>)?.filterIsInstance<String>() ?: emptyList()
                            NotificationQueue.setWatched(this, list)
                            result.success(null)
                        }
                        "drain" -> result.success(NotificationQueue.drain(this))
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("native", e.javaClass.simpleName, null)
                }
            }
    }
}
