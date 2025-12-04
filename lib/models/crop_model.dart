import 'dart:math';
import 'package:pass1_/helpers/random_number.dart';

// class CropModel {
//   int id;
//   // Offset? offset;
//   Size size;
//   double scale;
//   double instructionRotateValue;
//   double currentRotateValue;

//   CropModel({
//     required this.id,
//     required this.currentRotateValue,
//     required this.instructionRotateValue,
//     //  this.offset,
//     required this.size,
//     required this.scale,
//   });

//   Size get scaledSize => size * scale;
// }

class CropModel {
  final int id;
  final int checkId;
  double instructionRotateValue;
  double currentRotateValue;

  /// tỉ lệ vị trí của điểm left đến cạnh trái của ảnh gốc
  double ratioLeftInImage;

  /// tỉ lệ vị trí của điểm top đến cạnh trên của ảnh gốc
  double ratioTopInImage;

  /// tỉ lệ vị trí của điểm right đến cạnh phải của ảnh gốc
  double ratioRightInImage;

  /// tỉ lệ vị trí của điểm bottom đến cạnh dưới của ảnh gốc
  double ratioBottomInImage;

  CropModel({
    required this.id,
    required this.checkId,
    required this.currentRotateValue,
    required this.instructionRotateValue,
    required this.ratioLeftInImage,
    required this.ratioTopInImage,
    required this.ratioRightInImage,
    required this.ratioBottomInImage,
  });

  // Size get size => cropRect.size;
  // double get aspectRatio => size.aspectRatio;
  // double get width => cropRect.width;
  // double get height => cropRect.height;
  // Offset get topLeft => cropRect.topLeft;
  // Offset get bottomRight => cropRect.bottomRight;
  // Offset get center => cropRect.center;

  factory CropModel.create({
    required double currentRotateValue,
    required double instructionRotateValue,
    required double ratioLeftInImage,
    required double ratioTopInImage,
    required double ratioRightInImage,
    required double ratioBottomInImage,
  }) {
    return CropModel(
      id: randomInt(),
      checkId: randomInt(),
      currentRotateValue: currentRotateValue,
      instructionRotateValue: instructionRotateValue,
      ratioLeftInImage: ratioLeftInImage,
      ratioTopInImage: ratioTopInImage,
      ratioRightInImage: ratioRightInImage,
      ratioBottomInImage: ratioBottomInImage,
    );
  }

  double get getAngleByRadian =>
      (currentRotateValue - instructionRotateValue) * 90 * pi / 180;

  CropModel copyWith({
    double? instructionRotateValue,
    double? currentRotateValue,
    double? ratioLeftInImage,
    double? ratioTopInImage,
    double? ratioRightInImage,
    double? ratioBottomInImage,
  }) {
    return CropModel(
      id: randomInt(),
      checkId: checkId,
      currentRotateValue: currentRotateValue ?? this.currentRotateValue,
      instructionRotateValue:
          instructionRotateValue ?? this.instructionRotateValue,
      ratioLeftInImage: ratioLeftInImage ?? this.ratioLeftInImage,
      ratioTopInImage: ratioTopInImage ?? this.ratioTopInImage,
      ratioRightInImage: ratioRightInImage ?? this.ratioRightInImage,
      ratioBottomInImage: ratioBottomInImage ?? this.ratioBottomInImage,
    );
  }

  @override
  String toString() {
    return 'CropModel(id: $id, checkId: $checkId, instructionRotateValue: $instructionRotateValue, currentRotateValue: $currentRotateValue, ratioLeftInImage: $ratioLeftInImage, ratioTopInImage: $ratioTopInImage, ratioRightInImage: $ratioRightInImage, ratioBottomInImage: $ratioBottomInImage,)';
  }
}
