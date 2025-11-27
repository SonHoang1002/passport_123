import 'package:flutter/material.dart';

class CropModel {
  int id;
  // Offset? offset;
  Size size;
  double scale;
  double instructionRotateValue;
  double currentRotateValue;

  CropModel({
    required this.id,
    required this.currentRotateValue,
    required this.instructionRotateValue,
    //  this.offset,
    required this.size,
    required this.scale,
  });

  Size get scaledSize => size * scale;
}
