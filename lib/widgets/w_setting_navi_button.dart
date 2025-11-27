import 'package:flutter/material.dart';
import 'package:passport_photo_2/commons/constants.dart';
import 'package:passport_photo_2/screens/module_setting/setting.dart';
import 'package:passport_photo_2/widgets/bottom_sheet/show_bottom_sheet.dart';

class WSettingNavigatorButton extends StatelessWidget {
  final bool isDarkMode;
  const WSettingNavigatorButton({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final _size = MediaQuery.sizeOf(context);
    return GestureDetector(
      onTap: () {
        showCustomBottomSheetWithClose(
          context: context,
          child: const Setting(),
          height: _size.height * 0.95,
        );
      },
      child: Container(
        height: 46,
        width: 46,
        child: Image.asset(PATH_PREFIX_ICON +
            (isDarkMode
                ? "icon_setting_dark.png"
                : "icon_setting_light.png")),
      ),
    );
  }
}
