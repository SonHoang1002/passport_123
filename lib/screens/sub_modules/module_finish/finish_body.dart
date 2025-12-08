import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/helpers/log_custom.dart';
import 'package:pass1_/helpers/native_bridge/method_channel.dart';
import 'package:pass1_/models/project_model.dart';
import 'package:pass1_/models/step_model.dart';
import 'package:pass1_/providers/blocs/device_platform_bloc.dart';
import 'package:pass1_/providers/blocs/theme_bloc.dart';
import 'package:pass1_/screens/module_home/widgets/w_footer.dart';
import 'package:pass1_/widgets/w_spacer.dart';
import 'package:pass1_/widgets/w_text.dart';

class BodyFinish extends StatefulWidget {
  final StepModel currentStep;
  final Function() onUpdateStep;
  final Function() onExport;
  final Function() onPrint;
  final ProjectModel projectModel;
  final Size screenSize;
  const BodyFinish({
    super.key,
    required this.projectModel,
    required this.screenSize,
    required this.currentStep,
    required this.onUpdateStep,
    required this.onPrint,
    required this.onExport,
  });
  @override
  State<BodyFinish> createState() => _BodyFinishState();
}

class _BodyFinishState extends State<BodyFinish> {
  late Size _frameSize;
  // double _valueSlider = 300;
  @override
  void initState() {
    super.initState();
    _initFrameSize();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await MyMethodChannel.showPopupReview();
    });
  }

  void _initFrameSize() {
    final initFrame = widget.screenSize.height <= MIN_SIZE.height
        ? const Size(220, 220)
        : const Size(280, 280);
    double newWidth = initFrame.width, newHeight = initFrame.height;
    final currentPassport = widget.projectModel.countryModel!.currentPassport;
    double frameWidth = currentPassport.width;
    double frameHeight = currentPassport.height;
    final ratioWH = frameWidth / frameHeight;
    if (frameHeight != 0) {
      if (ratioWH > 1) {
        // w > h
        newHeight = newHeight * (1 / ratioWH);
      } else if (ratioWH < 1) {
        // w < h
        newWidth = newWidth * ratioWH;
      }
    }
    _frameSize = Size(newWidth, newHeight);
  }

  @override
  Widget build(BuildContext context) {
    consolelog("_frameSize: ${_frameSize}");
    final bool isDarkMode = BlocProvider.of<ThemeBloc>(
      context,
      listen: true,
    ).isDarkMode;
    bool isPhone = BlocProvider.of<DevicePlatformCubit>(
      context,
      listen: false,
    ).isPhone;
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? blockDark : blockLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WTextContent(
                      value: "Your photo is ready!",
                      textSize: 14,
                      textLineHeight: 16,
                      textFontWeight: FontWeight.w600,
                      textColor: isDarkMode ? greenColorDark : greenColorLight,
                    ),
                    WSpacer(width: 5),
                    Image.asset("${PATH_PREFIX_ICON}icon_tick.png", height: 20),
                  ],
                ),
              ),
              Container(
                width: _frameSize.width,
                height: _frameSize.height,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: grey.withValues(alpha: 0.25),
                    width: 0.3,
                  ),
                ),
                child: widget.projectModel.croppedFile != null
                    ? Image.memory(
                        width: _frameSize.width,
                        height: _frameSize.height,
                        widget.projectModel.croppedFile!.readAsBytesSync(),
                        fit: BoxFit.fill,
                        frameBuilder: (context, child, frame, _) {
                          return child;
                        },
                      )
                    : RawImage(
                        fit: BoxFit.fill,
                        width: _frameSize.width,
                        height: _frameSize.height,
                        image: (widget.projectModel.uiImageAdjusted!),
                      ),
              ),
              const SizedBox(),
            ],
          ),
        ),
        WFooter(
          projectModel: widget.projectModel,
          currentStep: widget.currentStep,
          isDarkMode: isDarkMode,
          onNext: () {},
          onExport: widget.onExport,
          onPrint: widget.onPrint,
          footerHeight: isPhone ? null : 166,
          isHaveSettingButton: isPhone ? true : false,
        ),
      ],
    );
  }
}
