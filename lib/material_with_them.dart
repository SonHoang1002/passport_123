import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass1_/a_test/test_rotate_crop.dart';
import 'package:pass1_/commons/themes.dart';
import 'package:pass1_/providers/blocs/theme_bloc.dart';
import 'package:pass1_/providers/states/theme_state.dart';
import 'package:pass1_/screens/module_home/home.dart';
import 'package:pass1_/screens/module_onboard/onboard.dart';

class MaterialWithTheme extends StatefulWidget {
  final bool isOnBoard;
  const MaterialWithTheme({super.key, required this.isOnBoard});

  @override
  State<MaterialWithTheme> createState() => _MaterialWithThemeState();
}

class _MaterialWithThemeState extends State<MaterialWithTheme> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget homeWidget = (widget.isOnBoard)
        ? const OnBoardPage()
        : const HomePageMain();
    // homeWidget = const TestRotateCrop();
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, theme) {
        return MaterialApp(
          title: 'Image Converter',
          theme: MyThemes.lightTheme,
          darkTheme: MyThemes.darkTheme,
          debugShowCheckedModeBanner: false,
          themeMode: theme.themeMode,
          home: homeWidget,
        );
      },
    );
  }
}
