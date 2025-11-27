import 'package:auto_size_text/auto_size_text.dart';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passport_photo_2/commons/colors.dart';
import 'package:passport_photo_2/commons/constants.dart';
import 'package:passport_photo_2/providers/blocs/theme_bloc.dart';

Widget buildSegmentControl({
  required BuildContext context,
  required int? groupValue,
  required Map<int, String> listSegment,
  required void Function(int?) onValueChanged,
  double? borderRadius,
  Color? unactiveTextColor,
  Color? activeTextColor,
  EdgeInsets? marginItem,
}) {
  double borderRadius0 = borderRadius ?? 999;
  bool isDarkMode = BlocProvider.of<ThemeBloc>(context).isDarkMode;
  return CustomSlidingSegmentedControl<int>(
    onValueChanged: onValueChanged,
    initialValue: groupValue,
    isStretch: true,
    children: listSegment.map((key, value) {
      return MapEntry<int, Widget>(
          key,
          Container(
              clipBehavior: Clip.none,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius0),
              ),
              margin: marginItem,
              child: FittedBox(
                child: AutoSizeText(
                  value,
                  maxLines: 1,
                  style: TextStyle(
                    color: _getTextColor(
                      isDarkMode,
                      groupValue,
                      key,
                      unactiveTextColor,
                      activeTextColor,
                    ),
                    height: 13 / 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: FONT_GOOGLESANS,
                  ),
                ),
              )
              // WTextContent(
              //   value: value,
              //   textColor: _getTextColor(isDarkMode, groupValue, key),
              //   textSize: 13,
              //   textLineHeight: 20,
              //   textFontWeight: FontWeight.w600,
              // ),
              ));
    }),
    decoration: BoxDecoration(
      color: Theme.of(context).tabBarTheme.unselectedLabelColor!,
      borderRadius: BorderRadius.circular(borderRadius0),
    ),
    thumbDecoration: BoxDecoration(
      color: white,
      borderRadius: BorderRadius.circular(borderRadius0),
    ),
  );
}

Color _getTextColor(
  bool isDarkMode,
  int? groupValue,
  int checkValue,
  Color? unactiveTextColor,
  Color? activeTextColor,
) {
  Color textColor;

  if (isDarkMode) {
    if (groupValue == checkValue) {
      textColor = activeTextColor ?? black;
    } else {
      textColor = unactiveTextColor ?? white;
    }
  } else {
    if (groupValue == checkValue) {
      textColor = activeTextColor ?? black;
    } else {
      textColor = unactiveTextColor ?? black;
    }
  }
  return textColor;
}
