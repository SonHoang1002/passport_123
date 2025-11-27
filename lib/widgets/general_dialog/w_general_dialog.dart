import 'package:flutter/material.dart';
import 'package:passport_photo_2/commons/colors.dart';

void showCustomDialogWithOffset({
  required BuildContext context,
  required Widget newScreen,
}) {
  showGeneralDialog(
    context: context,
    pageBuilder: (context, animation, secondaryAnimation) {
      return newScreen;
    },
    barrierColor: transparent,
  );
}
