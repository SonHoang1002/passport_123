import 'dart:math' as math;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pass1_/commons/extension.dart';

class RotateHelper {
  /// Limit surrounding của image vs crop ->
  static Rect limitOuterOctagonToIncludeInnerOctagon({
    required Rect outerRect,
    required Rect innerRect,
    required double angleByRadian,
  }) {
    final Offset center = outerRect.center;

    final List<Offset> outerCorners = [
      outerRect.topLeft,
      outerRect.topRight,
      outerRect.bottomRight,
      outerRect.bottomLeft,
    ];

    List<Offset> rotatedCorners = outerCorners.map((p) {
      return _rotatePoint(p, center, angleByRadian);
    }).toList();

    double minX = rotatedCorners
        .map((p) => p.dx)
        .reduce((a, b) => a < b ? a : b);
    double maxX = rotatedCorners
        .map((p) => p.dx)
        .reduce((a, b) => a > b ? a : b);
    double minY = rotatedCorners
        .map((p) => p.dy)
        .reduce((a, b) => a < b ? a : b);
    double maxY = rotatedCorners
        .map((p) => p.dy)
        .reduce((a, b) => a > b ? a : b);

    Rect outerAABB = Rect.fromLTRB(minX, minY, maxX, maxY);

    // --- 4. Tính vector dịch để AABB phải chứa innerRect
    double dx = 0;
    double dy = 0;

    if (innerRect.left < outerAABB.left) {
      dx = innerRect.left - outerAABB.left;
    } else if (innerRect.right > outerAABB.right) {
      dx = innerRect.right - outerAABB.right;
    }

    if (innerRect.top < outerAABB.top) {
      dy = innerRect.top - outerAABB.top;
    } else if (innerRect.bottom > outerAABB.bottom) {
      dy = innerRect.bottom - outerAABB.bottom;
    }

    // --- 5. Trả lại outerRect đã dịch
    return outerRect.shift(Offset(dx, dy));
  }

  /// Rotate helper
  static Offset _rotatePoint(Offset p, Offset center, double angle) {
    final double s = math.sin(angle);
    final double c = math.cos(angle);

    final double dx = p.dx - center.dx;
    final double dy = p.dy - center.dy;

    final double x = dx * c - dy * s;
    final double y = dx * s + dy * c;

    return Offset(x + center.dx, y + center.dy);
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

  static bool isRotatedSeftOctagonContains({
    required Rect innerRect,
    required Rect outerRect,
    required double angleByRadianForOuter,
  }) {
    Map<String, Offset> listRotatePoint = getRotatedRectCorners(
      outerRect,
      angleByRadianForOuter,
    );
    return innerRect.topLeft.isContainedPointIn4Points(listRotatePoint) &&
        innerRect.bottomRight.isContainedPointIn4Points(listRotatePoint);
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
}

class RotatedCropHelpers {
  /// Limit sao cho khoảng
  /// Tính hình chiếu của điểm top right (o): A xuống cạnh top (r) -> H
  /// Nối điểm A với hình chiếu H, tìm giao điểm của đường thẳng nối hai điểm này với cạnh top (r) của image (r): H'
  ///
  /// Kiểm tra xem khoảng cách HH' có lớn hơn hoặc bằng AH -> OK
  /// Nếu không thì lấy điểm H

  /// Tương tự với điểm top left
  static Rect limitOuterOctagonToIncludeInnerOctagon({
    required Rect outerRect,
    required Rect innerRect,
    required double angleByRadian,
  }) {
    Map<String, Offset> listRotatedInnerPoint =
        RotateHelper.getRotatedRectCorners(innerRect, angleByRadian);

    Map<String, Offset> listRotatedOuterPoint =
        RotateHelper.getRotatedRectCorners(outerRect, angleByRadian);

    Offset innerRotatedTopLeft = listRotatedInnerPoint["topLeft"]!;
    Offset innerRotatedTopRight = listRotatedInnerPoint["topRight"]!;
    Offset innerRotatedBottomLeft = listRotatedInnerPoint["bottomLeft"]!;
    Offset innerRotatedBottomRight = listRotatedInnerPoint["bottomRight"]!;

    Offset outerRotatedTopLeft = listRotatedOuterPoint["topLeft"]!;
    Offset outerRotatedTopRight = listRotatedOuterPoint["topRight"]!;
    Offset outerRotatedBottomLeft = listRotatedOuterPoint["bottomLeft"]!;
    Offset outerRotatedBottomRight = listRotatedOuterPoint["bottomRight"]!;

    ///
    /// ------------------ KIỂM TRA CẠNH OUTER ROTATED TOP EDGE -------------------
    ///

    /// Tìm hình chiếu của điểm top right (o) xuống cạnh top (r) của crop rect: H
    Offset projectionInnerOriginTopRightToInnerRotatedTopEdge = innerRect
        .topRight
        .getProjectionWith(innerRotatedTopRight, innerRotatedTopLeft);

    /// Tìm giao điểm của đường nối top right (o) của crop rect và điểm projectionInnerOriginTopRightToInnerRotatedTopEdge
    /// với cạnh top (r) của image : H'
    Offset overlapInnerTopRightProjectionToOuterRotatedTopEdge =
        getOverlapPointBetween(
          begin1: innerRect.topRight,
          end1: projectionInnerOriginTopRightToInnerRotatedTopEdge,
          begin2: outerRotatedTopLeft,
          end2: outerRotatedTopRight,
        );

    /// Kiểm tra phía: Nếu điểm top right (o) và điểm H' nằm cùng phía so với điểm hình chiếu H
    /// + Nếu cùng phía và khoảng cách giao điểm đến
    ///   hình chiếu lớn hơn khoảng cách điểm
    ///   top right và hình chiếu -> OK
    /// + Nếu ko   -> Lấy điểm H, kéo image 1 đoạn HH'
    Offset targetOuterRotatedTopEdge;
    bool isSameSideTopRight = isSameSide(
      pivot: projectionInnerOriginTopRightToInnerRotatedTopEdge,
      check1: innerRect.topRight,
      check2: overlapInnerTopRightProjectionToOuterRotatedTopEdge,
    );
    // nằm khác phía hoặc cùng phía nhưng ko thoả mãn điều kiện khoảng cách
    bool isValidDistanceTopRight =
        projectionInnerOriginTopRightToInnerRotatedTopEdge.distanceWith(
          overlapInnerTopRightProjectionToOuterRotatedTopEdge,
        ) >=
        projectionInnerOriginTopRightToInnerRotatedTopEdge.distanceWith(
          innerRect.topRight,
        );
    if (!isSameSideTopRight ||
        (isSameSideTopRight && !isValidDistanceTopRight)) {
      targetOuterRotatedTopEdge = innerRect.topRight;
    } else {
      targetOuterRotatedTopEdge =
          overlapInnerTopRightProjectionToOuterRotatedTopEdge;
    }

    ///
    /// ------------------ KIỂM TRA CẠNH OUTER ROTATED LEFT EDGE -------------------
    ///

    /// Tìm hình chiếu của điểm top left (o) xuống cạnh left (r) của crop rect
    Offset projectionInnerOriginTopLeftToInnerRotatedLeftEdge = innerRect
        .topLeft
        .getProjectionWith(innerRotatedTopLeft, innerRotatedBottomLeft);

    Offset overlapInnerTopLeftProjectionToOuterRotatedLeftEdge =
        getOverlapPointBetween(
          begin1: innerRect.topLeft,
          end1: projectionInnerOriginTopLeftToInnerRotatedLeftEdge,
          begin2: outerRotatedTopLeft,
          end2: outerRotatedBottomLeft,
        );

    Offset targetOuterRotatedLeftEdge;
    bool isSameSideTopLeft = isSameSide(
      pivot: projectionInnerOriginTopLeftToInnerRotatedLeftEdge,
      check1: innerRect.topLeft,
      check2: overlapInnerTopLeftProjectionToOuterRotatedLeftEdge,
    );

    bool isValidDistanceTopLeft =
        projectionInnerOriginTopLeftToInnerRotatedLeftEdge.distanceWith(
          overlapInnerTopLeftProjectionToOuterRotatedLeftEdge,
        ) >=
        projectionInnerOriginTopLeftToInnerRotatedLeftEdge.distanceWith(
          innerRect.topLeft,
        );

    if (!isSameSideTopLeft || (isSameSideTopLeft && !isValidDistanceTopLeft)) {
      targetOuterRotatedLeftEdge = innerRect.topLeft;
    } else {
      targetOuterRotatedLeftEdge =
          overlapInnerTopLeftProjectionToOuterRotatedLeftEdge;
    }

    // if (!targetOuterRotatedLeftEdge.dy.equalTo(targetOuterRotatedTopEdge.dy)) {
    //   throw Exception(
    //       "Tính toán đang bị sai targetOuterRotatedLeftEdge = $targetOuterRotatedLeftEdge, targetOuterRotatedTopEdge = $targetOuterRotatedTopEdge, listRotatedInnerPoint = ${listRotatedInnerPoint}, listRotatedOuterPoint = ${listRotatedOuterPoint}");
    // }

    /// Sua khi tính được hai điểm đã limit
    /// Đã biết góc alpha ( angleByRadian ) chính là góc giữa điểm top left (r) của outer và điểm targetOuterRotatedTopEdge
    /// Tính lại điểm top left (o)
    Offset newTargetOuterRotatedTopLeft = getRotatePointWith(
      point1: targetOuterRotatedLeftEdge,
      point2: targetOuterRotatedTopEdge,
      angleByRadianWithPoint2: angleByRadian,
    );
    Offset translatedForOuterRotatedTopLeft =
        newTargetOuterRotatedTopLeft - outerRotatedTopLeft;

    Offset newCenterOuter = outerRect.center.translate(
      translatedForOuterRotatedTopLeft.dx,
      translatedForOuterRotatedTopLeft.dy,
    );

    return Rect.fromCenter(
      center: newCenterOuter,
      width: outerRect.width,
      height: outerRect.height,
    );
  }

  /// Tính điểm sao cho điểm [targetPoint] kết hợp với điểm [point2] tạo góc [angleByRadianWithPoint2] với cạnh tạo bởi [point1] và [point2]
  /// Tính điểm X sao cho:
  /// - X kết hợp với point2 tạo góc `angleByRadianWithPoint2`
  /// - với cạnh tạo bởi (point1 → point2)
  ///
  /// Nói cách khác: xoay vector (point1 - point2) quanh point2
  /// một góc angleByRadianWithPoint2
  ///
  /// CHÚ Ý: Góc tại target point là góc 90 độ
  static Offset getRotatePointWith({
    required Offset point1,
    required Offset point2,
    required double angleByRadianWithPoint2,
  }) {
    // Vector point2 → point1
    final double dx = point1.dx - point2.dx;
    final double dy = point1.dy - point2.dy;

    // Độ lớn vector (để giữ nguyên khoảng cách)
    final double length = math.sqrt(dx * dx + dy * dy);

    // Nếu góc yêu cầu là 90°, ta cần xoay vector sao cho:
    // (point2 -> targetPoint) ⟂ (point2 -> point1)
    if (angleByRadianWithPoint2.abs().toStringAsFixed(6) ==
        (math.pi / 2).toStringAsFixed(6)) {
      // Hai vector vuông góc: (dx, dy) ⟂ (vx, vy) → vx = -dy, vy = dx hoặc vx = dy, vy = -dx

      // Vector vuông góc chuẩn hóa
      final bool useLeftNormal = true; // có thể truyền vào nếu muốn chọn hướng

      final Offset normal = useLeftNormal
          ? Offset(-dy, dx) // xoay trái
          : Offset(dy, -dx); // xoay phải

      // Chuẩn hóa
      final double nLen = normal.distance;
      final Offset unitNormal = normal / nLen;

      // Target point
      return point2 + unitNormal * length;
    }

    // THƯỜNG: xoay theo góc angleByRadianWithPoint2
    final double cosA = math.cos(angleByRadianWithPoint2);
    final double sinA = math.sin(angleByRadianWithPoint2);

    final double rotatedDx = dx * cosA - dy * sinA;
    final double rotatedDy = dx * sinA + dy * cosA;

    return Offset(point2.dx + rotatedDx, point2.dy + rotatedDy);
  }

  static Offset getRotatePointWithV1({
    required Offset point1,
    required Offset point2,
    required double angleByRadianWithPoint2,
  }) {
    final double dx = point1.dx - point2.dx;
    final double dy = point1.dy - point2.dy;

    // Độ lớn vector (để giữ nguyên khoảng cách)
    final double length = math.sqrt(dx * dx + dy * dy);

    // Nếu góc yêu cầu là 90°, ta cần xoay vector sao cho:
    // (point2 -> targetPoint) ⟂ (point2 -> point1)
    if (angleByRadianWithPoint2.abs().toStringAsFixed(6) ==
        (math.pi / 2).toStringAsFixed(6)) {
      // Hai vector vuông góc: (dx, dy) ⟂ (vx, vy) → vx = -dy, vy = dx hoặc vx = dy, vy = -dx

      // Vector vuông góc chuẩn hóa
      final bool useLeftNormal = true; // có thể truyền vào nếu muốn chọn hướng

      final Offset normal = useLeftNormal
          ? Offset(-dy, dx) // xoay trái
          : Offset(dy, -dx); // xoay phải

      // Chuẩn hóa
      final double nLen = normal.distance;
      final Offset unitNormal = normal / nLen;

      // Target point
      return point2 + unitNormal * length;
    }

    // THƯỜNG: xoay theo góc angleByRadianWithPoint2
    final double cosA = math.cos(angleByRadianWithPoint2);
    final double sinA = math.sin(angleByRadianWithPoint2);

    final double rotatedDx = dx * cosA - dy * sinA;
    final double rotatedDy = dx * sinA + dy * cosA;

    return Offset(point2.dx + rotatedDx, point2.dy + rotatedDy);
  }

  /// Kiểm tra xem check1 và check2 có nằm cùng phía so với pivot hay không
  static bool isSameSide({
    required Offset pivot,
    required Offset check1,
    required Offset check2,
  }) {
    // Vector chỉ phương từ pivot đến check1
    final v = check1 - pivot;

    // Vector từ pivot đến từng điểm cần kiểm tra
    final v1 = check1 - pivot;
    final v2 = check2 - pivot;

    // Tính tích vô hướng
    final dot1 = v.dx * v1.dx + v.dy * v1.dy;
    final dot2 = v.dx * v2.dx + v.dy * v2.dy;

    // Nếu tích vô hướng cùng dấu → cùng phía
    return dot1 * dot2 >= 0;
  }

  /// Tìm giao điểm của hai ĐƯỜNG THẲNG
  /// (không giới hạn trong đoạn thẳng)
  ///
  /// Trả về:
  /// - Offset: giao điểm duy nhất
  /// - throw Exception nếu: song song không giao, hoặc cả hai đều suy biến
  static Offset getOverlapPointBetween({
    required Offset begin1,
    required Offset end1,
    required Offset begin2,
    required Offset end2,
  }) {
    // 1. Trường hợp đường thẳng suy biến thành điểm
    if (begin1 == end1 && begin2 == end2) {
      if (begin1 == begin2) return begin1;
      throw Exception("Hai đường đều là điểm nhưng khác nhau");
    }

    // Nếu line1 là điểm ⇒ chỉ cần kiểm tra line2 có đi qua điểm đó hay không
    if (begin1 == end1) {
      if (_isPointOnInfiniteLine(begin1, begin2, end2)) {
        return begin1;
      } else {
        throw Exception("Line1 là điểm nhưng điểm này không nằm trên line2");
      }
    }

    // Nếu line2 là điểm ⇒ tương tự
    if (begin2 == end2) {
      if (_isPointOnInfiniteLine(begin2, begin1, end1)) {
        return begin2;
      } else {
        throw Exception("Line2 là điểm nhưng điểm này không nằm trên line1");
      }
    }

    // 2. Tính vector
    final double dx1 = end1.dx - begin1.dx;
    final double dy1 = end1.dy - begin1.dy;
    final double dx2 = end2.dx - begin2.dx;
    final double dy2 = end2.dy - begin2.dy;

    // Định thức
    final double det = dx1 * dy2 - dy1 * dx2;

    if (det.abs() < 1e-12) {
      // Song song → kiểm tra trùng nhau
      bool isCollinear = _areLinesCollinear(begin1, end1, begin2, end2);
      if (isCollinear) {
        throw Exception("Hai đường thẳng trùng nhau (vô số giao điểm)");
      }
      throw Exception("Hai đường thẳng song song (không giao nhau)");
    }

    // 3. Tính tham số t để tìm giao điểm line1
    final double t =
        ((begin2.dx - begin1.dx) * dy2 - (begin2.dy - begin1.dy) * dx2) / det;

    // Giao điểm của hai đường thẳng VÔ HẠN
    return Offset(begin1.dx + t * dx1, begin1.dy + t * dy1);
  }

  /// Kiểm tra điểm có nằm trên đường thẳng vô hạn hay không
  static bool _isPointOnInfiniteLine(Offset p, Offset a, Offset b) {
    final double cross =
        (p.dy - a.dy) * (b.dx - a.dx) - (p.dx - a.dx) * (b.dy - a.dy);
    return cross.abs() < 1e-10;
  }

  /// Kiểm tra hai đường thẳng có cùng phương và thẳng hàng
  static bool _areLinesCollinear(Offset p1, Offset p2, Offset p3, Offset p4) {
    final double cross1 =
        (p2.dy - p1.dy) * (p3.dx - p1.dx) - (p2.dx - p1.dx) * (p3.dy - p1.dy);
    final double cross2 =
        (p2.dy - p1.dy) * (p4.dx - p1.dx) - (p2.dx - p1.dx) * (p4.dy - p1.dy);
    return cross1.abs() < 1e-10 && cross2.abs() < 1e-10;
  }
}
