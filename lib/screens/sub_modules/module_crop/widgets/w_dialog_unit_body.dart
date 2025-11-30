import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/models/country_passport_model.dart';
import 'package:pass1_/providers/blocs/theme_bloc.dart';
import 'package:pass1_/widgets/general_dialog/w_information_item.dart';
import 'package:pass1_/widgets/w_divider.dart';

Widget buildDialogUnitBody({
  required BuildContext context,
  required Unit currentUnit,
  required Function(Unit unit) onSelected,
  double? width,
  double? height,
  Color? color,
}) {
  final rWidth = width;
  final isDarkMode = BlocProvider.of<ThemeBloc>(
    context,
    listen: false,
  ).isDarkMode;
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Stack(
      children: [
        Positioned.fill(
          child: Container(color: Theme.of(context).dividerTheme.color),
        ),
        Column(
          children: LIST_UNIT
              .where((element) => element.id != currentUnit.id)
              .toList()
              .map((e) {
                final index = LIST_UNIT.indexWhere(
                  (element) => element.id == e.id,
                );
                Color bgColor =
                    color ?? Theme.of(context).dialogBackgroundColor;
                Color textColor = isDarkMode ? white : black;
                if (e.id == currentUnit.id) {
                  textColor = blue;
                }
                BoxDecoration boxDecoration = BoxDecoration(color: bgColor);
                if (index == 0) {
                  boxDecoration = BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    color: bgColor,
                  );
                }
                if (index == LIST_UNIT.length - 1) {
                  boxDecoration = BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                    color: bgColor,
                  );
                }
                return Column(
                  children: [
                    buildDialogInformationItem(
                      context,
                      e.title,
                      () => onSelected(e),
                      boxDecoration: boxDecoration,
                      width: rWidth,
                      textColor: textColor,
                      height: height,
                    ),
                    if (index != LIST_UNIT.length - 1)
                      WDivider(height: 0.5, width: rWidth),
                  ],
                );
              })
              .toList(),
        ),
      ],
    ),
  );
}
