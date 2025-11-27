import 'package:flutter/material.dart';
import 'package:passport_photo_2/widgets/w_spacer.dart';
import 'package:passport_photo_2/widgets/w_text.dart';

Widget buildDialogInformationItem(
  BuildContext context,
  String value,
  Function() onTap, {
  Color? textColor, // = const Color.fromRGBO(10, 132, 255, 1),
  double textSize = 12,
  double textLineHeight = 15,
  FontWeight textFontWeight = FontWeight.w500,
  BoxDecoration? boxDecoration,
  double? width,
  double? height,
  String? subTitle,
  int? textMaxLength,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: height,
      width: width,
      constraints: BoxConstraints(
        minHeight: height ?? 40,
        minWidth: width ?? 160,
      ),
      decoration: boxDecoration,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: subTitle != null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FittedBox(
                  child: WTextContent(
                    value: value,
                    textColor: textColor ??
                        Theme.of(context).textTheme.displayLarge!.color,
                    textFontWeight: textFontWeight,
                    textLineHeight: textLineHeight,
                    textMaxLength: textMaxLength,
                    textSize: textSize,
                  ),
                ),
                WSpacer(
                  width: 10,
                ),
                FittedBox(
                  child: WTextContent(
                    value: subTitle,
                    textColor: textColor ??
                        Theme.of(context).textTheme.displayLarge!.color,
                    textFontWeight: textFontWeight,
                    textLineHeight: textLineHeight,
                    textMaxLength: textMaxLength,
                    textSize: textSize,
                  ),
                ),
              ],
            )
          : WTextContent(
              value: value,
              textColor:
                  textColor ?? Theme.of(context).textTheme.displayLarge!.color,
              textFontWeight: textFontWeight,
              textLineHeight: textLineHeight,
              // textMaxLength: 1,
              textSize: textSize,
            ),
    ),
  );
}
