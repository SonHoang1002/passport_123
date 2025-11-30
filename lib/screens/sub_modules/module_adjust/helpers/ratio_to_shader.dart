import 'package:pass1_/models/adjust_subject_model.dart';

/// Return [
///   convertedExposure * 2,
///   convertedConstrast,
///   convertedSaturation,
///   convertedShadow,
///   convertedHightlight,
///   convertedWarmth,
///   convertedSharpen,
/// ];
List<double> convertRatioToShaderValue(List<AdjustSubjectModel> listSubject) {
  double deltaExposureValue =
      listSubject[0].currentRatioValue - listSubject[0].rootRatioValue;
  double deltaContrastValue =
      listSubject[1].currentRatioValue - listSubject[1].rootRatioValue;
  double deltaSaturationValue =
      listSubject[2].currentRatioValue - listSubject[2].rootRatioValue;
  double deltaShadowValue =
      listSubject[3].currentRatioValue - listSubject[3].rootRatioValue;
  double deltaHighlightValue =
      listSubject[4].currentRatioValue - listSubject[4].rootRatioValue;
  double deltaWarmthValue =
      listSubject[5].currentRatioValue - listSubject[5].rootRatioValue;
  double deltaSharpenValue =
      listSubject[6].currentRatioValue - listSubject[6].rootRatioValue;

  final double convertedExposure = deltaExposureValue;
  double convertedConstrast = deltaContrastValue;
  final double convertedSaturation = deltaSaturationValue;
  final double convertedShadow = deltaShadowValue;
  final double convertedHighlight = deltaHighlightValue;
  final double convertedWarmth = deltaWarmthValue;
  final double convertedSharpen = deltaSharpenValue;
  List<double> listValue = [
    convertedExposure * 2,
    convertedConstrast, //.clamp(-0.45, 0.45),
    convertedSaturation,
    convertedShadow,
    convertedHighlight,
    convertedWarmth,
    convertedSharpen,
  ];
  return listValue;
}
