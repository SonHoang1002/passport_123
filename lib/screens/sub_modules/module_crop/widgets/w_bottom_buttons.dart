import 'package:flutter/material.dart';
import 'package:passport_photo_2/commons/colors.dart';
import 'package:passport_photo_2/commons/constants.dart';
import 'package:passport_photo_2/helpers/navigator_route.dart';
import 'package:passport_photo_2/widgets/w_button.dart';
import 'package:passport_photo_2/widgets/w_spacer.dart';

Widget buildBottomButtons(
    BuildContext context, bool isDarkMode, Function() onSave) {
  final _size = MediaQuery.sizeOf(context);
  final bool _isDarkMode = isDarkMode;
  return Visibility(
    visible: MediaQuery.of(context).viewInsets.bottom < 100,
    maintainAnimation: _size.height > MIN_SIZE.height,
    maintainSize: _size.height > MIN_SIZE.height,
    maintainState: _size.height > MIN_SIZE.height,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Flex(
        direction: Axis.horizontal,
        children: [
          Flexible(
            child: WButtonFilled(
              height: 54,
              message: "Discard",
              backgroundColor: _isDarkMode ? blockDark : blockLight,
              textColor: !_isDarkMode ? black05 : white05,
              onPressed: () {
                popNavigator(context);
              },
            ),
          ),
          WSpacer(width: 20),
          Flexible(
            flex: 2,
            child: WButtonFilled(
              height: 54,
              message: "Save guide",
              backgroundColor: _isDarkMode ? primaryDark1 : primaryLight1,
              onPressed: () {
                // create
                onSave();
              },
            ),
          ),
        ],
      ),
    ),
  );
}
