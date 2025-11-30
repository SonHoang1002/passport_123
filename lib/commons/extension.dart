import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pass1_/commons/constants.dart';

extension DoubleExtension on double {
  String roundWithUnit({String? unitTitle, int? fractionDigits}) {
    if (unitTitle == null) {
      if (fractionDigits == null) {
        return toString();
      } else {
        return toStringAsFixed(fractionDigits);
      }
    }
    switch (unitTitle) {
      case titleInch:
        return roundWithUnit(fractionDigits: 2);
      case titleCentimet:
        return roundWithUnit(fractionDigits: 2);
      case titleMinimet:
      case titlePoint:
        return roundWithUnit(fractionDigits: 1);
      case titlePixel:
      default:
        return round().toString();
    }
  }

  double roundWithDigits(int numberDigits) {
    return double.parse(toStringAsFixed(numberDigits));
  }

  double get toDegreeFromRadian {
    return this / math.pi * 180;
  }

  double get toRadianFromDegree {
    return this * math.pi / 180;
  }
}

extension SizeExtension on Size {
  Size limitToInner(Size outerSize) {
    if (width <= outerSize.width && height <= outerSize.height) {
      return this;
    }

    double selfRatio = aspectRatio;
    double outerRatio = outerSize.aspectRatio;
    double rWidth, rHeight;
    if (selfRatio > outerRatio) {
      rWidth = outerSize.width;
      rHeight = rWidth / selfRatio;
    } else if (selfRatio < outerRatio) {
      rHeight = outerSize.height;
      rWidth = rHeight * selfRatio;
    } else {
      rHeight = outerSize.height;
      rWidth = outerSize.width;
    }
    return Size(rWidth, rHeight);
  }
}
