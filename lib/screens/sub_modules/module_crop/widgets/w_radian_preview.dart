import 'dart:math';
import 'package:flutter/material.dart';
import 'package:passport_photo_2/commons/colors.dart';
import 'package:passport_photo_2/models/crop_model.dart';
import 'package:passport_photo_2/screens/sub_modules/module_crop/widgets/w_circle_degree_preview.dart';
import 'package:passport_photo_2/widgets/w_text.dart';

Widget buildPreviewRadianWidget(
    BuildContext context, bool isDarkMode, CropModel? cropModel) {
  double deltaRotate;
  int deltaDegree;
  if (cropModel != null) {
    deltaRotate =
        cropModel.currentRotateValue - cropModel.instructionRotateValue;
  } else {
    deltaRotate = 0;
  }
  deltaDegree =
      max(-45.000001, min(45.000001, ((deltaRotate) * 90).toInt())).toInt();
  Color _textColor = Theme.of(context).textTheme.bodySmall!.color!;
  Color _activeColor = isDarkMode ? primaryDark1 : primaryLight1;
  Color _inactiveColor = isDarkMode ? white02 : black02;

  if (deltaDegree >= 0) {
    if (isDarkMode) {
      _textColor = white;
      _activeColor = primaryDark1;
      _inactiveColor = primaryDark1.withValues(alpha: 0.4);
    } else {
      _textColor = black;
      _activeColor = primaryLight1;
      _inactiveColor = primaryLight1.withValues(alpha: 0.4);
    }
  } else {
    if (isDarkMode) {
      _textColor = white;
      _activeColor = white.withValues(alpha: 0.5);
      _inactiveColor = white.withValues(alpha: 0.2);
    } else {
      _textColor = black;
      _activeColor = black.withValues(alpha: 0.5);
      _inactiveColor = black.withValues(alpha: 0.2);
    }
  }

  return Container(
    // margin: const EdgeInsets.only(bottom: 5),
    height: 32,
    width: 32,
    child: Stack(
      alignment: Alignment.center,
      children: [
        WCircleDegreePreview(
          size: const Size(32, 32),
          // inactiveColor: Theme.of(context).badgeTheme.backgroundColor!,
          inactiveColor: _inactiveColor,
          activeColor: _activeColor,
          degree: deltaRotate * 360,
        ),
        Container(
          decoration: BoxDecoration(
            color: transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: WTextContent(
            textAlign: TextAlign.center,
            textSize: 13,
            textLineHeight: 13,
            textColor: _textColor,
            value: deltaDegree.toString(),
          ),
        ),
      ],
    ),
  );
}
