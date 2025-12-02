import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/helpers/log_custom.dart';

class FlutterSizeHelpers {
  static bool checkSizeIsSmall(BuildContext context) {
    return getLimitScreenSize(context).width <= MIN_SIZE.width;
  }

  static Size handleScaleWithSpecialDimension({
    required Size originalSize,
    double maxDimension = 1200,
  }) {
    Size newSize = Size(originalSize.width, originalSize.height);
    if (originalSize.height > maxDimension ||
        originalSize.width > maxDimension) {
      double ratioWH = originalSize.width / originalSize.height;
      if (ratioWH > 1) {
        newSize = Size(maxDimension, maxDimension / ratioWH);
      } else if (ratioWH < 1) {
        newSize = Size(maxDimension * ratioWH, maxDimension);
      } else {
        newSize = Size(maxDimension, maxDimension);
      }
    }
    consolelog("handleScaleWithSpecialDimension $originalSize -  $newSize");
    return newSize;
  }

  ///
  ///
  ///  [Android] API level 17:
  ///
  ///  (0 - LandscapeRight)
  ///
  ///  (90 - Portrait)
  ///
  ///  (180 - LandscapeLeft)
  ///
  ///  (270 - portraitUpsideDown)
  ///
  ///
  static Size getSizeFromOrientation(int? orientation, Size originalSize) {
    Size realSize = originalSize;

    switch (orientation) {
      case 0:
      case 180:
        realSize = originalSize;
        break;
      case 90:
      case 270:
        realSize = Size(originalSize.height, originalSize.width);
        break;
    }
    return realSize;
  }

  ///
  /// Giới hạn kích thước của screen nếu quá to
  ///
  static Size getLimitScreenSize(BuildContext context) {
    Size size = MediaQuery.sizeOf(context);
    size = Size(
      min(SIZE_EXAMPLE.width, size.width),
      min(SIZE_EXAMPLE.height, size.height),
    );
    return size;
  }

  ///
  /// Giới hạn kích thước hiển thị thực với tỉ lệ gốc và kích thước tối đa
  ///
  static Size getLimitSize({
    required Size maxSize,
    required Size originalSize,
    double? aspectRatio,
  }) {
    double mainHeight, mainWidth;
    double ratioWH;
    if (aspectRatio != null) {
      ratioWH = aspectRatio;
    } else {
      if (originalSize.height == 0 || originalSize.width == 0) {
        ratioWH = 0;
      } else {
        ratioWH = originalSize.width / originalSize.height;
      }
    }
    if (maxSize.width > maxSize.height) {
      mainHeight = maxSize.height;
      mainWidth = mainHeight * ratioWH;
      if (mainWidth > maxSize.width) {
        mainWidth = maxSize.width;
        mainHeight = mainWidth * (1 / ratioWH);
      }
    } else if (maxSize.width < maxSize.height) {
      mainWidth = maxSize.width;
      mainHeight = mainWidth * (1 / ratioWH);
      if (mainHeight > maxSize.height) {
        mainHeight = maxSize.height;
        mainWidth = mainHeight * ratioWH;
      }
    } else {
      if (ratioWH > 1) {
        mainWidth = maxSize.width;
        mainHeight = mainWidth * (1 / ratioWH);
      } else if (ratioWH < 1) {
        mainHeight = maxSize.height;
        mainWidth = mainHeight * ratioWH;
      } else {
        mainWidth = mainHeight = maxSize.height;
      }
    }
    Size result = Size(mainWidth, mainHeight);
    consolelog("getLimitSize $result");
    return result;
  }

  ///
  /// Giới hạn kích thước thu nhỏ trong trường hợp độ phân giải của video quá to
  ///
  static List<int> getLimitDimension({
    required int dimensionWidth,
    required int dimensionHeight,
    bool isCompress = false,
  }) {
    consolelog(
      "_videoEditorController.videoDimension $dimensionWidth -  $dimensionHeight",
    );
    int mainWidth, mainHeight;
    if (dimensionWidth <= 0 || dimensionHeight <= 0 || !isCompress) {
      return [dimensionWidth, dimensionHeight];
    }
    double ratioWH = dimensionWidth / dimensionHeight;
    if (ratioWH > 1) {
      mainWidth = 1000;
      mainHeight = mainWidth ~/ ratioWH;
    } else if (ratioWH < 1) {
      mainHeight = 1000;
      mainWidth = mainHeight ~/ (1 / ratioWH);
    } else {
      mainHeight = mainWidth = 1000;
    }
    var result = [mainWidth, mainHeight];
    return result;
  }

  ///
  static bool? handleCheckVideoPortrait(Size? realSize) {
    if (realSize == null) return null;
    return (realSize.aspectRatio) <= 1;
  }

  ///
  ///  Giới hạn kích thước của video theo [maxSizeValue] (default: 2160)
  ///
  static Size getLimitSize4K({
    required Size originalSize,
    double? maxSizeValue,
  }) {
    double maxSize = 2160;
    if (maxSizeValue == null) {
      // bool checkSdk = FlutterSdkDevice.checkSdk(24);
      // if (checkSdk) {
      //   maxSize = 3000;
      // } else {
      //   maxSize = 2160;
      // }
    } else {
      maxSize = maxSizeValue;
    }

    Size result = originalSize;
    double ratio = originalSize.width / originalSize.height;
    if (ratio > 1) {
      if (originalSize.width > maxSize) {
        result = Size(maxSize, maxSize / ratio);
      }
    } else if (ratio < 1) {
      if (originalSize.height > maxSize) {
        result = Size(maxSize * ratio, maxSize);
      }
    } else {
      if (originalSize.height > maxSize) {
        result = Size(maxSize, maxSize);
      }
    }
    return result;
  }
}
