import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/models/instruction_model.dart';
import 'package:pass1_/providers/blocs/theme_bloc.dart';

class WCarouselIndicator extends StatelessWidget {
  final List<InstructionModel> listInstructionModel;
  final int currentIndex;
  const WCarouselIndicator({
    super.key,
    required this.currentIndex,
    required this.listInstructionModel,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = BlocProvider.of<ThemeBloc>(
      context,
      listen: true,
    ).isDarkMode;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: listInstructionModel.indexed.map((e) {
        final index = e.$1;
        return _buildDot(
          index == currentIndex ? blue : (isDarkMode ? white015 : black015),
        );
      }).toList(),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      height: 10,
      width: 10,
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
