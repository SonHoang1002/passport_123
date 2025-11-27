import 'package:flutter/material.dart';

Widget buildDot(
  Color color,
  double size,
) {
  return Container(
    height: size,
    width: size,
    decoration:
        BoxDecoration(borderRadius: BorderRadius.circular(999), color: color),
  );
}
