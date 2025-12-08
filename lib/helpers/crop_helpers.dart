import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pass1_/commons/extension.dart';
import 'package:pass1_/helpers/log_custom.dart';

class CropHelpers {
  static double limitAngleRadian(double angleByRadian) {
    double newAngleByDegree = angleByRadian.toDegreeFromRadian;

    newAngleByDegree = (newAngleByDegree % 360.0);

    // Xử lý góc âm
    // Handle negative angles
    if (newAngleByDegree < 0.0) {
      newAngleByDegree += 360.0;
    }

    double targetAngle1 = newAngleByDegree.toRadianFromDegree;
    return targetAngle1;
  }

  static double limitAngleDegree(double angleByDegree) {
    double newAngleByDegree = (angleByDegree % 360.0);
    // Handle negative angles
    if (newAngleByDegree < 0.0) {
      newAngleByDegree += 360.0;
    }
    return newAngleByDegree;
  }

  static Rect limitOuterOctagonToIncludeInnerOctagon({
    required Rect outerRect,
    required Rect innerRect,
    required double angleByRadian,
  }) {
    /// Lấy danh sách điểm đã xoay của image theo center của outer
    Offset outerCenterInInnerCoord = getRotatedPointByAngle(
      innerRect.center,
      outerRect.center,
      -angleByRadian,
    );

    /// Tính toán rect outer tại hệ quy chiếu inner
    Rect transverseOuterRectInInnerCoord = Rect.fromCenter(
      center: outerCenterInInnerCoord,
      width: outerRect.width,
      height: outerRect.height,
    );
    // Lấy rect bao quanh của inner
    Rect surroundingRotatedCropRect = getRotatedRect(innerRect, angleByRadian);

    /// limit
    Rect limitTransverseOuterRectInInnerCoord = transverseOuterRectInInnerCoord
        .limitSelfToInclude(surroundingRotatedCropRect);

    Offset newCenterOuter = getRotatedPointByAngle(
      innerRect.center,
      limitTransverseOuterRectInInnerCoord.center,
      angleByRadian,
    );

    return Rect.fromCenter(
      center: newCenterOuter,
      width: outerRect.width,
      height: outerRect.height,
    );
  }

  static Size getTargetMaxScaleSizeToOuterContainRotatedInner({
    required Rect outerRect,
    required Rect innerRect,
    required double angleByRadian,
  }) {
    Offset outerCenterInInnerCoord = getRotatedPointByAngle(
      innerRect.center,
      outerRect.center,
      -angleByRadian,
    );
    Rect transverseOuterRectInInnerCoord = Rect.fromCenter(
      center: outerCenterInInnerCoord,
      width: outerRect.width,
      height: outerRect.height,
    );
    Rect surroundingRotatedCropRect = getRotatedRect(innerRect, angleByRadian);

    double translateTopEdge =
        transverseOuterRectInInnerCoord.top -
        surroundingRotatedCropRect.top; // outer nằm trong thì > 0
    double translateLeftEdge =
        transverseOuterRectInInnerCoord.left -
        surroundingRotatedCropRect.left; // outer nằm trong thì > 0
    double translateRightEdge =
        -(transverseOuterRectInInnerCoord.right -
            surroundingRotatedCropRect.right); // outer nằm trong thì > 0
    double translateBottomEdge =
        -(transverseOuterRectInInnerCoord.bottom -
            surroundingRotatedCropRect.bottom); // outer nằm trong thì > 0

    List<double> listTranslate = [
      translateLeftEdge,
      translateTopEdge,
      translateRightEdge,
      translateBottomEdge,
    ];

    /// Lấy khoảng cách lớn giữa hai rect bên trên
    double maxTranslate = 0;
    int indexOfEdgeHasMaxDistance = -1;

    for (var i = 0; i < listTranslate.length; i++) {
      double item = listTranslate[i];
      if (item > 0 && item > maxTranslate) {
        indexOfEdgeHasMaxDistance = i;
        maxTranslate = item;
      }
    }
    double ratio = outerRect.size.aspectRatio;
    double targetWidth, targetHeight;
    switch (indexOfEdgeHasMaxDistance) {
      case 0:
        // Tỉ lệ từ cạnh left của crop rect đến cạnh left của outer rect
        double distanceCropCenterToTransverseOuterLeftEdge =
            (surroundingRotatedCropRect.center.dx -
            transverseOuterRectInInnerCoord.left);

        /// Ở phía từ center của crop đến cạnh left của outer, tính khoảng cách mới
        double distanceWidthCenterInnerRectToNewRotatedOuterLeftEdge =
            maxTranslate + distanceCropCenterToTransverseOuterLeftEdge;

        /// Theo công thức: dLeftNew / dLeftOld = đRightNew / dRightOld; -> tính dRightNew
        double distanceWidthCenterInnerRectToNewRotatedOuterRightEdge =
            distanceWidthCenterInnerRectToNewRotatedOuterLeftEdge /
            distanceCropCenterToTransverseOuterLeftEdge *
            (transverseOuterRectInInnerCoord.width -
                distanceCropCenterToTransverseOuterLeftEdge);

        targetWidth =
            distanceWidthCenterInnerRectToNewRotatedOuterRightEdge +
            distanceWidthCenterInnerRectToNewRotatedOuterLeftEdge;
        targetHeight = targetWidth / ratio;

        break;
      case 1:
        // Tỉ lệ từ cạnh top của crop rect đến cạnh top của outer rect
        double distanceCropCenterToTransverseOuterTopEdge =
            (surroundingRotatedCropRect.center.dy -
            transverseOuterRectInInnerCoord.top);

        /// Ở phía từ center của crop đến cạnh top của outer, tính khoảng cách mới
        double distanceWidthCenterInnerRectToNewRotatedOuterTopEdge =
            maxTranslate + distanceCropCenterToTransverseOuterTopEdge;

        /// Theo công thức: dTopNew / dTopOld = dBottomNew / dBottomOld; -> tính dBottomNew
        double distanceWidthCenterInnerRectToNewRotatedOuterBottomEdge =
            distanceWidthCenterInnerRectToNewRotatedOuterTopEdge /
            distanceCropCenterToTransverseOuterTopEdge *
            (transverseOuterRectInInnerCoord.height -
                distanceCropCenterToTransverseOuterTopEdge);

        targetHeight =
            distanceWidthCenterInnerRectToNewRotatedOuterBottomEdge +
            distanceWidthCenterInnerRectToNewRotatedOuterTopEdge;
        targetWidth = targetHeight * ratio;
        break;
      case 2:
        // Tỉ lệ từ cạnh left của crop rect đến cạnh right của outer rect
        double distanceCropCenterToTransverseOuterRightEdge =
            transverseOuterRectInInnerCoord.width -
            (surroundingRotatedCropRect.center.dx -
                transverseOuterRectInInnerCoord.left);

        /// Ở phía từ center của crop đến cạnh right của outer, tính khoảng cách mới
        double distanceWidthCenterInnerRectToNewRotatedOuterRightEdge =
            maxTranslate + distanceCropCenterToTransverseOuterRightEdge;

        /// Theo công thức: dLeftNew / dLeftOld = đRightNew / dRightOld; -> tính dRightNew
        double distanceWidthCenterInnerRectToNewRotatedOuterLeftEdge =
            distanceWidthCenterInnerRectToNewRotatedOuterRightEdge /
            distanceCropCenterToTransverseOuterRightEdge *
            (transverseOuterRectInInnerCoord.width -
                distanceCropCenterToTransverseOuterRightEdge);

        targetWidth =
            distanceWidthCenterInnerRectToNewRotatedOuterRightEdge +
            distanceWidthCenterInnerRectToNewRotatedOuterLeftEdge;
        targetHeight = targetWidth / ratio;
        break;
      case 3:
        // Tỉ lệ từ cạnh top của crop rect đến cạnh bottom của outer rect
        double distanceCropCenterToTransverseOuterBottomEdge =
            transverseOuterRectInInnerCoord.height -
            (surroundingRotatedCropRect.center.dy -
                transverseOuterRectInInnerCoord.top);

        /// Ở phía từ center của crop đến cạnh top của outer, tính khoảng cách mới
        double distanceWidthCenterInnerRectToNewRotatedOuterBottomEdge =
            maxTranslate + distanceCropCenterToTransverseOuterBottomEdge;

        /// Theo công thức: dTopNew / dTopOld = dBottomNew / dBottomOld; -> tính dTopNew
        double distanceWidthCenterInnerRectToNewRotatedOuterTopEdge =
            distanceWidthCenterInnerRectToNewRotatedOuterBottomEdge /
            distanceCropCenterToTransverseOuterBottomEdge *
            (transverseOuterRectInInnerCoord.height -
                distanceCropCenterToTransverseOuterBottomEdge);

        targetHeight =
            distanceWidthCenterInnerRectToNewRotatedOuterBottomEdge +
            distanceWidthCenterInnerRectToNewRotatedOuterTopEdge;
        targetWidth = targetHeight * ratio;
        break;
      default:
        targetHeight = outerRect.height;
        targetWidth = outerRect.width;
        break;
    }
    // if ([0, 2].contains(indexOfEdgeHasMaxDistance)) {
    //   targetWidth = outerRect.width + maxTranslate * 2;
    //   targetHeight = targetWidth / ratio;
    // } else if ([1, 3].contains(indexOfEdgeHasMaxDistance)) {
    //   targetHeight = outerRect.height + maxTranslate * 2;
    //   targetWidth = targetHeight * ratio;
    // } else {
    // targetHeight = outerRect.height;
    // targetWidth = outerRect.width;
    // }
    Size targetSize = Size(targetWidth, targetHeight);
    consolelog(
      "indexOfEdgeHasMaxDistance = $indexOfEdgeHasMaxDistance, distance: ${listTranslate}, outerRect size = ${outerRect.size}, targetSize = $targetSize",
    );
    return targetSize;
  }

  static Offset getRotatedPointByAngle(
    Offset center,
    Offset originPoint,
    double angleByRadian,
  ) {
    final transform = Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1.0)
      ..rotateZ(angleByRadian)
      ..translateByDouble(-center.dx, -center.dy, 0, 1.0);
    final rotatedPoint = MatrixUtils.transformPoint(transform, originPoint);
    return rotatedPoint;
  }

  /// Return Surrounding rotated rect from 0 to [angle] and [originalRect]
  ///
  /// NOTE: Transform from center point
  static Rect getRotatedRect(
    Rect originalRect,
    double angle, {
    Offset? pivotPoint,
  }) {
    final pivot = pivotPoint ?? originalRect.center;

    final transform = Matrix4.identity()
      ..translateByDouble(pivot.dx, pivot.dy, 0, 1.0)
      ..rotateZ(angle) // by radian
      ..translateByDouble(-pivot.dx, -pivot.dy, 0, 1.0);

    // transform for edges
    final topLeft = MatrixUtils.transformPoint(transform, originalRect.topLeft);
    final topRight = MatrixUtils.transformPoint(
      transform,
      originalRect.topRight,
    );
    final bottomLeft = MatrixUtils.transformPoint(
      transform,
      originalRect.bottomLeft,
    );
    final bottomRight = MatrixUtils.transformPoint(
      transform,
      originalRect.bottomRight,
    );

    // get surrounding rect of transformed above points
    final left = math.min(
      math.min(topLeft.dx, topRight.dx),
      math.min(bottomLeft.dx, bottomRight.dx),
    );
    final top = math.min(
      math.min(topLeft.dy, topRight.dy),
      math.min(bottomLeft.dy, bottomRight.dy),
    );
    final right = math.max(
      math.max(topLeft.dx, topRight.dx),
      math.max(bottomLeft.dx, bottomRight.dx),
    );
    final bottom = math.max(
      math.max(topLeft.dy, topRight.dy),
      math.max(bottomLeft.dy, bottomRight.dy),
    );

    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// Tính 4 điểm góc của rect sau khi xoay
  ///
  /// * {
  /// *  'topLeft': ...,
  /// *  'topRight': ...,
  /// *  'bottomRight': ...,
  /// *  'bottomLeft': ...,
  /// *  'center': ...,
  /// * }
  static Map<String, Offset> getRotatedRectCorners(
    Rect rect,
    double angleByRadian, {
    Offset? pivotPoint,
  }) {
    final pivot = pivotPoint ?? rect.center;

    // Lấy 4 điểm góc ban đầu
    final topLeft = rect.topLeft;
    final topRight = rect.topRight;
    final bottomLeft = rect.bottomLeft;
    final bottomRight = rect.bottomRight;
    final center = rect.center;

    // Xoay từng điểm
    return {
      'topLeft': _rotatePointAroundPivot(topLeft, pivot, angleByRadian),
      'topRight': _rotatePointAroundPivot(topRight, pivot, angleByRadian),
      'bottomRight': _rotatePointAroundPivot(bottomRight, pivot, angleByRadian),
      'bottomLeft': _rotatePointAroundPivot(bottomLeft, pivot, angleByRadian),
      'center': _rotatePointAroundPivot(center, pivot, angleByRadian),
    };
  }

  // Xoay một điểm quanh pivot point
  static Offset _rotatePointAroundPivot(
    Offset point,
    Offset pivot,
    double angle,
  ) {
    // Dịch chuyển về hệ tọa độ với pivot là gốc
    final translatedPoint = point - pivot;

    // Xoay điểm
    final rotatedPoint = rotatePoint(translatedPoint, angle);

    // Dịch chuyển ngược về hệ tọa độ gốc
    return rotatedPoint + pivot;
  } // Xoay điểm quanh gốc tọa độ (0,0)

  static Offset rotatePoint(Offset point, double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Offset(
      point.dx * cos - point.dy * sin,
      point.dx * sin + point.dy * cos,
    );
  }

  static Size limitScaleSize({
    required double angleByRadian,
    required Rect innerRect,
    required Size outerSize,
  }) {
    Rect surroundingRotatedCropRect = getRotatedRect(innerRect, angleByRadian);

    if (surroundingRotatedCropRect.size < outerSize) {
      return outerSize;
    }

    /// Giới hạn sao cho giữ nguyên ratio của outerSize
    ///
    /// Đảm bảo kích thước outerSize không được nhỏ

    double ratioOuter = outerSize.aspectRatio;
    double ratioSurroundingInnerRect =
        surroundingRotatedCropRect.size.aspectRatio;
    double targetOuterWidth, targetOuterHeight;
    if (ratioOuter < ratioSurroundingInnerRect) {
      targetOuterWidth = surroundingRotatedCropRect.width;
      targetOuterHeight = targetOuterWidth / ratioOuter;
    } else {
      targetOuterHeight = surroundingRotatedCropRect.height;
      targetOuterWidth = targetOuterHeight * ratioOuter;
    }
    return Size(targetOuterWidth, targetOuterHeight);
  }
}
