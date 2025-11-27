import 'package:flutter_image_filters/flutter_image_filters.dart';
import 'package:flutter_gpu_filters_interface/flutter_gpu_filters_interface.dart';
import 'package:passport_photo_2/helpers/log_custom.dart';

class CustomExposureShaderConfiguration extends ShaderConfiguration {
  final NumberParameter _exposure;

  CustomExposureShaderConfiguration()
      : _exposure = ShaderRangeNumberParameter(
          'inputExposure',
          'exposure',
          0.0,
          0,
          min: -10.0,
          max: 10.0,
        ),
        super([0.0]);

  /// Updates the [exposure] value.
  ///
  /// The [value] must be in -10.0 and 10.0 range.
  set exposure(double value) {
    consolelog("CustomExposureShaderConfiguration exposure = $value");
    _exposure.value = value;
    _exposure.update(this);
  }

  double get exposure => _exposure.value as double;

  CustomExposureShaderConfiguration copyWith({
    double? exposure,
  }) {
    return CustomExposureShaderConfiguration()
      ..exposure = exposure ?? this.exposure;
  }

  @override
  List<ConfigurationParameter> get parameters => [_exposure];
}
