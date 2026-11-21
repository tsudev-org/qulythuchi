import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';

/// Hoạ tiết chữ ký `cot-tang-truong` (tsudev-standards v5.0.0, DESIGN_SYSTEM.md mục 1.2.4): cột tăng dần, TĨNH, tô
/// `accent` với độ phủ ≤ 15%. Cùng công thức với apps/site/src/lib/cot-tang-truong.mjs (hero website + og-image).
const cotSoCot = 9;
const cotDoPhu = 0.12;

/// Các cột trong khung [size]: cao từ 22% tới 100%, cột chiếm 62% bước.
List<Rect> cotTangTruong(Size size, {int soCot = cotSoCot}) {
  final buoc = size.width / soCot;
  final be = buoc * 0.62;
  return [
    for (var i = 0; i < soCot; i++)
      () {
        final h = size.height * (0.22 + 0.78 * math.pow(i / (soCot - 1), 1.15));
        return Rect.fromLTWH(i * buoc + (buoc - be) / 2, size.height - h, be, h);
      }(),
  ];
}

class CotTangTruongPainter extends CustomPainter {
  const CotTangTruongPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: cotDoPhu);
    final r = Radius.circular(QtRadius.sm);
    for (final c in cotTangTruong(size)) {
      canvas.drawRRect(RRect.fromRectAndCorners(c, topLeft: r, topRight: r), paint);
    }
  }

  @override
  bool shouldRepaint(CotTangTruongPainter old) => old.color != color;
}

/// Nền trang trí (không đọc bởi trình đọc màn hình), màu `accent` của bản sắc theo chế độ đang dùng.
class CotTangTruong extends StatelessWidget {
  const CotTangTruong({super.key});

  @override
  Widget build(BuildContext context) =>
      ExcludeSemantics(child: CustomPaint(painter: CotTangTruongPainter(context.palette.accent)));
}
