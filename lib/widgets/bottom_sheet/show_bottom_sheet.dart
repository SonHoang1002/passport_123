import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passport_photo_2/commons/colors.dart';
import 'package:passport_photo_2/commons/constants.dart';
import 'package:passport_photo_2/helpers/navigator_route.dart';
import 'package:passport_photo_2/providers/blocs/theme_bloc.dart';

void showCustomBottomSheetWithClose({
  required BuildContext context,
  required Widget child,
  required double height,
  Function()? onClose,
  bool isHaveCloseButton = true,
}) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      final isDarkMode =
          BlocProvider.of<ThemeBloc>(context, listen: false).isDarkMode;
      return Container(
          height: height,
          decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            children: [
              if (isHaveCloseButton)
                Container(
                  alignment: Alignment.centerRight,
                  margin: const EdgeInsets.only(right: 15, top: 20),
                  child: GestureDetector(
                    onTap: () {
                      if (onClose != null) {
                        onClose();
                      } else {
                        popNavigator(context);
                      }
                    },
                    child: Container(
                      height: 28,
                      width: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Image.asset(PATH_PREFIX_ICON +
                          (isDarkMode
                              ? "icon_close_dark.png"
                              : "icon_close_light.png")),
                    ),
                  ),
                ),
              Expanded(child: child),
            ],
          ));
    },
    isScrollControlled: true,
  );
}

void showCustomBottomSheetWithDragIcon({
  required BuildContext context,
  required Widget child,
  required double height,
  Function()? onClose,
  bool isHaveButton = true,
}) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return Container(
        height: height,
        decoration: const BoxDecoration(
          color: transparent,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            if (isHaveButton)
              Container(
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () {
                    if (onClose != null) {
                      onClose();
                    } else {
                      popNavigator(context);
                    }
                  },
                  child: Container(
                    height: 5,
                    width: 40,
                    margin: const EdgeInsets.only(bottom: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: white,
                    ),
                  ),
                ),
              ),
            Expanded(child: child),
          ],
        ),
      );
    },
    isScrollControlled: true,
    backgroundColor: transparent,
  );
}
