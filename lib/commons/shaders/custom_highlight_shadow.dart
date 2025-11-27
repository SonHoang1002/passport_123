// // import 'package:flutter_gpu_filters_interface/flutter_gpu_filters_interface.dart';
// // import 'package:flutter_image_filters/flutter_image_filters.dart';
// // import 'package:passport_photo_2/helpers/log_custom.dart';

// // class CustomHighlightShadowShaderConfiguration extends ShaderConfiguration {
// //   final NumberParameter _shadows;
// //   final NumberParameter _highlights;

// //   CustomHighlightShadowShaderConfiguration()
// //       : _shadows = ShaderRangeNumberParameter(
// //           'inputShadows',
// //           'shadows',
// //           0.0,
// //           0,
// //           min: -1.0,
// //           max: 1.0,
// //         ),
// //         _highlights = ShaderRangeNumberParameter(
// //           'inputHighlights',
// //           'highlights',
// //           0.0,
// //           0,
// //           min: -1.0,
// //           max: 1.0,
// //         ),
// //         super([0.0, 0.0]);

// //   double get highlights => _highlights.value as double;
// //   double get shadows => _shadows.value as double;

// //   set shadows(double value) {
// //     consolelog("CustomHighlightShadowShaderConfiguration shadows: ${value}");
// //     _shadows.value = value;
// //     _shadows.update(this);
// //   }

// //   set highlights(double value) {
// //     consolelog("CustomHighlightShadowShaderConfiguration highlights: ${value}");
// //     _highlights.value = value;
// //     _highlights.update(this);
// //   }

// //   @override
// //   List<ConfigurationParameter> get parameters => [_shadows, _highlights];
// // }

// import 'package:flutter_gpu_filters_interface/flutter_gpu_filters_interface.dart';
// import 'package:flutter_image_filters/flutter_image_filters.dart';
// import 'package:passport_photo_2/helpers/log_custom.dart';

// /// Describes highlight shadow manipulations
// class CustomHighlightShadowShaderConfiguration extends ShaderConfiguration {
//   final NumberParameter _shadows;
//   final NumberParameter _highlights;

//   CustomHighlightShadowShaderConfiguration()
//       : _shadows = ShaderRangeNumberParameter(
//           'inputShadows',
//           'shadows',
//           0.0,
//           0,
//           min: 0.0,
//           max: 1.0,
//         ),
//         _highlights = ShaderRangeNumberParameter(
//           'inputHighlights',
//           'highlights',
//           1.0,
//           0,
//           min: 0.0,
//           max: 1.0,
//         ),
//         super([0.0, 1.0]);

//   /// Updates the [shadows] value.
//   ///
//   /// The [value] must be in 0.0 and 1.0 range.
//   set shadows(double value) {
//     consolelog("CustomHighlightShadowShaderConfiguration shadows: ${value}");
//     _shadows.value = value;
//     _shadows.update(this);
//   }

//   /// Updates the [highlights] value.
//   ///
//   /// The [value] must be in 0.0 and 1.0 range.
//   set highlights(double value) {
//     consolelog("CustomHighlightShadowShaderConfiguration highlights: ${value}");
//     _highlights.value = value;
//     _highlights.update(this);
//   }

//   double get highlights => _highlights.value as double;

//   double get shadows => _shadows.value as double;
//   @override
//   List<ConfigurationParameter> get parameters => [_shadows, _highlights];
// }
