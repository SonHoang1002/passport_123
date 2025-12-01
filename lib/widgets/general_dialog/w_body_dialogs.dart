import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/helpers/navigator_route.dart';
import 'package:pass1_/widgets/w_divider.dart';
import 'package:pass1_/widgets/w_text.dart';

class BodyDialogCustom extends StatefulWidget {
  final Offset offset;
  final Widget dialogWidget;
  final Alignment scaleAlignment;
  final Function()? onTapBackground;
  final Curve curve;
  final int animDurationInMs;
  const BodyDialogCustom({
    super.key,
    required this.offset,
    required this.dialogWidget,
    this.scaleAlignment = Alignment.center,
    this.onTapBackground,
    this.curve = CUBIC_CURVE,
    this.animDurationInMs = 200,
  });

  @override
  State<BodyDialogCustom> createState() => _BodyDialogCustomState();
}

class _BodyDialogCustomState extends State<BodyDialogCustom>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> scaleAnimation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.animDurationInMs),
    );
    scaleAnimation = CurvedAnimation(parent: controller, curve: widget.curve);
    controller.addListener(() {
      setState(() {});
    });
    controller.forward();
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
    scaleAnimation.removeListener(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                controller.reverse().then((_) {
                  if (widget.onTapBackground != null) {
                    widget.onTapBackground!();
                  } else {
                    popNavigator(context);
                  }
                });
              },
              child: Container(color: const Color.fromRGBO(0, 0, 0, 0.03)),
            ),
          ),
          Positioned(
            top: widget.offset.dy + 50,
            left: widget.offset.dx,
            child: ScaleTransition(
              scale: scaleAnimation,
              alignment: widget.scaleAlignment,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      child: widget.dialogWidget,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: black015,
                            spreadRadius: 0,
                            blurRadius: 60,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                      child: widget.dialogWidget,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: must_be_immutable
class DialogBody extends StatefulWidget {
  final List<String> listItem;
  final Function(String value) onSelected;
  String? selectedValue; // dung de check mau text
  Color? selectedTextColor; // ket hop voi [valueSelected] de check mau
  double dialogWidth;
  Color? backgroundColor;
  Color? textColor;
  String? title;
  List<Widget>? itemReplaceWidgets;
  List<String>? listMediaString;
  List<BoxShadow>? boxShadows;
  double itemHeight;
  double titleHeight;
  Widget? selectedWidget;
  bool textAlignCenter;
  double? maxHeight;

  DialogBody({
    super.key,
    this.dialogWidth = 312,
    required this.listItem,
    required this.onSelected,
    this.selectedValue,
    this.selectedTextColor,
    this.backgroundColor,
    this.textColor,
    this.title,
    this.itemReplaceWidgets,
    this.listMediaString,
    this.boxShadows,
    this.itemHeight = 44,
    this.textAlignCenter = false,
    this.titleHeight = 44,
    this.selectedWidget,
    this.maxHeight,
  });

  @override
  State<DialogBody> createState() => _DialogBodyState();
}

class _DialogBodyState extends State<DialogBody> {
  double dividerHeight = 0.5;
  late double heightOfContent;
  late bool isCanScroll;
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.sizeOf(context);

    int itemLength = widget.listItem.length;

    double heightOfDialog = itemLength * widget.itemHeight;

    double sumOfDividers = (itemLength - 1) * dividerHeight;
    double _maxHeight = widget.maxHeight ?? size.height * 0.45;

    if (heightOfDialog >= _maxHeight) {
      heightOfContent = _maxHeight + sumOfDividers;
      isCanScroll = true;
    } else {
      heightOfContent = itemLength * widget.itemHeight + sumOfDividers;
      isCanScroll = false;
    }

    return Container(
      width: widget.dialogWidth,
      decoration: BoxDecoration(
        color:
            widget.backgroundColor ?? Theme.of(context).dialogBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow:
            widget.boxShadows ??
            const [
              BoxShadow(
                blurRadius: 60,
                spreadRadius: 0,
                offset: Offset(0, 0),
                color: black015,
              ),
            ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // body
              widget.itemReplaceWidgets != null
                  ? Container(
                      margin: EdgeInsets.zero,
                      child: Column(children: widget.itemReplaceWidgets!),
                    )
                  : SizedBox(
                      height: heightOfContent,
                      child: SingleChildScrollView(
                        physics: isCanScroll
                            ? null
                            : const NeverScrollableScrollPhysics(),
                        child: Column(
                          children: widget.listItem.indexed.map((e) {
                            int index = e.$1;
                            return GestureDetector(
                              onTap: () {
                                widget.onSelected(e.$2);
                              },
                              child: Container(
                                color: transparent,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const SizedBox(),
                                    Container(
                                      constraints: BoxConstraints(
                                        maxWidth: widget.dialogWidth * 0.8,
                                      ),
                                      alignment: Alignment.centerLeft,
                                      height: widget.itemHeight,
                                      child: Row(
                                        mainAxisAlignment:
                                            widget.textAlignCenter == false
                                            ? MainAxisAlignment.spaceBetween
                                            : MainAxisAlignment.center,
                                        children: [
                                          WTextContent(
                                            value: e.$2,
                                            textSize: 12,
                                            textLineHeight: 15,
                                            textFontWeight: FontWeight.w500,
                                            textOverflow: TextOverflow.ellipsis,
                                            textMaxLength: 2,
                                            textColor: widget.selectedValue == e
                                                ? widget.selectedTextColor
                                                : widget.textColor,
                                          ),
                                          if (widget.listMediaString != null)
                                            Image.asset(
                                              widget.listMediaString![index],
                                              height: 20,
                                              width: 20,
                                              color: Theme.of(
                                                context,
                                              ).iconTheme.color,
                                              // isDarkMode ? white07 : black07,
                                            ),
                                          if (widget.selectedValue == e)
                                            widget.selectedWidget ??
                                                const SizedBox(),
                                        ],
                                      ),
                                    ),
                                    (index != widget.listItem.length - 1)
                                        ? WDivider(
                                            width: widget.dialogWidth,
                                            color: Theme.of(
                                              context,
                                            ).dividerTheme.color,
                                            height: dividerHeight,
                                          )
                                        : const SizedBox(),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

class CustomDialogBody extends StatefulWidget {
  final Offset offset;
  final Widget dialogWidget;
  final Alignment scaleAlignment;
  final Function()? onTapBackground;
  const CustomDialogBody({
    super.key,
    required this.offset,
    required this.dialogWidget,
    this.scaleAlignment = Alignment.center,
    this.onTapBackground,
  });

  @override
  State<CustomDialogBody> createState() => _CustomDialogBodyState();
}

class _CustomDialogBodyState extends State<CustomDialogBody>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> scaleAnimation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    scaleAnimation = CurvedAnimation(parent: controller, curve: CUBIC_CURVE);
    controller.addListener(() {
      setState(() {});
    });
    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    scaleAnimation.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                controller.reverse().then((_) {
                  if (widget.onTapBackground != null) {
                    widget.onTapBackground!();
                  } else {
                    popNavigator(context);
                  }
                });
              },
              child: Container(color: const Color.fromRGBO(0, 0, 0, 0.03)),
            ),
          ),
          Positioned(
            top: widget.offset.dy + 50,
            left: widget.offset.dx,
            child: ScaleTransition(
              scale: scaleAnimation,
              alignment: widget.scaleAlignment,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      child: widget.dialogWidget,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            spreadRadius: 0,
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: widget.dialogWidget,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
