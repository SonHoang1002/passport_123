// import 'dart:ui';
// import 'package:flutter_gpu_filters_interface/flutter_gpu_filters_interface.dart';
// import 'package:flutter_image_filters/flutter_image_filters.dart';

// class FillColorConfiguration extends ShaderConfiguration {
//   ColorParameter _color;

//   FillColorConfiguration()
//       : _color = ShaderColorParameter(
//           'inputColor',
//           'color',
//           Color.fromRGBO(0, 0, (0.5 * 255).toInt(), 1.0),
//           0,
//         ),
//         super([0.0, 0.0, 0.5]);

//   set color(Color value) {
//     _color.value = value;
//     _color.update(this);
//   }

//   @override
//   List<ConfigurationParameter> get parameters => [_color];
// }
