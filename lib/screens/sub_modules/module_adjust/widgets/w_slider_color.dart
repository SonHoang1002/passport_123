import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passport_photo_2/commons/colors.dart';
import 'package:passport_photo_2/providers/blocs/theme_bloc.dart';

class SliderColor extends StatelessWidget {
  final double dotSize;
  final List<Color> listGradientColor;
  final double sliderWidth;
  final Offset offsetTracker;
  const SliderColor({
    super.key,
    required this.dotSize,
    required this.listGradientColor,
    required this.offsetTracker,
    required this.sliderWidth,
  });

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = BlocProvider.of<ThemeBloc>(context).isDarkMode;

    return Container(
      decoration: BoxDecoration(
          border: Border.all(
            color: isDarkMode ? sliderStrokeDark : sliderStrokeLight,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(999)),
      height: dotSize + 4,
      width: sliderWidth,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: listGradientColor,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight),
                borderRadius: BorderRadius.circular(15)),
          ),
          Positioned(
            left: offsetTracker.dx,
            child: Container(
              height: dotSize,
              width: dotSize,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(dotSize / 2),
                  // boxShadow: const [
                  //   BoxShadow(
                  //       color: Color.fromRGBO(0, 0, 0, 0.1),
                  //       offset: Offset(0, 2),
                  //       blurRadius: 10,
                  //       spreadRadius: 0)
                  // ],
                  color: white,
                  border: Border.all(
                      width: 3,
                      color:
                          isDarkMode ? sliderStrokeDark : sliderStrokeLight)),
            ),
          )
        ],
      ),
    );
  }
}
