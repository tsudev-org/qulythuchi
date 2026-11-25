// TỆP SINH TỰ ĐỘNG bởi tool/gen_tokens.dart - KHÔNG SỬA TAY.
// Nguồn: .standards/tokens/design-tokens.json v4.0.0 + products/qulythuchi.json

import 'dart:ui' show Color;

/// Bảng màu một chế độ (Sáng/Tối). Chế độ Ấm đã ngừng dùng (DESIGN_SYSTEM.md mục 1).
final class QtPalette {
  const QtPalette({
    required this.bgBase,
    required this.bgSurface,
    required this.bgSubtle,
    required this.bgHover,
    required this.border,
    required this.borderStrong,
    required this.borderControl,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textLink,
    required this.primary,
    required this.primaryHover,
    required this.primaryActive,
    required this.onPrimary,
    required this.focusRing,
    required this.accent,
    required this.glow,
    required this.iconInfo,
    required this.iconNav,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.onStatus,
    required this.overlay,
  });
  final Color bgBase;
  final Color bgSurface;
  final Color bgSubtle;
  final Color bgHover;
  final Color border;
  final Color borderStrong;
  final Color borderControl;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textLink;
  final Color primary;
  final Color primaryHover;
  final Color primaryActive;
  final Color onPrimary;
  final Color focusRing;
  final Color accent;
  final Color glow;
  final Color iconInfo;
  final Color iconNav;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color onStatus;
  final Color overlay;
  static const light = QtPalette(
    bgBase: Color(0xFFEEF1F5),
    bgSurface: Color(0xFFF8FAFC),
    bgSubtle: Color(0xFFE9EDF2),
    bgHover: Color(0xFFE6EAF0),
    border: Color(0xFFD5DBE3),
    borderStrong: Color(0xFFC3CBD6),
    borderControl: Color(0xFF64748B),
    textPrimary: Color(0xFF0A0A0A),
    textSecondary: Color(0xFF334155),
    textMuted: Color(0xFF475569),
    textLink: Color(0xFF056641),
    primary: Color(0xFF05794F),
    primaryHover: Color(0xFF056641),
    primaryActive: Color(0xFF005334),
    onPrimary: Color(0xFFFFFFFF),
    focusRing: Color(0xFF05794F),
    accent: Color(0xFF045738),
    glow: Color(0x1A05794F),
    iconInfo: Color(0xFF05794F),
    iconNav: Color(0xFF056641),
    success: Color(0xFF15803D),
    warning: Color(0xFFB45309),
    danger: Color(0xFFDC2626),
    info: Color(0xFF0369A1),
    onStatus: Color(0xFFFFFFFF),
    overlay: Color(0x730A0A0A),
  );
  static const dark = QtPalette(
    bgBase: Color(0xFF0A0A0A),
    bgSurface: Color(0xFF0F1114),
    bgSubtle: Color(0xFF15181D),
    bgHover: Color(0xFF1C2027),
    border: Color(0xFF22272F),
    borderStrong: Color(0xFF2C323C),
    borderControl: Color(0xFF6E6E6E),
    textPrimary: Color(0xFFEDEDED),
    textSecondary: Color(0xFFB4B4B4),
    textMuted: Color(0xFF8F8F8F),
    textLink: Color(0xFF63C795),
    primary: Color(0xFF39BA81),
    primaryHover: Color(0xFF67CA98),
    primaryActive: Color(0xFF12A46C),
    onPrimary: Color(0xFF0A0A0A),
    focusRing: Color(0xFF39BA81),
    accent: Color(0xFF8DDBB1),
    glow: Color(0x2439BA81),
    iconInfo: Color(0xFF39BA81),
    iconNav: Color(0xFF63C795),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    info: Color(0xFF38BDF8),
    onStatus: Color(0xFF0A0A0A),
    overlay: Color(0x99000000),
  );
}

/// Màu biểu đồ (token mở rộng: design/tokens.qulythuchi.json, đã kiểm bằng validate_palette).
final class QtChartPalette {
  const QtChartPalette({
    required this.series1,
    required this.series2,
    required this.seq1,
    required this.seq2,
    required this.seq3,
    required this.seq4,
    required this.seq5,
  });
  final Color series1;
  final Color series2;
  final Color seq1;
  final Color seq2;
  final Color seq3;
  final Color seq4;
  final Color seq5;
  static const light = QtChartPalette(
    series1: Color(0xFF2A78D6),
    series2: Color(0xFFEB6834),
    seq1: Color(0xFFCDE2FB),
    seq2: Color(0xFF9EC5F4),
    seq3: Color(0xFF6DA7EC),
    seq4: Color(0xFF3987E5),
    seq5: Color(0xFF1C5CAB),
  );
  static const dark = QtChartPalette(
    series1: Color(0xFF3987E5),
    series2: Color(0xFFD95926),
    seq1: Color(0xFF184F95),
    seq2: Color(0xFF256ABF),
    seq3: Color(0xFF3987E5),
    seq4: Color(0xFF6DA7EC),
    seq5: Color(0xFF9EC5F4),
  );

  /// Dải tuần tự 5 bậc (thấp → cao).
  List<Color> get sequential => [seq1, seq2, seq3, seq4, seq5];
}

/// Bo góc (px) - bộ `mem` của bản sắc; `control` cho nút.
abstract final class QtRadius {
  static const double none = 0.0;
  static const double sm = 6.0;
  static const double md = 10.0;
  static const double lg = 14.0;
  static const double control = 10.0;
}

/// Khoảng cách bội số 4px.
abstract final class QtSpace {
  static const double s1 = 4.0;
  static const double s2 = 8.0;
  static const double s3 = 12.0;
  static const double s4 = 16.0;
  static const double s5 = 20.0;
  static const double s6 = 24.0;
  static const double s8 = 32.0;
  static const double s10 = 40.0;
  static const double s12 = 48.0;
}

/// Cỡ chữ (px).
abstract final class QtFontSize {
  static const double xs = 12.0;
  static const double sm = 13.0;
  static const double bodyDesktop = 14.0;
  static const double bodyDesktopLg = 15.0;
  static const double bodyWeb = 15.0;
  static const double bodyWebLg = 16.0;
  static const double h4 = 18.0;
  static const double h3 = 20.0;
  static const double h2 = 24.0;
  static const double h1 = 30.0;
}

/// Thời lượng chuyển động (ms).
abstract final class QtMotion {
  static const double fast = 120.0;
  static const double base = 180.0;
  static const double slow = 260.0;
}

/// Chiều cao dòng (hệ số).
abstract final class QtLineHeight {
  static const double heading = 1.3;
  static const double body = 1.55;
  static const double long = 1.6;
}

/// Bản sắc sản phẩm (DESIGN_SYSTEM.md mục 1.2): font tiêu đề h1-h3 + số liệu lớn, bố cục, hoạ tiết.
abstract final class QtBrand {
  static const id = 'qulythuchi';
  static const fontDisplay = 'Be Vietnam Pro';
  static const layout = 'bang-dieu-khien';
  static const shape = 'mem';
  static const motif = 'cot-tang-truong';
}
