package com.tsudev.qulythuchi

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

/**
 * FlutterFragmentActivity: local_auth cần FragmentActivity để hiện hộp thoại sinh trắc.
 * FLAG_SECURE: chặn chụp/ghi màn hình và ảnh xem trước trong màn đa nhiệm (dữ liệu tài chính D3).
 */
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
        super.onCreate(savedInstanceState)
    }
}
