import 'package:flutter_gpu_filters_interface/flutter_gpu_filters_interface.dart';
import 'package:flutter_image_filters/flutter_image_filters.dart';
import 'package:passport_photo_2/helpers/log_custom.dart';

/// Describes highlight shadow manipulations
class CustomShadowShaderConfiguration extends ShaderConfiguration {
  final NumberParameter _shadows;

  CustomShadowShaderConfiguration()
      : _shadows = ShaderRangeNumberParameter(
          'inputShadows',
          'shadows',
          0.0,
          0,
          min: 0.0,
          max: 1.0,
        ),
        super([0.0]);

  /// Updates the [shadows] value.
  ///
  /// The [value] must be in 0.0 and 1.0 range.
  set shadows(double value) {
    consolelog("CustomShadowShaderConfiguration shadows: ${value}");
    _shadows.value = value;
    _shadows.update(this);
  }

  double get shadows => _shadows.value as double;
  @override
  List<ConfigurationParameter> get parameters => [_shadows];
}
