import 'package:flutter_gpu_filters_interface/flutter_gpu_filters_interface.dart';
import 'package:flutter_image_filters/flutter_image_filters.dart';
import 'package:passport_photo_2/helpers/log_custom.dart';

class CustomSharpenShaderConfiguration extends ShaderConfiguration {
  final NumberParameter _sharpen;

  CustomSharpenShaderConfiguration()
      : _sharpen = ShaderRangeNumberParameter(
          'inputSharpen', // uniform name
          'sharpen', // display name
          0.0,
          0, // default value
          min: -4, // minimum value
          max: 4, // maximum value
        ),
        super([0.0]); // default values

  // custom setter (optional)
  set sharpen(double value) {
    consolelog("CustomSharpenShaderConfiguration sharpen value: ${value}");
    _sharpen.value = value;
    _sharpen.update(this);
  }

  double get sharpen => _sharpen.value as double;

  CustomSharpenShaderConfiguration copyWith({
    double? sharpen,
  }) {
    return CustomSharpenShaderConfiguration()
      ..sharpen = sharpen ?? this.sharpen;
  }

  @override
  List<ConfigurationParameter> get parameters => [_sharpen];
}
