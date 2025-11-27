import 'package:flutter/material.dart';
import 'package:passport_photo_2/helpers/random_number.dart';
import 'package:passport_photo_2/models/country_passport_model.dart';

class ExportSizeModel {
  final int uid;
  final int id;
  final String title;
  final Size size;
  final Unit unit;
  final MarginModel marginModel;
  final double spacingHorizontal;
  final double spacingVertical;
  ExportSizeModel({
    required this.uid,
    required this.id,
    required this.title,
    required this.size,
    required this.unit,
    required this.marginModel,
    required this.spacingHorizontal,
    required this.spacingVertical,
  });

  double get width => size.width;
  double get height => size.height;

  ExportSizeModel copyWith({
    int? id,
    String? title,
    Size? size,
    Unit? unit,
    MarginModel? marginModel,
    double? spacingHorizontal,
    double? spacingVertical,
  }) {
    return ExportSizeModel(
      uid: randomInt(),
      id: id ?? this.id,
      title: title ?? this.title,
      size: size ?? this.size,
      unit: unit ?? this.unit,
      marginModel: marginModel ?? this.marginModel,
      spacingHorizontal: spacingHorizontal ?? this.spacingHorizontal,
      spacingVertical: spacingVertical ?? this.spacingVertical,
    );
  }

  @override
  String toString() {
    return 'ExportSizeModel infor: uid: $uid, id: $id, title: $title, size: $size, unit: $unit, marginModel: $marginModel, spacingHorizontal: ${spacingHorizontal}, spacingVertical: ${spacingVertical}';
  }
}

class MarginModel {
  final double mLeft;
  final double mTop;
  final double mRight;
  final double mBottom;

  MarginModel({
    required this.mLeft,
    required this.mTop,
    required this.mRight,
    required this.mBottom,
  });

  static MarginModel marginAll(double marginAll) {
    return MarginModel(
      mLeft: marginAll,
      mTop: marginAll,
      mRight: marginAll,
      mBottom: marginAll,
    );
  }

  static MarginModel marginSymmetric({double? horizontal, double? vertical}) {
    return MarginModel(
      mLeft: horizontal ?? 0,
      mTop: vertical ?? 0,
      mRight: horizontal ?? 0,
      mBottom: vertical ?? 0,
    );
  }

  EdgeInsets toEdgeInsets() {
    EdgeInsets margin = EdgeInsets.fromLTRB(
      mLeft,
      mTop,
      mRight,
      mBottom,
    );
    return margin;
  }

  List<double> toList() {
    return [
      mLeft,
      mTop,
      mRight,
      mBottom,
    ];
  }

  // MarginModel copyWith({int? id, String? title, Size? size, Unit? unit}) {
  //   return MarginModel(
  //     id: id ?? this.id,
  //     title: title ?? this.title,
  //     size: size ?? this.size,
  //     unit: unit ?? this.unit,
  //   );
  // }
}
