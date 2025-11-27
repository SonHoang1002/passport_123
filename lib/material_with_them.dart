import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passport_photo_2/commons/themes.dart';
import 'package:passport_photo_2/providers/blocs/theme_bloc.dart';
import 'package:passport_photo_2/providers/states/theme_state.dart';
import 'package:passport_photo_2/screens/module_home/home.dart';
import 'package:passport_photo_2/screens/module_onboard/onboard.dart';

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
    Widget homeWidget =
        (widget.isOnBoard) ? const OnBoardPage() : const HomePageMain();
    // homeWidget = const TestSharpenWidget();
    return BlocBuilder<ThemeBloc, ThemeState>(builder: (context, theme) {
      return MaterialApp(
        title: 'Image Converter',
        theme: MyThemes.lightTheme,
        darkTheme: MyThemes.darkTheme,
        debugShowCheckedModeBanner: false,
        themeMode: theme.themeMode,
        home: homeWidget,
      );
    });
  }
}
