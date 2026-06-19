import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom thin-stroke icons for ClipQ v2.
/// Avoids default Material icons to establish a premium, custom UI look.

class ClipTextIcon extends StatelessWidget {
  final Color? color;
  final double size;

  const ClipTextIcon({super.key, this.color, this.size = 16.0});

  @override
  Widget build(BuildContext context) {
    final defaultColor = color ?? Theme.of(context).iconTheme.color ?? const Color(0xFF52525B);
    return CustomPaint(
      size: Size(size, size),
      painter: _TextPainter(color: defaultColor),
    );
  }
}

class _TextPainter extends CustomPainter {
  final Color color;
  _TextPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.35),
      Offset(size.width * 0.85, size.height * 0.35),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.65),
      Offset(size.width * 0.65, size.height * 0.65),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _TextPainter oldDelegate) => oldDelegate.color != color;
}

class ClipCodeIcon extends StatelessWidget {
  final Color? color;
  final double size;

  const ClipCodeIcon({super.key, this.color, this.size = 16.0});

  @override
  Widget build(BuildContext context) {
    final defaultColor = color ?? Theme.of(context).iconTheme.color ?? const Color(0xFF52525B);
    return CustomPaint(
      size: Size(size, size),
      painter: _CodePainter(color: defaultColor),
    );
  }
}

class _CodePainter extends CustomPainter {
  final Color color;
  _CodePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    final pathLeft = Path()
      ..moveTo(w * 0.35, h * 0.25)
      ..lineTo(w * 0.15, h * 0.5)
      ..lineTo(w * 0.35, h * 0.75);
    canvas.drawPath(pathLeft, paint);

    final pathRight = Path()
      ..moveTo(w * 0.65, h * 0.25)
      ..lineTo(w * 0.85, h * 0.5)
      ..lineTo(w * 0.65, h * 0.75);
    canvas.drawPath(pathRight, paint);
  }

  @override
  bool shouldRepaint(covariant _CodePainter oldDelegate) => oldDelegate.color != color;
}

class ClipLinkIcon extends StatelessWidget {
  final Color? color;
  final double size;

  const ClipLinkIcon({super.key, this.color, this.size = 16.0});

  @override
  Widget build(BuildContext context) {
    final defaultColor = color ?? Theme.of(context).iconTheme.color ?? const Color(0xFF52525B);
    return CustomPaint(
      size: Size(size, size),
      painter: _LinkPainter(color: defaultColor),
    );
  }
}

class _LinkPainter extends CustomPainter {
  final Color color;
  _LinkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    canvas.save();
    canvas.translate(w * 0.58, h * 0.42);
    canvas.rotate(-0.785398);
    final rrect1 = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 8, height: 4),
      const Radius.circular(2),
    );
    canvas.drawRRect(rrect1, paint);
    canvas.restore();

    canvas.save();
    canvas.translate(w * 0.42, h * 0.58);
    canvas.rotate(-0.785398);
    final rrect2 = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 8, height: 4),
      const Radius.circular(2),
    );
    canvas.drawRRect(rrect2, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LinkPainter oldDelegate) => oldDelegate.color != color;
}

class ClipImageIcon extends StatelessWidget {
  final Color? color;
  final double size;

  const ClipImageIcon({super.key, this.color, this.size = 16.0});

  @override
  Widget build(BuildContext context) {
    final defaultColor = color ?? Theme.of(context).iconTheme.color ?? const Color(0xFF52525B);
    return CustomPaint(
      size: Size(size, size),
      painter: _ImagePainter(color: defaultColor),
    );
  }
}

class _ImagePainter extends CustomPainter {
  final Color color;
  _ImagePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    final outerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.1, h * 0.1, w * 0.8, h * 0.8),
      const Radius.circular(2),
    );
    canvas.drawRRect(outerRect, paint);

    final mountain = Path()
      ..moveTo(w * 0.15, h * 0.75)
      ..lineTo(w * 0.45, h * 0.4)
      ..lineTo(w * 0.65, h * 0.6)
      ..lineTo(w * 0.75, h * 0.5)
      ..lineTo(w * 0.85, h * 0.7)
      ..lineTo(w * 0.85, h * 0.75);
    canvas.drawPath(mountain, paint);

    final sunPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.65, h * 0.3), 1.0, sunPaint);
  }

  @override
  bool shouldRepaint(covariant _ImagePainter oldDelegate) => oldDelegate.color != color;
}

class ClipCopyIcon extends StatelessWidget {
  final Color? color;
  final double size;

  const ClipCopyIcon({super.key, this.color, this.size = 16.0});

  @override
  Widget build(BuildContext context) {
    final defaultColor = color ?? Theme.of(context).iconTheme.color ?? const Color(0xFF52525B);
    return CustomPaint(
      size: Size(size, size),
      painter: _CopyPainter(color: defaultColor),
    );
  }
}

class _CopyPainter extends CustomPainter {
  final Color color;
  _CopyPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    final backPath = Path()
      ..moveTo(w * 0.15, h * 0.45)
      ..lineTo(w * 0.15, h * 0.15)
      ..lineTo(w * 0.65, h * 0.15)
      ..lineTo(w * 0.65, h * 0.45);
    canvas.drawPath(backPath, paint);

    final frontRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.35, h * 0.35, w * 0.5, h * 0.5),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(frontRRect, paint);
  }

  @override
  bool shouldRepaint(covariant _CopyPainter oldDelegate) => oldDelegate.color != color;
}

class ClipDeleteIcon extends StatelessWidget {
  final Color? color;
  final double size;

  const ClipDeleteIcon({super.key, this.color, this.size = 16.0});

  @override
  Widget build(BuildContext context) {
    final defaultColor = color ?? Theme.of(context).iconTheme.color ?? const Color(0xFF52525B);
    return CustomPaint(
      size: Size(size, size),
      painter: _DeletePainter(color: defaultColor),
    );
  }
}

class _DeletePainter extends CustomPainter {
  final Color color;
  _DeletePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    canvas.drawLine(Offset(w * 0.15, h * 0.25), Offset(w * 0.85, h * 0.25), paint);

    final lidHandle = Path()
      ..moveTo(w * 0.38, h * 0.25)
      ..lineTo(w * 0.38, h * 0.15)
      ..lineTo(w * 0.62, h * 0.15)
      ..lineTo(w * 0.62, h * 0.25);
    canvas.drawPath(lidHandle, paint);

    final body = Path()
      ..moveTo(w * 0.23, h * 0.25)
      ..lineTo(w * 0.26, h * 0.85)
      ..lineTo(w * 0.74, h * 0.85)
      ..lineTo(w * 0.77, h * 0.25);
    canvas.drawPath(body, paint);

    canvas.drawLine(Offset(w * 0.42, h * 0.4), Offset(w * 0.42, h * 0.7), paint);
    canvas.drawLine(Offset(w * 0.58, h * 0.4), Offset(w * 0.58, h * 0.7), paint);
  }

  @override
  bool shouldRepaint(covariant _DeletePainter oldDelegate) => oldDelegate.color != color;
}

class ClipSettingsIcon extends StatelessWidget {
  final Color? color;
  final double size;

  const ClipSettingsIcon({super.key, this.color, this.size = 16.0});

  @override
  Widget build(BuildContext context) {
    final defaultColor = color ?? Theme.of(context).iconTheme.color ?? const Color(0xFF52525B);
    return CustomPaint(
      size: Size(size, size),
      painter: _SettingsPainter(color: defaultColor),
    );
  }
}

class _SettingsPainter extends CustomPainter {
  final Color color;
  _SettingsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    final double rOuter = w * 0.38;
    final double rInner = w * 0.24;
    final double rHole = w * 0.12;

    final path = Path();
    const int teeth = 8;

    for (int i = 0; i < teeth; i++) {
      final double angle = i * 2 * math.pi / teeth;
      final double nextAngle = (i + 1) * 2 * math.pi / teeth;

      final double x1 = cx + math.cos(angle - 0.15) * rInner;
      final double y1 = cy + math.sin(angle - 0.15) * rInner;
      final double x2 = cx + math.cos(angle - 0.08) * rOuter;
      final double y2 = cy + math.sin(angle - 0.08) * rOuter;
      final double x3 = cx + math.cos(angle + 0.08) * rOuter;
      final double y3 = cy + math.sin(angle + 0.08) * rOuter;
      final double x4 = cx + math.cos(angle + 0.15) * rInner;
      final double y4 = cy + math.sin(angle + 0.15) * rInner;

      if (i == 0) {
        path.moveTo(x1, y1);
      } else {
        path.lineTo(x1, y1);
      }
      path.lineTo(x2, y2);
      path.lineTo(x3, y3);
      path.lineTo(x4, y4);

      final double nextX1 = cx + math.cos(nextAngle - 0.15) * rInner;
      final double nextY1 = cy + math.sin(nextAngle - 0.15) * rInner;
      path.lineTo(nextX1, nextY1);
    }
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(cx, cy), rHole, paint);
  }

  @override
  bool shouldRepaint(covariant _SettingsPainter oldDelegate) => oldDelegate.color != color;
}

class ClipSearchIcon extends StatelessWidget {
  final Color? color;
  final double size;

  const ClipSearchIcon({super.key, this.color, this.size = 16.0});

  @override
  Widget build(BuildContext context) {
    final defaultColor = color ?? Theme.of(context).iconTheme.color ?? const Color(0xFF52525B);
    return CustomPaint(
      size: Size(size, size),
      painter: _SearchPainter(color: defaultColor),
    );
  }
}

class _SearchPainter extends CustomPainter {
  final Color color;
  _SearchPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    canvas.drawCircle(Offset(w * 0.43, h * 0.43), w * 0.22, paint);

    canvas.drawLine(
      Offset(w * 0.58, h * 0.58),
      Offset(w * 0.82, h * 0.82),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SearchPainter oldDelegate) => oldDelegate.color != color;
}
