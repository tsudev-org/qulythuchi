import Flutter
import UIKit

/// Lối tắt nhấn giữ biểu tượng app (Quick Actions, ADR-0022): Gõ/Nói/Quét ⇒ mở liên kết ghi nhanh
/// `com.tsudev.qulythuchi:/quick?mode=…` - cùng đường với widget, app_links chuyển vào Dart. Không mang dữ liệu.
class SceneDelegate: FlutterSceneDelegate {
  private static let prefix = "com.tsudev.qulythuchi.quick."

  override func scene(
    _ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    Self.installShortcutItems()
    if let item = connectionOptions.shortcutItem {
      // Khởi động nguội: đợi Flutter dựng xong bộ nghe liên kết.
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { Self.open(item) }
    }
  }

  override func windowScene(
    _ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) {
    completionHandler(Self.open(shortcutItem))
  }

  @discardableResult
  private static func open(_ item: UIApplicationShortcutItem) -> Bool {
    guard item.type.hasPrefix(prefix) else { return false }
    let mode = String(item.type.dropFirst(prefix.count))
    guard ["type", "voice", "scan"].contains(mode),
      let url = URL(string: "com.tsudev.qulythuchi:/quick?mode=\(mode)")
    else { return false }
    UIApplication.shared.open(url)
    return true
  }

  private static func installShortcutItems() {
    let vi = Locale.preferredLanguages.first?.hasPrefix("vi") ?? true
    let items: [(String, String, String)] = [
      ("type", vi ? "Ghi nhanh" : "Quick add", "square.and.pencil"),
      ("voice", vi ? "Ghi bằng giọng nói" : "Add by voice", "mic"),
      ("scan", vi ? "Quét hoá đơn" : "Scan receipt", "doc.text.viewfinder"),
    ]
    UIApplication.shared.shortcutItems = items.map { mode, title, symbol in
      UIApplicationShortcutItem(
        type: prefix + mode, localizedTitle: title, localizedSubtitle: nil,
        icon: UIApplicationShortcutIcon(systemImageName: symbol), userInfo: nil)
    }
  }
}
