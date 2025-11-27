import 'dart:math';

import 'package:flutter/material.dart';

class WCircleDegreePreview extends StatefulWidget {
  final Size size;
  final double degree;
  final Color inactiveColor;
  final Color activeColor;
  const WCircleDegreePreview({
    super.key,
    required this.size,
    required this.degree,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  State<WCircleDegreePreview> createState() => _CircleDegreePreviewState();
}

class _CircleDegreePreviewState extends State<WCircleDegreePreview> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: WCirclePainter(
        degree: widget.degree,
        inactiveColor: widget.inactiveColor,
        activeColor: widget.activeColor,
      ),
      size: widget.size,
    );
  }
}

class WCirclePainter extends CustomPainter {
  final double degree;
  final Color inactiveColor;
  final Color activeColor;
  WCirclePainter({
    required this.degree,
    required this.activeColor,
    required this.inactiveColor,
  });
  @override
  void paint(Canvas canvas, Size size) {
    var paintArc = Paint()
      ..color = activeColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    var paintCircle = Paint()
      // ..color = Colors.grey.withValues(alpha:0.6)
      ..color = inactiveColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double radius = size.width / 2;
    double centerX = size.width / 2;
    double centerY = size.height / 2;

    double startAngle = 3 * pi / 2;
    double endAngle = degree * (pi / 90);
    canvas.drawCircle(Offset(centerX, centerY), radius, paintCircle);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      startAngle,
      endAngle,
      false,
      paintArc,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
