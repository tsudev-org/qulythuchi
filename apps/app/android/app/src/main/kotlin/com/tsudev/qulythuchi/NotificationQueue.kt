package com.tsudev.qulythuchi

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.io.File
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import org.json.JSONObject

/**
 * Hàng đợi thông báo ngân hàng chờ app mở khóa (ADR-0006, ADR-0012).
 *
 * - Chỉ nhận thông báo của gói app người dùng đã chọn ([watched]); danh sách gói không phải dữ liệu tài chính.
 * - Mỗi mục được mã hóa AES-256-GCM bằng khóa trong Android Keystore (không xuất được ra ngoài) rồi ghi vào
 *   noBackupFilesDir (không sao lưu, không đi theo chuyển máy). App lấy ra bằng [drain] và xóa ngay.
 * - Giới hạn [MAX_ITEMS] mục; quá hạn thì bỏ mục cũ nhất. Không ghi nội dung ra logcat.
 */
object NotificationQueue {
    private const val KEY_ALIAS = "qt_notif_queue_v1"
    private const val FILE_NAME = "notif_queue.bin"
    private const val PREFS = "qt_autoimport"
    private const val PREF_WATCHED = "watched"
    private const val MAX_ITEMS = 500
    private const val MAX_TEXT = 2000
    private val lock = Any()

    fun watched(context: Context): Set<String> =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getStringSet(PREF_WATCHED, emptySet()) ?: emptySet()

    fun setWatched(context: Context, packages: Collection<String>) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putStringSet(PREF_WATCHED, packages.filter { it.length <= 255 }.toSet())
            .apply()
        if (packages.isEmpty()) clear(context)
    }

    private fun file(context: Context) = File(context.noBackupFilesDir, FILE_NAME)

    private fun key(): SecretKey {
        val ks = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (ks.getKey(KEY_ALIAS, null) as? SecretKey)?.let { return it }
        val gen = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        gen.init(
            KeyGenParameterSpec.Builder(KEY_ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build(),
        )
        return gen.generateKey()
    }

    fun append(context: Context, pkg: String, title: String, text: String, postedAt: Long) {
        val json = JSONObject()
            .put("package", pkg)
            .put("title", title.take(MAX_TEXT))
            .put("text", text.take(MAX_TEXT))
            .put("postedAt", postedAt)
            .toString()
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key())
        val sealed = cipher.iv + cipher.doFinal(json.toByteArray(Charsets.UTF_8))
        val line = Base64.encodeToString(sealed, Base64.NO_WRAP)
        synchronized(lock) {
            val f = file(context)
            val lines = if (f.exists()) f.readLines().filter { it.isNotBlank() }.toMutableList() else mutableListOf()
            lines.add(line)
            while (lines.size > MAX_ITEMS) lines.removeAt(0)
            val tmp = File(f.parentFile, "$FILE_NAME.tmp")
            tmp.writeText(lines.joinToString("\n"))
            tmp.renameTo(f)
        }
    }

    /** Lấy và xóa mọi mục; mục không giải mã được (khóa đã đổi, tệp hỏng) bị bỏ. */
    fun drain(context: Context): List<Map<String, Any>> {
        val lines = synchronized(lock) {
            val f = file(context)
            if (!f.exists()) return emptyList()
            val all = f.readLines().filter { it.isNotBlank() }
            f.delete()
            all
        }
        val k = key()
        val out = ArrayList<Map<String, Any>>(lines.size)
        for (line in lines) {
            try {
                val sealed = Base64.decode(line, Base64.NO_WRAP)
                if (sealed.size < 12 + 16) continue
                val cipher = Cipher.getInstance("AES/GCM/NoPadding")
                cipher.init(Cipher.DECRYPT_MODE, k, GCMParameterSpec(128, sealed, 0, 12))
                val o = JSONObject(String(cipher.doFinal(sealed, 12, sealed.size - 12), Charsets.UTF_8))
                out.add(
                    mapOf(
                        "package" to o.getString("package"),
                        "title" to o.optString("title"),
                        "text" to o.optString("text"),
                        "postedAt" to o.optLong("postedAt"),
                    ),
                )
            } catch (_: Exception) {
                // Bỏ qua mục hỏng, không ghi log nội dung.
            }
        }
        return out
    }

    fun clear(context: Context) {
        synchronized(lock) { file(context).delete() }
    }
}
