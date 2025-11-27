import 'dart:math';

import 'package:flutter/material.dart';

///
/// Giói hạn hiển thị của các passport bên trong khổ giấy
///
Size getRealSizeInPaper(
  double widthPassport,
  double heightPassport,
  Size format,
) {
  double mainWidthPassport, mainHeightPassport;
  double passportRatioWH = widthPassport / heightPassport;
  if (format.width < format.height) {
    // anh ngang
    if (passportRatioWH > 1) {
      if (widthPassport >= format.width) {
        mainWidthPassport = format.width;
        mainHeightPassport = mainWidthPassport * (1 / passportRatioWH);
      } else {
        mainWidthPassport = widthPassport;
        mainHeightPassport = heightPassport;
      }
    } else if (passportRatioWH < 1) {
      if (heightPassport >= format.height) {
        mainHeightPassport = format.height;
        mainWidthPassport = mainHeightPassport * passportRatioWH;
        // truong hop chieu dai moi lon hon format.width
        if (mainWidthPassport >= format.width) {
          mainWidthPassport = format.width;
          mainHeightPassport = mainWidthPassport * (1 / passportRatioWH);
        }
      } else {
        if (widthPassport >= format.width) {
          mainWidthPassport = format.width;
          mainHeightPassport = mainWidthPassport * (1 / passportRatioWH);
        } else {
          ////
          mainWidthPassport = widthPassport;
          mainHeightPassport = heightPassport;
        }
      }
    } else {
      // so sanh voi chieu be nhat cua giay
      if (widthPassport >= format.width) {
        mainWidthPassport = mainHeightPassport = format.width;
      } else {
        mainWidthPassport = mainHeightPassport = heightPassport;
      }
    }
  } else if (format.width > format.height) {
    // anh doc
    if (passportRatioWH < 1) {
      if (heightPassport >= format.height) {
        mainHeightPassport = format.height;
        mainWidthPassport = mainHeightPassport * passportRatioWH;
      } else {
        mainWidthPassport = widthPassport;
        mainHeightPassport = heightPassport;
      }
    } else if (passportRatioWH > 1) {
      if (widthPassport >= format.width) {
        mainWidthPassport = format.width;
        mainHeightPassport = mainWidthPassport * (1 / passportRatioWH);
        if (mainHeightPassport > format.height) {
          mainHeightPassport = format.height;
          mainWidthPassport = mainHeightPassport * passportRatioWH;
        }
      } else {
        if (heightPassport >= format.height) {
          mainHeightPassport = format.height;
          mainWidthPassport = mainHeightPassport * passportRatioWH;
        } else {
          ////
          mainWidthPassport = widthPassport;
          mainHeightPassport = heightPassport;
        }
      }
    } else {
      if (widthPassport >= format.height) {
        mainHeightPassport = mainWidthPassport = format.height;
      } else {
        mainHeightPassport = mainWidthPassport = heightPassport;
      }
    }
  } else {
    if (passportRatioWH > 1) {
      if (widthPassport >= format.width) {
        mainWidthPassport = format.width;
        mainHeightPassport = mainWidthPassport * (1 / passportRatioWH);
      } else {
        mainWidthPassport = widthPassport;
        mainHeightPassport = heightPassport;
      }
    } else if (passportRatioWH < 1) {
      if (heightPassport >= format.height) {
        mainHeightPassport = format.height;
        mainWidthPassport = mainHeightPassport * passportRatioWH;
      } else {
        mainWidthPassport = widthPassport;
        mainHeightPassport = heightPassport;
      }
    } else {
      if (heightPassport >= format.height) {
        mainHeightPassport = mainWidthPassport = format.height;
      } else {
        mainHeightPassport = mainWidthPassport = widthPassport;
      }
    }
  }
  return Size(mainWidthPassport - 3, mainHeightPassport - 3);
  // cat bot phan ria cua anh de cho anh khong bi vuot qua khung hien thi cua pdf
}

///
/// [isKeepSizeWhenSmall]
///
/// : = true -> giữ nguyên kích thước [insideSize] mà không scale lên
///
/// : = false -> scale kích thước [insideSize] theo [aroundSize] nhưng vẫn giữ tỉ lệ
///
Size getLimitImageInPaper(
  Size aroundSize,
  Size insideSize, {
  bool isKeepSizeWhenSmall = true,
}) {
  double scaleFactor = _getScaleFactor(aroundSize, insideSize);
  if (isKeepSizeWhenSmall) {
    if (scaleFactor >= 1) {
      return insideSize;
    }
  }
  return Size(
    insideSize.width * scaleFactor,
    insideSize.height * scaleFactor,
  );
}

double _getScaleFactor(Size paperSize, Size imageSize) {
  double scaleWidth = paperSize.width / imageSize.width;
  double scaleHeight = paperSize.height / imageSize.height;
  return min(scaleWidth, scaleHeight);
}
