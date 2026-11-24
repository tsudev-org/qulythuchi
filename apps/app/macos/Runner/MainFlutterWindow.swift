import Cocoa
import FlutterMacOS
import Vision

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    OcrChannel.register(messenger: flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
  }
}

/// OCR hóa đơn trên máy bằng Vision (ADR-0021). Kênh `com.tsudev.qulythuchi/ocr`, `recognize(Uint8List) -> String`
/// (mỗi dòng một dòng, từ trên xuống). Ảnh chỉ trong bộ nhớ, không ghi tệp, không gửi đi.
enum OcrChannel {
  static let maxImageBytes = 25 * 1024 * 1024
  static var channel: FlutterMethodChannel?

  static func register(messenger: FlutterBinaryMessenger) {
    let ch = FlutterMethodChannel(name: "com.tsudev.qulythuchi/ocr", binaryMessenger: messenger)
    ch.setMethodCallHandler { call, result in
      guard call.method == "recognize" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let data = (call.arguments as? FlutterStandardTypedData)?.data, !data.isEmpty,
        data.count <= maxImageBytes
      else {
        result(FlutterError(code: "bad_args", message: "Expected image bytes (<= 25 MiB)", details: nil))
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        let out = recognize(data)
        DispatchQueue.main.async { result(out) }
      }
    }
    channel = ch
  }

  /// Tiếng Việt nếu Vision có (`vi-VN`/`vi`), rồi tiếng Anh.
  static func languages(_ request: VNRecognizeTextRequest) -> [String] {
    let supported = (try? request.supportedRecognitionLanguages()) ?? []
    var langs = supported.filter { $0 == "vi-VN" || $0 == "vi" || $0.hasPrefix("vi-") }
    if supported.contains("en-US") { langs.append("en-US") }
    return langs
  }

  static func recognize(_ data: Data) -> Any {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    let langs = languages(request)
    if !langs.isEmpty { request.recognitionLanguages = langs }
    let handler = VNImageRequestHandler(data: data, options: [:])
    do {
      try handler.perform([request])
    } catch {
      // Không đưa nội dung ảnh vào lỗi (D3).
      return FlutterError(code: "failed", message: "Vision error", details: nil)
    }
    // Gốc toạ độ Vision ở dưới-trái: dòng trên có midY lớn hơn (thứ tự chặt, không dùng dung sai).
    let obs = (request.results ?? []).sorted { $0.boundingBox.midY > $1.boundingBox.midY }
    return obs.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
  }
}
