import 'package:flutter_gpu_filters_interface/flutter_gpu_filters_interface.dart';
import 'package:flutter_image_filters/flutter_image_filters.dart';
import 'package:pass1_/helpers/log_custom.dart';

class CustomContrastShaderConfiguration extends ShaderConfiguration {
  final NumberParameter _contrast;

  CustomContrastShaderConfiguration()
    : _contrast = ShaderRangeNumberParameter(
        'inputContrast',
        'contrast',
        1.0,
        0,
        min: 0.0,
        max: 2.0,
      ),
      super([1.0]);

  set contrast(double value) {
    consolelog("CustomContrastShaderConfiguration contrast: $value");
    _contrast.value = value;
    _contrast.update(this);
  }

  double get contrast => _contrast.value as double;

  CustomContrastShaderConfiguration copyWith({double? contrast}) {
    return CustomContrastShaderConfiguration()
      ..contrast = contrast ?? this.contrast;
  }

  @override
  List<ConfigurationParameter> get parameters => [_contrast];
}
