import 'package:flutter/material.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/models/project_model.dart';

Widget buildImageOriginal({
  required ProjectModel projectModel,
  double? imageHeight,
  double? imageWidth,
}) {
  ///   Giảm shadow default, tăng độ trắng background default
  return Stack(
    children: [
      // noise
      Image.asset(
        "${PATH_PREFIX_IMAGE}noise.png",
        height: imageHeight,
        width: imageWidth,
        fit: BoxFit.cover,
        color: (projectModel.background is Color)
            ? projectModel.background
            : null,
        colorBlendMode: BlendMode.multiply,
        opacity: const AlwaysStoppedAnimation(0.1), //0.3
      ),
      // gradient
      Container(
        height: imageHeight,
        width: imageWidth,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              transparent,
              black.withValues(alpha: 0.015), //0.02
            ],
          ),
        ),
        child: SizedBox(height: imageHeight, width: imageWidth),
      ),
    ],
  );
}
