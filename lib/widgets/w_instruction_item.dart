import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/models/instruction_model.dart';
import 'package:pass1_/providers/blocs/theme_bloc.dart';
import 'package:pass1_/widgets/w_spacer.dart';
import 'package:pass1_/widgets/w_text.dart';

class InstructionItem extends StatelessWidget {
  final int index;
  final InstructionModel model;
  final MainAxisAlignment mainAxisAlignment;
  const InstructionItem({
    super.key,
    required this.index,
    required this.model,
    this.mainAxisAlignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = BlocProvider.of<ThemeBloc>(
      context,
      listen: true,
    ).isDarkMode;
    final _size = MediaQuery.sizeOf(context);
    return Column(
      children: [
        // title
        Row(
          mainAxisAlignment: mainAxisAlignment,
          children: [
            Container(
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).textTheme.displayLarge!.color,
              ),
              alignment: Alignment.center,
              child: WTextContent(
                value: (index + 1).toString(),
                textSize: 12,
                textLineHeight: 14.32,
                textColor: Theme.of(context).textTheme.titleLarge!.color,
              ),
            ),
            WSpacer(width: 10),
            FittedBox(
              child: AutoSizeText(
                model.title,
                maxFontSize: _size.height > MIN_SIZE.height ? 15 : 12,
                minFontSize: 8,
                style: TextStyle(
                  height: 17.9 / 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: FONT_GOOGLESANS,
                  color: Theme.of(context).textTheme.displayLarge!.color,
                ),
              ),
            ),
          ],
        ),
        WSpacer(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 210,
              width: 155,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 155,
                    width: 155,
                    child: Image.asset(
                      model.pathImageOrigin,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(
                    height: 32,
                    width: 52,
                    child: Image.asset(
                      PATH_PREFIX_ICON + "icon_instruction_origin.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
            WSpacer(width: 20),
            Container(
              height: 210,
              width: 155,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 155,
                    width: 155,
                    child: Image.asset(model.pathImageDone, fit: BoxFit.cover),
                  ),
                  SizedBox(
                    height: 32,
                    width: 52,
                    child: Image.asset(
                      PATH_PREFIX_ICON +
                          (isDarkMode
                              ? "icon_instruction_done_dark.png"
                              : "icon_instruction_done_light.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
