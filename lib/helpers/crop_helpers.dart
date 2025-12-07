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

  static double getTargetMaxScaleSizeToOuterContainRotatedInner({
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
        maxTranslate = item;
        indexOfEdgeHasMaxDistance = i;x
      }
    }
    double targetScale = 1;
    if (indexOfEdgeHasMaxDistance == 0 || indexOfEdgeHasMaxDistance == 2) {
      targetScale = (outerRect.width + maxTranslate * 2) / outerRect.width;
    }
    if (indexOfEdgeHasMaxDistance == 1 || indexOfEdgeHasMaxDistance == 3) {
      targetScale = (outerRect.height + maxTranslate * 2) / outerRect.height;
    }
    consolelog(
      "indexOfEdgeHasMaxDistance = $indexOfEdgeHasMaxDistance, targetScale = $targetScale",
    );

    return targetScale;
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
