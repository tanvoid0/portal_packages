import 'package:flutter/material.dart';

/// Tiny trend line for portfolio cards in showcase screens.
class ShowcaseSparkline extends StatelessWidget {
  const ShowcaseSparkline({
    required this.color,
    super.key,
    this.points = const [0.3, 0.5, 0.4, 0.7, 0.6, 0.85, 0.75],
    this.height = 32,
  });

  final Color color;
  final List<double> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(points: points, color: color),
        size: const Size(double.infinity, 32),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.points, required this.color});

  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final stepX = size.width / (points.length - 1);

    for (var i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = size.height * (1 - points[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.points != points;
  }
}
