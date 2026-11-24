import SwiftUI
import WidgetKit

// Widget "Ghi nhanh" (ADR-0022): chỉ ba lối tắt Gõ/Nói/Quét mở `com.tsudev.qulythuchi:/quick?mode=…`.
// KHÔNG đọc, KHÔNG hiển thị số dư hay bất kỳ dữ liệu nào (widget nằm ngoài khoá app, hiện cả trên màn hình khoá);
// không App Group, không mạng. App vẫn đòi mở khoá trước khi ghi - giống widget Android (ADR-0012 mục 11).

struct QuickEntry: TimelineEntry { let date: Date }

struct QuickProvider: TimelineProvider {
  func placeholder(in context: Context) -> QuickEntry { QuickEntry(date: Date()) }
  func getSnapshot(in context: Context, completion: @escaping (QuickEntry) -> Void) {
    completion(QuickEntry(date: Date()))
  }
  func getTimeline(in context: Context, completion: @escaping (Timeline<QuickEntry>) -> Void) {
    completion(Timeline(entries: [QuickEntry(date: Date())], policy: .never))
  }
}

enum QuickMode: String, CaseIterable {
  case type, voice, scan

  var url: URL { URL(string: "com.tsudev.qulythuchi:/quick?mode=\(rawValue)")! }
  var symbol: String {
    switch self {
    case .type: return "square.and.pencil"
    case .voice: return "mic"
    case .scan: return "doc.text.viewfinder"
    }
  }
  var label: String {
    let vi = Locale.preferredLanguages.first?.hasPrefix("vi") ?? true
    switch self {
    case .type: return vi ? "Gõ" : "Type"
    case .voice: return vi ? "Nói" : "Speak"
    case .scan: return vi ? "Quét" : "Scan"
    }
  }
}

let brand = Color(red: 0x05 / 255, green: 0x66 / 255, blue: 0x41 / 255)
var titleText: String { (Locale.preferredLanguages.first?.hasPrefix("vi") ?? true) ? "Ghi nhanh" : "Quick add" }

struct QuickWidgetView: View {
  @Environment(\.widgetFamily) var family

  var body: some View {
    content.widgetBackground()
  }

  @ViewBuilder var content: some View {
    switch family {
    case .systemSmall:
      VStack(spacing: 8) {
        Image(systemName: "plus.circle.fill").font(.system(size: 40)).foregroundColor(brand)
        Text(titleText).font(.headline)
      }
      .widgetURL(QuickMode.type.url)
    case .systemMedium:
      VStack(alignment: .leading, spacing: 10) {
        Text(titleText).font(.headline)
        HStack(spacing: 10) {
          ForEach(QuickMode.allCases, id: \.self) { m in
            Link(destination: m.url) {
              VStack(spacing: 6) {
                Image(systemName: m.symbol).font(.title2)
                Text(m.label).font(.caption)
              }
              .frame(maxWidth: .infinity, minHeight: 64)
              .foregroundColor(brand)
              .background(brand.opacity(0.12))
              .cornerRadius(12)
            }
          }
        }
      }
      .padding(4)
    default:
      // Màn hình khoá (iOS 16+): chỉ một biểu tượng, chạm mở Ghi nhanh.
      Image(systemName: "plus.circle").font(.title2).widgetURL(QuickMode.type.url)
    }
  }
}

extension View {
  @ViewBuilder func widgetBackground() -> some View {
    if #available(iOS 17.0, *) {
      containerBackground(for: .widget) { Color(UIColor.systemBackground) }
    } else {
      self
    }
  }
}

@main
struct QuickWidget: Widget {
  var families: [WidgetFamily] {
    if #available(iOS 16.0, *) { return [.systemSmall, .systemMedium, .accessoryCircular] }
    return [.systemSmall, .systemMedium]
  }

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "QuickAddWidget", provider: QuickProvider()) { _ in QuickWidgetView() }
      .configurationDisplayName(titleText)
      .description(
        (Locale.preferredLanguages.first?.hasPrefix("vi") ?? true)
          ? "Mở Ghi nhanh: gõ, nói hoặc quét hoá đơn. Không hiển thị số dư."
          : "Open Quick add: type, speak or scan a receipt. Shows no balances.")
      .supportedFamilies(families)
  }
}
