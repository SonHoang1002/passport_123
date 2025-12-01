import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/models/project_model.dart';
import 'package:pass1_/models/step_model.dart';
import 'package:pass1_/providers/blocs/device_platform_bloc.dart';
import 'package:pass1_/widgets/w_button.dart';
import 'package:pass1_/widgets/w_setting_navi_button.dart';
import 'package:pass1_/widgets/w_spacer.dart';

// ignore: must_be_immutable
class WFooter extends StatelessWidget {
  ProjectModel projectModel;
  StepModel currentStep;
  bool isDarkMode;
  final Function() onNext;
  final Function()? onExport;
  final Function()? onPrint;
  final double? footerHeight;
  final bool isHaveSettingButton;
  WFooter({
    super.key,
    required this.projectModel,
    required this.currentStep,
    required this.isDarkMode,
    required this.onNext,
    this.footerHeight,
    this.onExport,
    this.onPrint,
    this.isHaveSettingButton = true,
  });

  @override
  Widget build(BuildContext context) {
    Size _size = MediaQuery.sizeOf(context);
    bool isPhone = BlocProvider.of<DevicePlatformCubit>(context).isPhone;

    return Container(
      decoration: BoxDecoration(
        border: projectModel.selectedFile == null
            ? null
            : Border(
                top: BorderSide(
                  color: Theme.of(context).sliderTheme.inactiveTrackColor!,
                  width: 0.5,
                ),
              ),
      ),
      alignment: Alignment.center,
      height:
          footerHeight ??
          (projectModel.selectedFile == null
              ? null
              : (_size.width > MIN_SIZE.width ? 130 : 130)),
      child: (currentStep.id == LIST_STEP_SELECTION[3].id)
          ? Container(
              height:
                  footerHeight ?? (_size.width > MIN_SIZE.width ? 130 : 130),
              padding: EdgeInsets.only(
                right: 20,
                left: 20,
                bottom: MediaQuery.of(context).padding.bottom,
              ),
              color: Theme.of(context).bottomAppBarTheme.color,
              child: Flex(
                direction: Axis.horizontal,
                mainAxisAlignment: isPhone
                    ? MainAxisAlignment.spaceEvenly
                    : MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: SIZE_EXAMPLE.width / 2,
                      ),
                      child: WButtonFilled(
                        height: 54,
                        message: "Export",
                        backgroundColor: isDarkMode
                            ? primaryDark1
                            : primaryLight1,
                        onPressed: () {
                          onExport != null ? onExport!() : null;
                        },
                      ),
                    ),
                  ),
                  WSpacer(width: 10),
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: SIZE_EXAMPLE.width / 2,
                      ),
                      child: WButtonFilled(
                        height: 54,
                        message: "Print",
                        backgroundColor: isDarkMode ? white : black,
                        textColor: isDarkMode ? black : white,
                        onPressed: () {
                          onPrint != null ? onPrint!() : null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Container(
              color: projectModel.selectedFile == null
                  ? null
                  : Theme.of(context).bottomAppBarTheme.color,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom,
                right: 20,
                left: 20,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (projectModel.selectedFile != null)
                    WButtonFilled(
                      height: 50,
                      width: 214,
                      message: "Next Step",
                      backgroundColor: isDarkMode
                          ? primaryDark1
                          : primaryLight1,
                      onPressed: () {
                        onNext();
                      },
                    ),
                  Container(
                    padding: EdgeInsets.only(
                      bottom: projectModel.selectedFile == null ? 7 : 0,
                    ),
                    alignment: projectModel.selectedFile != null
                        ? Alignment.centerRight
                        : Alignment.center,
                    child: (isHaveSettingButton)
                        ? WSettingNavigatorButton(isDarkMode: isDarkMode)
                        : const SizedBox(),
                  ),
                  // _buildTestWidget(),
                ],
              ),
            ),
    );
  }

  Widget _buildTestWidget() {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: () async {
          await MediaScanner.loadMedia(
            path:
                "/storage/emulated/0/Pictures/jim-tran-6XZ_wgiwFjI-unsplash.jpg",
          );
          // await openAppSettings();
        },
        child: Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: red,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Image.asset(
            PATH_PREFIX_ICON +
                (isDarkMode
                    ? "icon_setting_dark.png"
                    : "icon_setting_light.png"),
          ),
        ),
      ),
    );
  }
}
