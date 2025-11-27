import 'package:flutter/material.dart';
import 'package:passport_photo_2/commons/constants.dart';
import 'dart:ui' as ui;

class HolePainter extends CustomPainter {
  final Color backgroundColor;
  final Size targetSize;

  HolePainter({
    required this.backgroundColor,
    required this.targetSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double startX = (size.width - targetSize.width) / 2;
    final double startY = (size.height - targetSize.height) / 2;
    canvas.saveLayer(Rect.largest, Paint());
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = backgroundColor);
    canvas.drawRect(
        Rect.fromLTWH(startX, startY, targetSize.width, targetSize.height),
        Paint()..blendMode = BlendMode.clear);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class FrameHolePainter extends CustomPainter {
  final Size targetSize;
  final Color lineColor;

  FrameHolePainter({required this.targetSize, required this.lineColor});

  double cornerSize = 20;
  @override
  void paint(Canvas canvas, Size size) {
    Paint paintRectangle = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..color = lineColor;
    Paint paintCorner = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..color = lineColor;
    final double startX = (size.width - targetSize.width) / 2;
    final double startY = (size.height - targetSize.height) / 2;

    // draw rectangle line
    canvas.drawPath(
        Path()
          ..moveTo(startX, startY)
          ..lineTo(startX + targetSize.width, startY)
          ..lineTo(startX + targetSize.width, startY + targetSize.height)
          ..lineTo(startX, startY + targetSize.height)
          ..lineTo(startX, startY),
        paintRectangle);
    // top left
    canvas.drawPath(
      Path()
        ..moveTo(startX - 1, startY + cornerSize)
        ..lineTo(startX - 1, startY - 1)
        ..lineTo(startX + cornerSize + 1, startY - 1),
      paintCorner,
    );
    // top right
    canvas.drawPath(
      Path()
        ..moveTo(startX + targetSize.width - cornerSize, startY - 1)
        ..lineTo(startX + targetSize.width + 1, startY - 1)
        ..lineTo(startX + targetSize.width + 1, startY + cornerSize + 1),
      paintCorner,
    );
    // bottom left
    canvas.drawPath(
        Path()
          ..moveTo(startX - 1, startY + targetSize.height - cornerSize)
          ..lineTo(startX - 1, startY + targetSize.height + 1)
          ..lineTo(startX + cornerSize + 1, startY + targetSize.height + 1),
        paintCorner);
    // bottom right
    canvas.drawPath(
        Path()
          ..moveTo(startX + targetSize.width + 1,
              startY + targetSize.height - cornerSize)
          ..lineTo(
              startX + targetSize.width + 1, startY + targetSize.height + 1)
          ..lineTo(startX + targetSize.width - cornerSize - 1,
              startY + targetSize.height + 1),
        paintCorner);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class CustomPainterBlurredShadowImage extends CustomPainter {
  final ui.Image image;
  final Paint paintBlur;
  final Size targetSize;

  const CustomPainterBlurredShadowImage(
      {required this.paintBlur, required this.image, required this.targetSize});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(
        targetSize.width / image.width, targetSize.height / image.height);
    canvas.drawImage(image, Offset.zero, paintBlur);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class CustomPainterBlurredImage extends CustomPainter {
  final ui.Image image;
  final Size targetSize;

  const CustomPainterBlurredImage(
      {required this.image, required this.targetSize});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(
        targetSize.width / image.width, targetSize.height / image.height);
    canvas.drawImage(
        image,
        Offset.zero,
        PAINT_BLURRED
          ..color = const Color.fromRGBO(
              0, 0, 0, 0.02)); // vi reflection co opacity la 2
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
