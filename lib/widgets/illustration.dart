import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Original vector artwork. Scales without loading images or using the network.
class NeighborhoodArt extends StatelessWidget {
  final int variant;
  const NeighborhoodArt({super.key, this.variant = 0});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      painter: _NeighborhoodPainter(variant),
      size: Size.infinite,
    ),
  );
}

class _NeighborhoodPainter extends CustomPainter {
  final int variant;
  _NeighborhoodPainter(this.variant);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final scale = math.min(size.width / 320, size.height / 240);
    canvas.translate(
      (size.width - 320 * scale) / 2,
      (size.height - 240 * scale) / 2,
    );
    canvas.scale(scale);
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final black = Paint()..color = ink;
    final white = Paint()..color = const Color(0xFFFFFEF5);
    final accent = Paint()
      ..color = variant == 1 ? yellow : const Color(0xFFECECE2);
    void ln(double x, double y, double xx, double yy) =>
        canvas.drawLine(Offset(x, y), Offset(xx, yy), stroke);
    void box(
      double x,
      double y,
      double w,
      double h,
      Paint fill, {
      double r = 0,
    }) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        Radius.circular(r),
      );
      canvas.drawRRect(rect, fill);
      canvas.drawRRect(rect, stroke);
    }

    // Sun, floating cloud and a shared patch of ground.
    canvas.drawCircle(const Offset(268, 39), 20, black);
    for (int i = 0; i < 4; i++) {
      ln(239 + i * 13, 8, 242 + i * 13, 2);
    }
    final cloud = Path()
      ..moveTo(19, 48)
      ..cubicTo(11, 34, 31, 29, 39, 35)
      ..cubicTo(43, 15, 72, 17, 76, 35)
      ..cubicTo(95, 26, 106, 47, 96, 54)
      ..lineTo(23, 54)
      ..close();
    canvas.drawPath(cloud, white);
    canvas.drawPath(cloud, stroke);
    canvas.drawOval(const Rect.fromLTWH(11, 188, 300, 42), accent);
    ln(10, 210, 308, 210);
    // Three welcoming apartment blocks.
    box(116, 63, 68, 143, white, r: 3);
    box(184, 93, 57, 113, white, r: 3);
    box(71, 111, 45, 95, white, r: 3);
    for (int y = 0; y < 5; y++) {
      for (int x = 0; x < 3; x++) {
        box(
          128 + x * 17,
          76 + y * 22,
          7,
          10,
          y == 2 && x == 1 ? black : accent,
          r: 1,
        );
      }
    }
    for (int y = 0; y < 4; y++) {
      for (int x = 0; x < 2; x++) {
        box(197 + x * 21, 107 + y * 22, 8, 10, accent, r: 1);
      }
    }
    for (int y = 0; y < 3; y++) {
      for (int x = 0; x < 2; x++) {
        box(80 + x * 17, 124 + y * 22, 6, 9, accent, r: 1);
      }
    }
    box(141, 184, 17, 22, black, r: 2);
    // Tree.
    ln(271, 155, 271, 209);
    final tree = Path()
      ..moveTo(271, 106)
      ..cubicTo(251, 115, 245, 145, 253, 153)
      ..cubicTo(260, 163, 287, 163, 293, 151)
      ..cubicTo(298, 139, 286, 114, 271, 106)
      ..close();
    canvas.drawPath(tree, white);
    canvas.drawPath(tree, stroke);
    ln(271, 146, 281, 136);
    // Two residents, drawn with the same rounded line language.
    void person(double x, double y, bool dark, bool waving) {
      final fill = dark ? black : white;
      canvas.drawCircle(Offset(x, y), 10, white);
      canvas.drawCircle(Offset(x, y), 10, stroke);
      final hair = Path()
        ..moveTo(x - 9, y - 3)
        ..quadraticBezierTo(x - 10, y - 15, x + 2, y - 11)
        ..quadraticBezierTo(x + 12, y - 11, x + 10, y - 2)
        ..quadraticBezierTo(x + 2, y - 2, x, y - 7)
        ..close();
      canvas.drawPath(hair, black);
      final body = Path()
        ..moveTo(x - 7, y + 13)
        ..quadraticBezierTo(x, y + 9, x + 8, y + 14)
        ..lineTo(x + 13, y + 40)
        ..lineTo(x - 13, y + 40)
        ..close();
      canvas.drawPath(body, fill);
      canvas.drawPath(body, stroke);
      ln(x - 6, y + 41, x - 8, y + 61);
      ln(x + 6, y + 41, x + 10, y + 61);
      ln(x - 8, y + 61, x - 14, y + 61);
      ln(x + 10, y + 61, x + 16, y + 61);
      ln(x - 10, y + 18, x - 22, y + 30);
      if (waving) {
        ln(x + 10, y + 17, x + 24, y + 5);
        ln(x + 24, y + 5, x + 23, y - 7);
      } else {
        ln(x + 11, y + 20, x + 23, y + 30);
      }
    }

    person(45, 147, true, true);
    person(249, 166, false, false);
    // Little sparkles.
    ln(23, 105, 23, 91);
    ln(16, 98, 30, 98);
    ln(298, 86, 298, 76);
    ln(293, 81, 303, 81);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_NeighborhoodPainter oldDelegate) =>
      oldDelegate.variant != variant;
}

class BrandMark extends StatelessWidget {
  final double size;
  final Color color;
  const BrandMark({super.key, this.size = 32, this.color = ink});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: Size.square(size), painter: _BrandPainter(color)),
  );
}

class _BrandPainter extends CustomPainter {
  final Color color;
  _BrandPainter(this.color);
  @override
  void paint(Canvas c, Size s) {
    c.scale(s.width / 32);
    final p = Paint()
      ..color = color
      ..strokeWidth = 2.7
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    c.drawPath(
      Path()
        ..moveTo(3, 16)
        ..lineTo(11, 8)
        ..lineTo(19, 16)
        ..lineTo(19, 29)
        ..lineTo(3, 29)
        ..close(),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(15, 8)
        ..lineTo(22, 2)
        ..lineTo(29, 8)
        ..lineTo(29, 24)
        ..lineTo(24, 24),
      p,
    );
    c.drawLine(const Offset(10, 22), const Offset(10, 29), p);
    c.drawCircle(const Offset(22, 11), 1, p);
  }

  @override
  bool shouldRepaint(_BrandPainter oldDelegate) => oldDelegate.color != color;
}
