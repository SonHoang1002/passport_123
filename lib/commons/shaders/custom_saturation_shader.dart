import 'package:flutter_gpu_filters_interface/flutter_gpu_filters_interface.dart';
import 'package:flutter_image_filters/flutter_image_filters.dart';
import 'package:passport_photo_2/helpers/log_custom.dart';

/// Describes saturation manipulations
class CustomSaturationShaderConfiguration extends ShaderConfiguration {
  final NumberParameter _saturation;

  CustomSaturationShaderConfiguration()
      : _saturation = ShaderRangeNumberParameter(
          'inputSaturation',
          'saturation',
          1.0,
          0,
          min: 0,
          max: 2,
        ),
        super([1.0]);

  /// Updates the [saturation] value.
  ///
  /// The [value] must be in 0.0 and 2.0 range.
  set saturation(double value) {
    consolelog("CustomExposureShaderConfiguration saturation = $value");

    _saturation.value = value;
    _saturation.update(this);
  }
  
  double get saturation => _saturation.value as double;

  @override
  List<ConfigurationParameter> get parameters => [_saturation];
}
