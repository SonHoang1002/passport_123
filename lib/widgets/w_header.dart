import 'dart:math';

import 'package:flutter/material.dart';
import 'package:passport_photo_2/commons/colors.dart';
import 'package:passport_photo_2/commons/constants.dart';
import 'package:passport_photo_2/models/step_model.dart';
import 'package:passport_photo_2/screens/module_home/widgets/w_home.dart';

class WHeader extends StatelessWidget {
  final StepModel currentStep;
  final Function(StepModel step) onSelectStep;
  final bool isDarkMode;
  final bool isHaveSettingButton;
  final double? width;
  const WHeader({
    super.key,
    required this.currentStep,
    required this.onSelectStep,
    required this.isDarkMode,
    this.isHaveSettingButton = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: max(0, MediaQuery.of(context).padding.top - 10),
      ),
      height: 150,
      width: MediaQuery.sizeOf(context).width,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).sliderTheme.inactiveTrackColor!,
            width: 0.5,
          ),
        ),
        color: Theme.of(context).bottomAppBarTheme.color,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: width ?? MediaQuery.sizeOf(context).width,
          child: Flex(
            direction: Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: LIST_STEP_SELECTION.map((e) {
              Color iconBackground =
                  Theme.of(context).badgeTheme.backgroundColor!;
              Color stepColor =
                  Theme.of(context).searchViewTheme.backgroundColor!;
              Color textColor =
                  Theme.of(context).textTheme.displayMedium!.color!;
              bool isActive = currentStep.id == e.id;
              if (isActive) {
                if (isDarkMode) {
                  iconBackground = stepColor = textColor = primaryDark1;
                } else {
                  iconBackground = stepColor = textColor = primaryLight1;
                }
              }
              return buildStepSelection(
                currentStep: currentStep,
                stepModel: e,
                isDarkMode: isDarkMode,
                iconBackground: iconBackground,
                stepColor: stepColor,
                iconColor: isActive ? white : null,
                textColor: textColor,
                onTap: () {
                  onSelectStep(e);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
