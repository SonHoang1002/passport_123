// import 'package:flutter_gpu_filters_interface/flutter_gpu_filters_interface.dart';
// import 'package:flutter_image_filters/flutter_image_filters.dart';
// import 'package:pass1_/helpers/log_custom.dart';

// /// Describes brightness manipulations
// class BrightnessBackgroundShaderConfiguration extends ShaderConfiguration {
//   final NumberParameter _brightness;

//   BrightnessBackgroundShaderConfiguration()
//       : _brightness = ShaderRangeNumberParameter(
//           'inputBrightness',
//           'brightness',
//           0.0001,
//           0,
//           min: 0.0001,
//           max: 0.9999,
//         ),
//         super([0.0]);

//   set brightness(double value) {
//     consolelog("brightness update: ${value}");
//     _brightness.value = value;
//     _brightness.update(this);
//   }

//   @override
//   List<ConfigurationParameter> get parameters => [_brightness];
// }
