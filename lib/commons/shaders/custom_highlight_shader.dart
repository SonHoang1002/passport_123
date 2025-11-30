import 'package:flutter_gpu_filters_interface/flutter_gpu_filters_interface.dart';
import 'package:flutter_image_filters/flutter_image_filters.dart';
import 'package:pass1_/helpers/log_custom.dart';

/// Describes highlight shadow manipulations
class CustomHighlightShaderConfiguration extends ShaderConfiguration {
  final NumberParameter _highlights;

  CustomHighlightShaderConfiguration()
    : _highlights = ShaderRangeNumberParameter(
        'inputHighlights',
        'highlights',
        1.0,
        0,
        min: 0.0,
        max: 1.0,
      ),
      super([0.0]);

  /// Updates the [highlights] value.
  ///
  /// The [value] must be in 0.0 and 1.0 range.
  set highlights(double value) {
    consolelog("CustomHighlightShaderConfiguration highlights: ${value}");
    _highlights.value = value;
    _highlights.update(this);
  }

  double get highlights => _highlights.value as double;

  @override
  List<ConfigurationParameter> get parameters => [_highlights];
}
