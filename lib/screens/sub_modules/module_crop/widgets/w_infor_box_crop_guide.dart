import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:passport_photo_2/commons/colors.dart';
import 'package:passport_photo_2/commons/constants.dart';
import 'package:passport_photo_2/models/country_passport_model.dart';

Widget buildInformationBox(
    {required Key key,
    required double heightTooltip,
    required bool isDarkMode,
    required String percentValue,
    required String mainValue,
    required Unit currentUnit,
    required Offset offsetBox,
    Function()? onTap}) {
  return Positioned(
    key: key,
    top: offsetBox.dy,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? white : black,
          borderRadius: BorderRadius.circular(4),
        ),
        height: heightTooltip,
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          FittedBox(
            child: AutoSizeText(
              "$percentValue%",
              maxFontSize: 10,
              minFontSize: 5,
              textAlign: TextAlign.start,
              style: TextStyle(
                  height: 13.13 / 11,
                  color: isDarkMode ? black : white,
                  fontWeight: FontWeight.w700,
                  fontFamily: FONT_GOOGLESANS,),
            ),
          ),
          FittedBox(
            child: AutoSizeText(
              "$mainValue${currentUnit.title}",
              maxFontSize: 10,
              minFontSize: 5,
              maxLines: 2,
              textAlign: TextAlign.start,
              style: TextStyle(
                  height: 13.13 / 11,
                  color: isDarkMode ? black : white,
                  fontWeight: FontWeight.w700,
                  fontFamily: FONT_GOOGLESANS),
            ),
          ),
        ]),
      ),
    ),
  );
}
