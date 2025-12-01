import 'package:flutter/material.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/models/step_model.dart';
import 'package:pass1_/widgets/w_spacer.dart';
import 'package:pass1_/widgets/w_text.dart';

Widget buildStepSelection({
  required StepModel currentStep,
  required StepModel stepModel,
  required Color iconBackground,
  required Color? iconColor,
  required Color stepColor,
  required Color textColor,
  required bool isDarkMode,
  required Function() onTap,
}) {
  bool isActive = currentStep.id == stepModel.id;
  return GestureDetector(
    onTap: onTap,
    child: Container(
      color: transparent,
      child: Column(
        children: [
          // icon
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: iconBackground,
            ),
            child: Container(
              padding: const EdgeInsets.all(7),
              child: Image.asset(
                stepModel.listMediaSrc[0],
                color: isActive
                    ? null
                    : isDarkMode
                    ? grey.withValues(alpha: 0.9)
                    : black.withValues(alpha: 0.5),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 70,
            height: 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: stepColor,
            ),
          ),
          WTextContent(
            value: stepModel.title,
            textSize: 12,
            textLineHeight: 12,
            textFontWeight: FontWeight.w600,
            textColor: textColor,
          ),
        ],
      ),
    ),
  );
}

Widget buildHomeSelection({
  required String iconPath,
  required String title,
  required double iconSize,
  Color? textColor,
  Color? titleBackgroundColor,
  Function()? onTap,
}) {
  return Column(
    children: [
      GestureDetector(
        onTap: onTap,
        child: Image.asset(iconPath, height: iconSize, width: iconSize),
      ),
      WSpacer(height: 10),
      GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: titleBackgroundColor,
            borderRadius: BorderRadius.circular(13),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: WTextContent(
            value: title,
            textSize: 12,
            textLineHeight: 15,
            textColor: textColor,
          ),
        ),
      ),
    ],
  );
}
