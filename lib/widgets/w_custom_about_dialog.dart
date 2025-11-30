import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/helpers/navigator_route.dart';
import 'package:pass1_/widgets/w_divider.dart';
import 'package:pass1_/widgets/w_text.dart';

void showCustomAboutDialog(
  BuildContext context,
  double dialogWidth,
  String title,
  String content, {
  Color? titleColor,
  Color? contentColor,
}) {
  Size _size = MediaQuery.sizeOf(context);
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              color: Theme.of(context).dialogBackgroundColor,
            ),
            height: (title != "") ? 160 : 120,
            width: dialogWidth,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: title == ""
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.spaceEvenly,
                    children: [
                      if (title != "")
                        Container(
                          padding: const EdgeInsets.all(7),
                          child: AutoSizeText(
                            title,
                            textAlign: TextAlign.center,
                            maxFontSize: 25,
                            minFontSize: _size.height < 700 ? 19 : 24,
                            style: TextStyle(
                              fontFamily: FONT_GOOGLESANS,
                              fontWeight: FontWeight.w700,
                              color:
                                  titleColor ??
                                  Theme.of(context).textTheme.bodySmall!.color,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: AutoSizeText(
                          content,
                          textAlign: TextAlign.center,
                          maxFontSize: (title != "") ? 14 : 16,
                          minFontSize: (title != "") ? 8 : 10,
                          maxLines: 3,
                          style: TextStyle(
                            color:
                                contentColor ??
                                Theme.of(
                                  context,
                                ).textTheme.displayMedium!.color,
                            fontFamily: FONT_GOOGLESANS,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    WDivider(
                      width: dialogWidth,
                      height: 0.5,
                      color: Theme.of(context).dividerTheme.color,
                      margin: EdgeInsets.zero,
                    ),
                    GestureDetector(
                      onTap: () {
                        popNavigator(context);
                      },
                      child: Container(
                        height: 50,
                        color: transparent,
                        alignment: Alignment.center,
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          width: double.infinity,
                          child: WTextContent(value: "OK", textColor: blue),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
