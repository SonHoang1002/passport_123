import 'package:flutter/material.dart';
import 'package:passport_photo_2/commons/colors.dart';

class CustomLoadingIndicator extends StatelessWidget {
  const CustomLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: blue,
        strokeWidth: 6.5,
        strokeCap: StrokeCap.round,
      ),
    );
  }
}
