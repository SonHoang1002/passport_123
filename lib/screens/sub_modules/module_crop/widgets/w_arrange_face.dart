import 'package:flutter/material.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/models/project_model.dart';
import 'package:pass1_/widgets/w_dash_line.dart';

class WFaceArrangeComponents extends StatelessWidget {
  final ProjectModel projectModel;
  final Size frameSize;
  final double opacity;
  const WFaceArrangeComponents({
    super.key,
    required this.projectModel,
    required this.frameSize,
    required this.opacity,
  });
  final marginChin = 16.0;

  @override
  Widget build(BuildContext context) {
    final currentPassport = projectModel.countryModel!.currentPassport;
    final offsetHead = Offset(
      0,
      frameSize.height * (1 - currentPassport.ratioHead),
    );
    final offsetEyes = Offset(
      0,
      frameSize.height * (1 - currentPassport.ratioEyes),
    );
    final offsetChin = Offset(
      0,
      frameSize.height * (1 - currentPassport.ratioChin),
    );
    Color mainColor = black; //isDarkMode ? primaryDark1 : primaryLight1;
    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 300),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // head
          Positioned(
            top: offsetHead.dy,
            child: Image.asset(
              "${PATH_PREFIX_ICON}icon_crop_head.png",
              height: 18,
              gaplessPlayback: true,
              width: 100,
              color: mainColor,
            ),
          ),
          // eyes horizontal line
          Positioned(
            top: offsetEyes.dy,
            child: SizedBox(
              width: frameSize.width * 0.8,
              child: WLineDash(color: mainColor.withValues(alpha: 0.4)),
            ),
          ),
          // eyes vertical line
          SizedBox(
            height: frameSize.height,
            child: WLineDash(
              color: mainColor.withValues(alpha: 0.4),
              direction: Axis.vertical,
            ),
          ),
          // chin
          Positioned(
            top: offsetChin.dy - marginChin,
            child: Image.asset(
              "${PATH_PREFIX_ICON}icon_crop_chin.png",
              height: 18,
              width: 100,
              gaplessPlayback: true,
              color: mainColor,
            ),
          ),
          // test preview

          // Positioned(
          //   top: offsetHead.dy,
          //   child: WTextContent(value: "${currentPassport.ratioHead}"),
          // ),
          // Positioned(
          //   top: offsetEyes.dy,
          //   child: WTextContent(value: "${currentPassport.ratioEyes}"),
          // ),
          // Positioned(
          //   top: offsetChin.dy,
          //   child: WTextContent(value: "${currentPassport.ratioChin}"),
          // ),
        ],
      ),
    );
  }
}
