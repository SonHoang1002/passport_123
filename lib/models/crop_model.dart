import 'package:flutter/material.dart';
import 'package:pass1_/helpers/random_number.dart';

class CropModel {
  final int id;
  final int checkId;
  double instructionRotateValue;
  double currentRotateValue;
  Rect cropRect;

  CropModel({
    required this.id,
    required this.checkId,
    required this.currentRotateValue,
    required this.instructionRotateValue,
    required this.cropRect,
  });

  Size get size => cropRect.size;
  double get aspectRatio => size.aspectRatio;
  double get width => cropRect.width;
  double get height => cropRect.height;
  Offset get topLeft => cropRect.topLeft;
  Offset get bottomRight => cropRect.bottomRight;
  Offset get center => cropRect.center;

  factory CropModel.create({
    required double currentRotateValue,
    required double instructionRotateValue,
    required Rect cropRect,
  }) {
    return CropModel(
      id: randomInt(),
      checkId: randomInt(),
      currentRotateValue: currentRotateValue,
      instructionRotateValue: instructionRotateValue,
      cropRect: cropRect,
    );
  }

  CropModel copyWith({
    double? instructionRotateValue,
    double? currentRotateValue,
    Rect? cropRect,
  }) {
    return CropModel(
      id: randomInt(),
      checkId: checkId,
      currentRotateValue: currentRotateValue ?? this.currentRotateValue,
      instructionRotateValue:
          instructionRotateValue ?? this.instructionRotateValue,
      cropRect: cropRect ?? this.cropRect,
    );
  }
}
