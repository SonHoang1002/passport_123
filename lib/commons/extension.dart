import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pass1_/commons/constants.dart';

extension NumberExtension on num {
  Duration get um => Duration(microseconds: round());

  Duration get ms => (this * 1000).um;

  Duration get seconds => (this * 1000 * 1000).um;

  Duration get minutes => (this * 1000 * 1000 * 60).um;

  Duration get hours => (this * 1000 * 1000 * 60 * 60).um;

  Duration get days => (this * 1000 * 1000 * 60 * 60 * 24).um;
}

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

  /// So sánh hai số thực với sai số tương đối & tuyệt đối.
  ///
  /// [epsilon] là sai số nhỏ nhất chấp nhận được (mặc định [EPSILON_E5])
  /// Có thể dùng an toàn cho cả số học và hình học.
  bool equalTo(double other, {double epsilon = EPSILON_E5}) {
    final diff = (this - other).abs();
    return diff.abs() <= epsilon;
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

  double scaleWith(Size other) {
    return math.max(width / other.width, height / other.height);
  }
}

extension OffsetExtension on Offset {
  Offset getProjectionWith(Offset target1, Offset target2) {
    Offset start = this;
    // Vector chỉ phương của đường thẳng
    final dx = target2.dx - target1.dx;
    final dy = target2.dy - target1.dy;

    // Nếu 2 điểm trùng nhau → không xác định đường thẳng
    final lenSq = dx * dx + dy * dy;
    if (lenSq == 0) return target1;

    // Vector từ target1 → start
    final vx = start.dx - target1.dx;
    final vy = start.dy - target1.dy;

    // Hệ số t trong công thức projection
    final t = (vx * dx + vy * dy) / lenSq;

    // Tính điểm chiếu
    return Offset(target1.dx + t * dx, target1.dy + t * dy);
  }

  /// Expand to rect from current offset
  /// ( center is current offset ) with width = [distance] * 2, height = [distance] * 2
  Rect expandedRectFromOffset(double distance) {
    Offset newTopLeft = translate(-distance, -distance);
    Offset newBottomRight = translate(distance, distance);
    return Rect.fromPoints(newTopLeft, newBottomRight);
  }

  /// Tạo ra rect hình vuông với chiều dài là [radius] * 2
  Rect expandedRectFromOffsetCircle(double radius) {
    return Rect.fromCircle(center: this, radius: radius);
  }

  /// Tạo ra list [this.dx, this.dy]
  List<double> get toList {
    return [dx, dy];
  }

  bool equalTo(Offset other, {double epsilon = EPSILON_E5}) {
    return (dx - other.dx).abs() <= epsilon && (dy - other.dy).abs() <= epsilon;
  }

  /// Lấy trung điểm giữa đạon thẳng tạo bởi 2 điểm
  Offset midPointWith(Offset other) {
    return Offset((dx + other.dx) / 2, (dy + other.dy) / 2);
  }

  Offset get normalized {
    final length = distance;
    if (length == 0) return Offset.zero;
    return Offset(dx / length, dy / length);
  }

  /// Lấy điểm hình chiếu của điểm [this] xuống đường thẳng tạo bởi 2 điểm
  /// * [clampToSegment]: Có muốn điểm hình chiếu này nằm bên trong đoạn thẳng tạo bởi hai điểm
  Offset getProjectionPointFrom(
    Offset A,
    Offset B, {
    bool clampToSegment = true,
  }) {
    if (A.equalTo(B)) {
      throw Exception("A == B");
    }

    /// Cho 3 điểm không trùng nhau  P, A, B,
    /// H là hình chiếu của P lên AB, tìm H
    ///
    /// Sử dụng công thức: vector(AH) = t * vector(AB)
    /// vector(AB) = B-A;
    /// vector(AP) = P-A;
    ///
    /// t = vector(AH) * vector(AB)/ (|vector(AB)|^2)
    ///
    /// H = A + t * vector(AB)
    ///
    /// ( muốn H nằm trong AB thì t thuộc [0,1], ngược lại sẽ năm bên ngoài )

    Offset vectorAB = B - A;
    Offset vectorAP = this - A;

    double t =
        (vectorAB.dx * vectorAP.dx + vectorAB.dy * vectorAP.dy) /
        (vectorAB.dx * vectorAB.dx + vectorAB.dy * vectorAB.dy);
    if (clampToSegment) {
      t = t.clamp(0, 1);
    }
    Offset H = A + vectorAB * t;
    // Kiểm tra vuông góc (nếu cần)
    final vectorPH = H - this;
    final dot = vectorPH.dx * vectorAB.dx + vectorPH.dy * vectorAB.dy;
    final valid = dot.abs() < EPSILON_E5;

    if (!valid) {
      debugPrint("Warning: projection not perfectly orthogonal (dot=$dot)");
    }
    return H;
  }

  /// Lấy chiều dài của hình chiếu từ [this] đến hai điểm
  double getProjectionDistance(Offset A, Offset B) {
    if (A.equalTo(B)) {
      throw Exception("A == B");
    }

    /// Sử dụng công thức: d(P, vector(AB)) = |vector(AB) x vector(AP)|/ |vector(AB)|

    Offset vectorAB = B - A;
    Offset vectorAH = this - A;
    return (vectorAB.dx * vectorAH.dy - vectorAB.dy * vectorAH.dx).abs() /
        vectorAB.distance;
  }

  bool isContainedBy(Offset startOffset, Offset endOffset) {
    return (startOffset.dx <= dx && dx <= endOffset.dx) &&
        (startOffset.dy <= dy && dy <= endOffset.dy);
  }

  /// [listPoint] phải xếp theo thứ tự sau đây: {
  ///   "topLeft":...,
  ///   "topRight":...,
  ///   "bottomRight":...,
  ///   "bottomLeft":...,
  /// };
  ///
  /// Note: Ray Casting algorithm
  bool isContainedPointIn4Points(Map<String, Offset> listPoint) {
    Offset topLeft = listPoint["topLeft"]!;
    Offset topRight = listPoint["topRight"]!;
    Offset bottomRight = listPoint["bottomRight"]!;
    Offset bottomLeft = listPoint["bottomLeft"]!;

    List<List<Offset>> edges = [
      [topLeft, topRight],
      [topRight, bottomRight],
      [bottomRight, bottomLeft],
      [bottomLeft, topLeft],
    ];

    int intersectionCount = 0;

    // Duyệt qua từng cạnh và kiểm tra giao điểm với tia nằm ngang
    for (var edge in edges) {
      Offset a = edge[0];
      Offset b = edge[1];

      // Kiểm tra xem tia nằm ngang có cắt qua cạnh này không
      if ((a.dy > dy) != (b.dy > dy)) {
        // Tính toán giao điểm
        double intersectX = (b.dx - a.dx) * (dy - a.dy) / (b.dy - a.dy) + a.dx;

        // Nếu giao điểm nằm bên phải điểm cần kiểm tra, tăng biến đếm
        if (dx < intersectX) {
          intersectionCount++;
        }
      }
    }

    // Nếu số lần cắt là lẻ, điểm nằm trong tứ giác
    bool result = intersectionCount % 2 == 1;
    return result;
  }

  /// Kiểm tra xem [this] (P) có nằm trong đường thẳng AB,
  /// *[onlyIncludeInnerSegment]: Chỉ kiểm tra điểm có nằm trong đoạn AB hay không, [false] -> miễn là nằm trong đường thẳng
  bool isOnLineOf(
    Offset A,
    Offset B, {
    double epsilon = EPSILON_E5,
    bool onlyIncludeInnerSegment = true,
  }) {
    // Trường hợp A và B trùng nhau
    if (A.equalTo(B)) {
      return equalTo(A);
    }

    // Kiểm tra nằm trên đường thẳng: cross(AB,AP) = (B−A)×(P−A) = 0 (tích có hướng)
    final vectorAB = B - A;
    final vectorAP = this - A;

    final cross = vectorAB.dx * vectorAP.dy - vectorAB.dy * vectorAP.dx;

    // Nếu không nằm trên đường thẳng
    if (cross.abs() > epsilon) {
      return false;
    }

    // Nếu chỉ cần nằm trên đường thẳng (không cần trong đoạn AB)
    if (!onlyIncludeInnerSegment) {
      return true;
    }

    // Kiểm tra nằm trong đoạn AB: tích vô hướng và khoảng cách
    final dotABAP = vectorAB.dx * vectorAP.dx + vectorAB.dy * vectorAP.dy;
    final dotABAB = vectorAB.dx * vectorAB.dx + vectorAB.dy * vectorAB.dy;

    // Điểm P nằm trong đoạn AB nếu:
    // 1. Tích vô hướng AB·AP ≥ 0 (P không nằm sau A)
    // 2. Tích vô hướng AB·AP ≤ AB·AB (P không nằm sau B)
    // 3. Khoảng cách từ P đến A và P đến B không vượt quá độ dài AB
    return dotABAP >= -epsilon &&
        dotABAP <= dotABAB + epsilon &&
        vectorAP.distance <= vectorAB.distance + epsilon &&
        (this - B).distance <= vectorAB.distance + epsilon;
  }

  /// Với hai đoạn thẳng [start1] (this) và [end1], [start2] và [end2], trả ra giao điểm của hai đoạn thẳng này
  ///
  /// Nếu không có điểm giao hoặc điểm giao nằm bên ngoài hai đoạn thẳng thì trả về null
  Offset? getIntersectionWith(
    Offset end1,
    Offset start2,
    Offset end2, {
    double epsilon = EPSILON_E5,
  }) {
    Offset start1 = this;

    // Vector của hai đoạn thẳng
    double dx1 = end1.dx - start1.dx;
    double dy1 = end1.dy - start1.dy;
    double dx2 = end2.dx - start2.dx;
    double dy2 = end2.dy - start2.dy;

    // Tính định thức (determinant)
    double determinant = dx1 * dy2 - dy1 * dx2;

    // Kiểm tra song song hoặc trùng nhau
    if (determinant.abs() <= epsilon) {
      // Hai đường thẳng song song hoặc trùng nhau
      // Kiểm tra xem có đoạn chồng lấn không

      // Kiểm tra đồng tuyến
      double dx = start2.dx - start1.dx;
      double dy = start2.dy - start1.dy;
      double cross = dx * dy1 - dy * dx1;

      if (cross.abs() <= epsilon) {
        // Đồng tuyến - kiểm tra các điểm đầu mút
        // Kiểm tra start2 nằm trong [start1, end1]
        if (start2.isOnSegment(start1, end1, epsilon)) {
          return start2;
        }
        // Kiểm tra end2 nằm trong [start1, end1]
        if (end2.isOnSegment(start1, end1, epsilon)) {
          return end2;
        }
        // Kiểm tra start1 nằm trong [start2, end2]
        if (start1.isOnSegment(start2, end2, epsilon)) {
          return start1;
        }
        // Kiểm tra end1 nằm trong [start2, end2]
        if (end1.isOnSegment(start2, end2, epsilon)) {
          return end1;
        }
      }

      return null;
    }

    // Sử dụng công thức tổng quát để xác định điểm có nằm trên đoạn thẳng hay không
    // Điểm P nằm trong đoạn AB khi và chỉ khi:
    // vec(AP) = t * vec(AB)
    // => P = A + t * (B - A)
    //
    // Với P1 là điểm nằm trong đoạn thẳng [start1, end1]
    // ...P2...[start2, end2]
    //
    //
    //
    // P1 = start1 + t * (end1 - start1)
    // P2 = start2 + u * (end2 - start2)
    //
    // Để có giao điểm, điều kiện là : P1 == P2, trong đó t và u nằm trong khoảng [0,1]
    //
    // Suy ra:
    //
    // t = (dx * dy2 - dy * dx2) / determinant
    // u = (dx * dy1 - dy * dx1) / determinant
    //
    // với:
    //  dx1 = end1.dx - start1.dx;
    //  dy1 = end1.dy - start1.dy;
    //  dx2 = end2.dx - start2.dx;
    //  dy2 = end2.dy - start2.dy;
    //  dx = start2.dx - start1.dx
    //  dy = start2.dy - start1.dy
    //  determinant = dx1 * dy2 - dy1 * dx2

    // Tính tham số t và u
    double dx = start2.dx - start1.dx;
    double dy = start2.dy - start1.dy;

    double t = (dx * dy2 - dy * dx2) / determinant;
    double u = (dx * dy1 - dy * dx1) / determinant;

    // Kiểm tra giao điểm có nằm trong cả hai đoạn thẳng không
    // Sử dụng epsilon để xử lý sai số số học
    if (t >= -epsilon &&
        t <= 1 + epsilon &&
        u >= -epsilon &&
        u <= 1 + epsilon) {
      // Tính tọa độ giao điểm
      return Offset(start1.dx + t * dx1, start1.dy + t * dy1);
    }

    // Giao điểm nằm ngoài một trong hai đoạn thẳng
    return null;
  }

  bool isOnSegment(Offset start, Offset end, [double epsilon = EPSILON_E5]) {
    // Kiểm tra cross product gần 0 (đồng tuyến)
    double crossProduct =
        (dx - start.dx) * (end.dy - start.dy) -
        (dy - start.dy) * (end.dx - start.dx);

    if (crossProduct.abs() > epsilon) {
      return false;
    }

    // Kiểm tra nằm trong bounding box
    double minX = math.min(start.dx, end.dx) - epsilon;
    double maxX = math.max(start.dx, end.dx) + epsilon;
    double minY = math.min(start.dy, end.dy) - epsilon;
    double maxY = math.max(start.dy, end.dy) + epsilon;

    return dx >= minX && dx <= maxX && dy >= minY && dy <= maxY;
  }

  /// Tìm điểm nối dài về phía mặt phẳng chứa cả 2 điểm
  ///
  /// Ví dụ:
  /// * Cho điểm A (this) và B, tìm C sao cho C nằm trên đường thẳng đi qua A và B,
  /// * B và C nằm cùng phía với nhau so với A
  Offset getOuterSegmentPoint(Offset other, double distance) {
    // Tính vector từ this đến other
    final vector = other - this;

    // Tính độ dài của vector
    final vectorLength = vector.distance;

    // Nếu vector có độ dài bằng 0, không thể xác định hướng
    if (vectorLength == 0) {
      return this;
    }

    // Chuẩn hóa vector để có vector đơn vị
    final unitVector = vector / vectorLength;

    // Tính điểm C: từ this đi theo hướng của unitVector với khoảng cách distance
    // B và C nằm cùng phía so với A (this) vì chúng ta dùng cùng hướng vector
    final pointC = this + unitVector * distance;

    return pointC;
  }

  double distanceWith(Offset other) {
    return (this - other).distance;
  }

  double getAngleWith(Offset otherVector) {
    double angle1 = math.atan2(dy, dx);
    double angle2 = math.atan2(otherVector.dy, otherVector.dx);
    return angle1 - angle2;
  }

  double getScaleWith(Offset otherVector) {
    return otherVector.distance / distance;
  }
}

extension PairExtension on (bool, bool, bool, bool) {
  List<bool> get toList => [this.$1, this.$2, this.$3, this.$4];
}

extension RectExtension on Rect {
  Rect get reverse {
    return Rect.fromCenter(center: center, width: height, height: width);
  }

  Rect operator /(int other) {
    return Rect.fromCenter(
      center: center,
      width: width / other,
      height: height / other,
    );
  }

  Rect operator *(int other) {
    return Rect.fromCenter(
      center: center,
      width: width * other,
      height: height * other,
    );
  }

  /// Expand rect with distance
  Rect expandedRectWith(double distance) {
    Offset newTopLeft = topLeft.translate(-distance, -distance);
    Offset newBottomRight = bottomRight.translate(distance, distance);
    return Rect.fromPoints(newTopLeft, newBottomRight);
  }

  Rect invert() {
    Offset center = this.center;
    double newWidth = height;
    double newHeight = width;
    Offset newOffset = center.translate(-newWidth / 2, -newHeight / 2);
    return Rect.fromLTWH(newOffset.dx, newOffset.dy, width, height);
  }

  Rect copyWith({
    double? newLeft,
    double? newTop,
    double? newRight,
    double? newBottom,
  }) {
    double left = newLeft ?? this.left;
    double top = newTop ?? this.top;
    double right = newRight ?? this.right;
    double bottom = newBottom ?? this.bottom;

    // Giữ nguyên width nếu thay đổi left/right
    if (newLeft != null && newRight == null) {
      right = left + width;
    } else if (newRight != null && newLeft == null) {
      left = right - width;
    }

    // Giữ nguyên height nếu thay đổi top/bottom
    if (newTop != null && newBottom == null) {
      bottom = top + height;
    } else if (newBottom != null && newTop == null) {
      top = bottom - height;
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  double get distanceCross {
    return math.sqrt(width * width + height * height);
  }

  (bool, bool, bool, bool) checkInsideStatusWith(Rect srcRect) {
    bool isInsideTop = top >= srcRect.top;
    bool isInsideLeft = left >= srcRect.left;
    bool isInsideRight = right <= srcRect.right;
    bool isInsideBottom = bottom <= srcRect.bottom;
    return (isInsideLeft, isInsideTop, isInsideRight, isInsideBottom);
  }

  bool isCheckInsideWith(Rect srcRect) {
    return checkInsideStatusWith(srcRect).toList.every((element) => element);
  }

  bool containRect(Rect other) {
    return other.isCheckInsideWith(this);
  }

  bool equalTo(Rect other) {
    return topLeft.equalTo(other.topLeft) &&
        bottomRight.equalTo(other.bottomRight);
  }

  /// [self] rect changes inside [outerRect]
  ///
  Rect limitSelfWith(Rect outerRect) {
    double limitedWidth = math.min(width, outerRect.width);
    double limitedHeight = math.min(height, outerRect.height);
    return Rect.fromLTWH(
      left.clamp(
        outerRect.left,
        outerRect.left + (outerRect.width - limitedWidth),
      ),
      top.clamp(
        outerRect.top,
        outerRect.top + (outerRect.height - limitedHeight),
      ),
      limitedWidth,
      limitedHeight,
    );
  }

  /// Ensure [self] must include inner rect
  ///
  /// Đảm bảo rằng chính rect hiện tại phải chứa [inner]
  Rect limitSelfToInclude(Rect inner, {double? angleByRadian, Offset? pivot}) {
    Rect outer = this;
    if (angleByRadian != null && pivot != null) {
      // Xoay rect inner ngược chiều kim đồng hồ với góc angleByRadian quanh pivot
      final cosAngle = math.cos(-angleByRadian);
      final sinAngle = math.sin(-angleByRadian);

      List<Offset> rotatedPoints =
          [
            outer.topLeft,
            outer.topRight,
            outer.bottomRight,
            outer.bottomLeft,
          ].map((point) {
            final translatedX = point.dx - pivot.dx;
            final translatedY = point.dy - pivot.dy;

            final rotatedX =
                translatedX * cosAngle - translatedY * sinAngle + pivot.dx;
            final rotatedY =
                translatedX * sinAngle + translatedY * cosAngle + pivot.dy;

            return Offset(rotatedX, rotatedY);
          }).toList();

      double minX = rotatedPoints.map((p) => p.dx).reduce(math.min);
      double maxX = rotatedPoints.map((p) => p.dx).reduce(math.max);
      double minY = rotatedPoints.map((p) => p.dy).reduce(math.min);
      double maxY = rotatedPoints.map((p) => p.dy).reduce(math.max);

      outer = Rect.fromLTRB(minX, minY, maxX, maxY);
    }
    double dx = 0, dy = 0;
    if (inner.left < outer.left) {
      dx = inner.left - outer.left;
    }
    if (inner.right > outer.right) {
      dx = inner.right - outer.right;
    }
    if (inner.top < outer.top) {
      dy = inner.top - outer.top;
    }
    if (inner.bottom > outer.bottom) {
      dy = inner.bottom - outer.bottom;
    }
    return shift(Offset(dx, dy));
  }

  Rect limitSelfToContain(Rect innerRect) {
    // Nếu hình chữ nhật hiện tại nhỏ hơn hoặc bằng innerRect, trả về vị trí hiện tại
    if (width <= innerRect.width && height <= innerRect.height) {
      return this;
    }

    double ratioSelf = size.aspectRatio;
    double ratioInner = innerRect.size.aspectRatio;

    if (ratioSelf > ratioInner) {
      // Cạnh min là cạnh height - scale theo chiều cao
      double scaleFactor = innerRect.height / height;
      double newWidth = width * scaleFactor;
      double newHeight = innerRect.height;
      double left = innerRect.left + (innerRect.width - newWidth) / 2;
      double top = innerRect.top;

      return Rect.fromLTWH(left, top, newWidth, newHeight);
    } else if (ratioSelf < ratioInner) {
      // Cạnh min là cạnh width - scale theo chiều rộng
      double scaleFactor = innerRect.width / width;
      double newWidth = innerRect.width;
      double newHeight = height * scaleFactor;
      double left = innerRect.left;
      double top = innerRect.top + (innerRect.height - newHeight) / 2;

      return Rect.fromLTWH(left, top, newWidth, newHeight);
    } else {
      // Tỉ lệ khung hình bằng nhau - giữ nguyên tỉ lệ, fit to innerRect
      return innerRect;
    }
  }

  /// Dùng để giới hạn [self] sao cho sau khi scale và translate [self],
  /// luôn luôn bao quanh [innerRect]
  ///
  /// * Giữ nguyên aspect ratio của [self], giữ nguyên [innerRect]
  Rect limitScaleTranslateSelfToContain(Rect innerRect) {
    Rect outerRect = this;

    double minScaleX = innerRect.width / outerRect.width;
    double minScaleY = innerRect.height / outerRect.height;

    double minScale = minScaleX > minScaleY ? minScaleX : minScaleY;
    // Giới hạn sao cho kích thước của outer rect không có cạnh nào nhỏ hơn inner rect
    bool isOuterSmallerInner = minScale > 1.0;
    if (isOuterSmallerInner) {
      double newWidth = outerRect.width * minScale;
      double newHeight = outerRect.height * minScale;
      outerRect = Rect.fromCenter(
        center: outerRect.center,
        width: newWidth,
        height: newHeight,
      );
    }
    // Giới hạn vị trí của của outer rect sao cho không cho inner rect thoát ra ngoài
    // bằng cách lấy độ chênh lệch vị trí giữa các góc tương ứng, sau đó dịch chuyển outer rect
    if (!outerRect.contains(innerRect.topLeft) ||
        !outerRect.contains(innerRect.bottomRight)) {
      double deltaX = 0.0;
      double deltaY = 0.0;

      if (innerRect.left < outerRect.left) {
        deltaX = innerRect.left - outerRect.left;
      } else if (innerRect.right > outerRect.right) {
        deltaX = innerRect.right - outerRect.right;
      }

      if (innerRect.top < outerRect.top) {
        deltaY = innerRect.top - outerRect.top;
      } else if (innerRect.bottom > outerRect.bottom) {
        deltaY = innerRect.bottom - outerRect.bottom;
      }

      outerRect = outerRect.shift(Offset(deltaX, deltaY));
    }
    return outerRect;
  }
}
