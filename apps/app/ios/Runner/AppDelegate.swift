import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var privacyCover: UIView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Che nội dung bằng lớp mờ khi app mất tiêu điểm: ảnh chụp màn đa nhiệm không lộ số dư (dữ liệu D3).
    NotificationCenter.default.addObserver(
      self, selector: #selector(sceneWillDeactivate(_:)), name: UIScene.willDeactivateNotification, object: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(sceneDidActivate(_:)), name: UIScene.didActivateNotification, object: nil)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  @objc private func sceneWillDeactivate(_ notification: Notification) {
    guard privacyCover == nil,
      let window = (notification.object as? UIWindowScene)?.windows.first(where: { $0.isKeyWindow })
    else { return }
    let cover = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    cover.frame = window.bounds
    cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    window.addSubview(cover)
    privacyCover = cover
  }

  @objc private func sceneDidActivate(_ notification: Notification) {
    privacyCover?.removeFromSuperview()
    privacyCover = nil
  }
}
