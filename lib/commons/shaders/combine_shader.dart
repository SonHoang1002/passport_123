import 'package:flutter_image_filters/flutter_image_filters.dart';
import 'package:passport_photo_2/commons/shaders/custom_constrast_shader.dart';
import 'package:passport_photo_2/commons/shaders/custom_exposure_shader.dart';
import 'package:passport_photo_2/commons/shaders/custom_highlight_shader.dart';
import 'package:passport_photo_2/commons/shaders/custom_saturation_shader.dart';
import 'package:passport_photo_2/commons/shaders/custom_shadow_shader.dart';
import 'package:passport_photo_2/commons/shaders/custom_sharpen_shader.dart';
import 'package:passport_photo_2/helpers/convert.dart';
import 'package:passport_photo_2/helpers/log_custom.dart';

class CombineShaderCustomConfiguration extends BunchShaderConfiguration {
  CombineShaderCustomConfiguration()
      : super([
          CustomExposureShaderConfiguration(),
          CustomContrastShaderConfiguration(),
          CustomSaturationShaderConfiguration(),
          CustomShadowShaderConfiguration(),
          CustomHighlightShaderConfiguration(),
          // CustomHighlightShadowShaderConfiguration(),
          WhiteBalanceShaderConfiguration2(),
          CustomSharpenShaderConfiguration(),
        ]);
  CustomExposureShaderConfiguration get _exposure =>
      configuration(at: 0) as CustomExposureShaderConfiguration;
  CustomContrastShaderConfiguration get _contrast =>
      configuration(at: 1) as CustomContrastShaderConfiguration;
  CustomSaturationShaderConfiguration get _saturation =>
      configuration(at: 2) as CustomSaturationShaderConfiguration;
  CustomShadowShaderConfiguration get _shadow =>
      configuration(at: 3) as CustomShadowShaderConfiguration;
  CustomHighlightShaderConfiguration get _highlight =>
      configuration(at: 4) as CustomHighlightShaderConfiguration;
  WhiteBalanceShaderConfiguration2 get _whiteBalance =>
      configuration(at: 5) as WhiteBalanceShaderConfiguration2;
  CustomSharpenShaderConfiguration get _sharpen =>
      configuration(at: 6) as CustomSharpenShaderConfiguration;

  CustomContrastShaderConfiguration get shaderContrast => _contrast;
  CustomExposureShaderConfiguration get shaderExposure => _exposure;
  CustomSaturationShaderConfiguration get shaderSaturation => _saturation;
  CustomShadowShaderConfiguration get shaderShadow => _shadow;
  CustomHighlightShaderConfiguration get shaderHighlight => _highlight;
  WhiteBalanceShaderConfiguration2 get shaderWhiteBalance => _whiteBalance;
  // CustomWhiteBalanceShaderConfiguration get shaderWhiteBalance => _whiteBalance;
  CustomSharpenShaderConfiguration get shaderSharpen => _sharpen;

  double get contrast => _contrast.contrast;
  double get saturation => _saturation.saturation;
  double get shadow => _shadow.shadows;
  double get highlight => _highlight.highlights;
  double get temperature => _whiteBalance.numUniforms.first;
  double get tint => _whiteBalance.numUniforms.last;
  double get sharpen => _sharpen.sharpen;
  double get exposure => _exposure.exposure;

  set contrast(double value) {
    consolelog("CombineShaderCustomConfiguration: contrast = $contrast");
    _contrast.contrast = value;
    // _contrast.update();
    // update();
  }

  set exposure(double value) {
    consolelog("CombineShaderCustomConfiguration: exposure = $exposure");
    _exposure.exposure = value;
    // _exposure.update();
    // update();
  }

  set saturation(double value) {
    consolelog("CombineShaderCustomConfiguration: saturation = $saturation");
    _saturation.saturation = value;
    // _saturation.update();
    // update();
  }

  set highlight(double highlight) {
    consolelog("CombineShaderCustomConfiguration: highlight = $highlight");
    _highlight.highlights = highlight;
    // _highlightShadow.update();
    // update();
  }

  set shadow(double shadow) {
    consolelog("CombineShaderCustomConfiguration: shadow = $shadow");
    _shadow.shadows = shadow;
    // _highlightShadow.update();
    // update();
  }

  set temperature(double temperature) {
    consolelog("CombineShaderCustomConfiguration: temperature = $temperature");
    _whiteBalance.temperature = temperature;
    // _whiteBalance.update();
    // update();
  }

  set tint(double tint) {
    consolelog("CombineShaderCustomConfiguration: tint = $tint");
    _whiteBalance.tint = tint;
    // _whiteBalance.update();
    // update();
  }

  set sharpen(double sharpen) {
    consolelog("CombineShaderCustomConfiguration: sharpen = $sharpen");
    _sharpen.sharpen = sharpen;
    // _sharpen.update();
    // update();
  }

  void updateValues(List<double> listValue) {
    exposure = (listValue[0]);
    contrast =
        FlutterConvert.convertMappingRange(listValue[1], -0.5, 0.5, 0, 2);
    saturation =
        FlutterConvert.convertMappingRange(listValue[2], -0.5, 0.5, 0, 2);
    shadow = listValue[3];
    highlight =
        FlutterConvert.convertMappingRange(listValue[4], 0, 1, 0, 1) + 1;
    double newTemp =
        FlutterConvert.convertMappingRange(listValue[5], -0.5, 0.5, -1, 1);
    temperature = newTemp;
    tint = newTemp;
    sharpen = listValue[6];
    consolelog(
        "CombineShaderCustomConfiguration: updateValues: $newTemp, listValue[5] = ${listValue[5]}");
    update();
  }

  void initValues() {
    exposure = 0.0;
    contrast = 0.0;
    saturation = 1.0;
    shadow = 0.0;
    highlight = 1.0;
    temperature = 0.0;
    tint = 0.0;
    sharpen = 0.0;
    update();
  }

  Map<String, dynamic> get getValues => {
        "contrast": contrast,
        "exposure": exposure,
        "saturation": saturation,
        "temperature": temperature,
        "tint": tint,
        "highlight": highlight,
        "shadow": shadow,
        "sharpen": sharpen,
      };

  CombineShaderCustomConfiguration copyWith(
    List<double> listValueForShader,
  ) {
    return CombineShaderCustomConfiguration()
      ..exposure = (listValueForShader[0])
      ..contrast = FlutterConvert.convertMappingRange(
          listValueForShader[1], -0.5, 0.5, 0, 2)
      ..saturation = FlutterConvert.convertMappingRange(
          listValueForShader[2], -0.5, 0.5, 0, 2)
      ..shadow = listValueForShader[3]
      ..highlight = FlutterConvert.convertMappingRange(
              listValueForShader[4], 0, 1, 0, 1) +
          1
      ..temperature = FlutterConvert.convertMappingRange(
          listValueForShader[5], -0.5, 0.5, -1, 1)
      ..tint = FlutterConvert.convertMappingRange(
          listValueForShader[5], -0.5, 0.5, -1, 1)
      ..sharpen = listValueForShader[6];
  }

  void log() {
    consolelog("CombineShaderCustomConfiguration log: $getValues");
  }
}
