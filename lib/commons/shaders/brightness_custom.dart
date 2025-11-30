import 'package:flutter_gpu_filters_interface/flutter_gpu_filters_interface.dart';
import 'package:flutter_image_filters/flutter_image_filters.dart';
import 'package:pass1_/helpers/log_custom.dart';

class CustomBrightnessShaderConfiguration extends ShaderConfiguration {
  final NumberParameter _brightness;

  CustomBrightnessShaderConfiguration()
    : _brightness = ShaderRangeNumberParameter(
        'inputBrightness',
        'brightness',
        0.0,
        0,
        min: -1,
        max: 1,
      ),
      super([0.0]);

  /// Updates the [brightness] value.
  ///
  /// The [value] must be in -1.0 and 1.0 range.
  set brightness(double value) {
    consolelog("brightnessbrightness call = $value");
    _brightness.value = value;
    _brightness.update(this);
  }

  double get getBrightness => _brightness.value as double;

  @override
  List<ConfigurationParameter> get parameters => [_brightness];
}
