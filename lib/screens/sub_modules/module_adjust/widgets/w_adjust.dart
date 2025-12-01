import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/commons/extension.dart';
import 'package:pass1_/helpers/log_custom.dart';
import 'package:pass1_/models/adjust_subject_model.dart';
import 'package:pass1_/providers/blocs/theme_bloc.dart';
import 'package:pass1_/widgets/w_custom_painter.dart';
import 'package:pass1_/widgets/w_text.dart';

Widget buildBackgroundOptionItem({
  required BuildContext context,
  required bool isSelected,
  required Function() onTap,
  required double size,
  File? image,
  Color? color,
  String? mediaSrc,
  Color? selectedColor, // apply with color picker
}) {
  double paddingEachColorItem = 10;
  bool isDarkMode = BlocProvider.of<ThemeBloc>(context).isDarkMode;
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: size,
      width: size,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isSelected)
            Container(
              height: size,
              width: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Theme.of(context).searchViewTheme.backgroundColor,
              ),
            ),
          // background white or black
          Container(
            height: size - 6,
            width: size - 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
          if (image != null)
            _buildPreviewSelectionImage(
              image: image,
              size: size - paddingEachColorItem,
            ),
          if (color != null)
            Container(
              height: size - paddingEachColorItem,
              width: size - paddingEachColorItem,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: isDarkMode ? color : color.withValues(alpha: 0.83),
                border: Border.all(
                  color: isDarkMode ? white01 : black01,
                  width: 2,
                ),
              ),
            ),
          if (mediaSrc != null)
            Container(
              height: size - paddingEachColorItem,
              width: size - paddingEachColorItem,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
              ),
              child: Image.asset(mediaSrc),
            ),
          Container(
            height: 10,
            width: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: selectedColor ?? transparent,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildPreviewSelectionImage({
  required File image,
  required double size,
}) {
  return Container(
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(999)),
    height: size,
    width: size,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Image.file(image, fit: BoxFit.cover),
    ),
  );
}

Widget buildAdjustSubjectItem(
  bool isDarkMode,
  bool isFocus,
  AdjustSubjectModel model,
  Function() onTap,
) {
  return Opacity(
    opacity: isFocus ? 1 : 0.2,
    child: Container(
      width: 56,
      alignment: Alignment.center,
      child: Container(
        height: 28,
        width: 28,
        child: Image.asset(
          isDarkMode ? model.listMediaSrc[1] : model.listMediaSrc[0],
        ),
      ),
    ),
  );
}

Widget buildAdjustSubjectTitlePreview({
  required bool isDarkMode,
  required AdjustSubjectModel model,
}) {
  consolelog("buildAdjustSubjectTitlePreview: ${model.toString()}");
  final delta = double.parse(
    (model.currentRatioValue - model.rootRatioValue).roundWithUnit(
      fractionDigits: 2,
    ),
  );
  String additionalInformation = "";
  if (delta > 0) {
    additionalInformation = ":+${delta.roundWithUnit(fractionDigits: 2)}";
  } else if (delta < 0) {
    additionalInformation = ":${delta.roundWithUnit(fractionDigits: 2)}";
  } else {}
  consolelog("additionalInformation: $additionalInformation");
  return Column(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Container(
        height: 20,
        width: 160,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: isDarkMode ? black05 : black03,
        ),
        alignment: Alignment.center,
        child: FittedBox(
          child: WTextContent(
            value: "${model.title}$additionalInformation",
            textSize: 12,
            textLineHeight: 16,
            textColor: white,
          ),
        ),
      ),
      const SizedBox(height: 10),
    ],
  );
}

Widget buildBlurShadowImage1(
  Uint8List data,
  double? height,
  double? width, {
  double? top,
  double? left,
  double? right,
  double? bottom,
}) {
  return Positioned(
    top: top,
    left: left,
    right: right,
    bottom: bottom,
    child: ImageFiltered(
      imageFilter: PAINT_BLURRED.imageFilter!,
      child: ColorFiltered(
        colorFilter: PAINT_BLURRED.colorFilter!,
        child: Image.memory(
          data,
          height: height,
          width: width,
          gaplessPlayback: true,
        ),
      ),
    ),
  );
}

Widget buildBlurShadowImage(
  ui.Image image,
  double? height,
  double? width,
  Paint paint, {
  double? top,
  double? left,
  double? right,
  double? bottom,
}) {
  return Positioned(
    top: top,
    left: left,
    right: right,
    bottom: bottom,
    child: CustomPaint(
      painter: CustomPainterBlurredShadowImage(
        paintBlur: paint,
        image: image,
        targetSize: Size(width!, height!),
      ),
    ),
  );
}

Widget buildBlursReflection1(Uint8List data, double? height, double? width) {
  return ImageFiltered(
    imageFilter: PAINT_BLURRED.imageFilter!,
    child: Image.memory(
      data,
      height: height,
      width: width,
      gaplessPlayback: true,
    ),
  );
}

Widget buildBlursReflection(ui.Image image, double? height, double? width) {
  return Opacity(
    opacity: 0.02,
    child: CustomPaint(
      painter: CustomPainterBlurredImage(
        image: image,
        targetSize: Size(width!, height!),
      ),
    ),
  );
}
