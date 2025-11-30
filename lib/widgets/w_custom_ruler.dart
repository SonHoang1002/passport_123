import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pass1_/helpers/adjust_helper.dart';

class WRulerCustom extends StatefulWidget {
  final Color color;
  final double instructionRatioValue;
  final double currentRatioValue;
  final int dividers;
  final Function(double newRatio) onValueChange;
  final Function(double value)? onEnd;
  final Color? checkPointColor;
  const WRulerCustom({
    super.key,
    required this.color,
    required this.instructionRatioValue,
    required this.currentRatioValue,
    required this.dividers,
    required this.onValueChange,
    this.onEnd,
    this.checkPointColor,
  });

  @override
  State<WRulerCustom> createState() => _WRulerCustomState();
}

class _WRulerCustomState extends State<WRulerCustom> {
  late Size _size;
  late ScrollController scrollController;
  bool? _isScrollIncrease;
  late double _currentRatioValue;
  // late bool _isScrollEnd;
  bool _isSnapping = false;
  late double _currentPosition;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    scrollController.addListener(_checkScrollDirection);
    _currentRatioValue = widget.currentRatioValue;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _jumpToNewRatio();
      setState(() {});
    });
  }

  void _checkScrollDirection() {
    ScrollPosition position = scrollController.position;
    // Kiểm tra chiều cuộn
    if (position.userScrollDirection == ScrollDirection.forward) {
      _isScrollIncrease = false;
    } else if (position.userScrollDirection == ScrollDirection.reverse) {
      _isScrollIncrease = true;
    } else {
      _isScrollIncrease = null;
    }
    setState(() {});
  }

  void _onValueChange(double newPosition) {
    final sliderWidth = widget.dividers * 10 / 2;
    final newRatio = newPosition / sliderWidth;
    _currentRatioValue = newRatio;
    widget.onValueChange(newRatio);
  }

  Future<bool> _snap(double currentPosition) async {
    double newPosition = currentPosition;
    int division = 50;
    if (_isScrollIncrease != null) {
      if (_isScrollIncrease!) {
        int checkSnapNumber =
            AdjustHelpers.getNearestNumberAndDivisibleTargetNumber(
              currentPosition,
              division,
              isGreatThan: _isScrollIncrease! == true,
            );

        if ((checkSnapNumber.toDouble() - currentPosition).abs() < 3) {
          newPosition = max(checkSnapNumber.toDouble(), currentPosition);
          scrollController.position.correctPixels(newPosition);
          _isSnapping = true;
          Future.delayed(const Duration(milliseconds: 500), () {
            _isSnapping = false;
          });
        }
      } else {
        int checkSnapNumber =
            AdjustHelpers.getNearestNumberAndDivisibleTargetNumber(
              currentPosition,
              division,
              isGreatThan: false,
            );
        if ((currentPosition - checkSnapNumber.toDouble()).abs() < 3) {
          newPosition = min(checkSnapNumber.toDouble(), currentPosition);
          scrollController.position.correctPixels(newPosition);
          _isSnapping = true;
          Future.delayed(const Duration(milliseconds: 500), () {
            _isSnapping = false;
          });
        }
      }
    }
    _onValueChange(newPosition);

    return true;
  }

  /// use to change subject
  void _jumpToNewRatio() {
    scrollController.jumpTo(
      widget.currentRatioValue * widget.dividers * 10 / 2,
    );
  }

  int lastMilli = DateTime.now().millisecondsSinceEpoch;
  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.sizeOf(context);
    if (_currentRatioValue != widget.currentRatioValue) {
      _jumpToNewRatio();
    }

    Color overlayColor = Theme.of(context).scaffoldBackgroundColor;
    double _mainWidth = min(_size.width, 411.4);
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Listener(
            onPointerDown: (event) {
              FocusScope.of(context).requestFocus(FocusNode());
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                final now = DateTime.now();
                final timeDiff = now.millisecondsSinceEpoch - lastMilli;

                lastMilli = DateTime.now().millisecondsSinceEpoch;

                if (scrollNotification is ScrollEndNotification) {
                  lastMilli = DateTime.now().millisecondsSinceEpoch;
                }

                if (scrollNotification is ScrollStartNotification) {
                } else if (scrollNotification is ScrollUpdateNotification) {
                  final pixelsPerMilli =
                      scrollNotification.scrollDelta! / timeDiff;
                  lastMilli = DateTime.now().millisecondsSinceEpoch;
                  if (_isSnapping) {
                    if (pixelsPerMilli.abs() > 0.3) {
                      _currentPosition = scrollNotification.metrics.pixels;
                      _snap(scrollNotification.metrics.pixels);
                    } else {
                      scrollController.position.setPixels(_currentPosition);
                    }
                  } else {
                    _currentPosition = scrollNotification.metrics.pixels;
                    _snap(scrollNotification.metrics.pixels);
                  }
                  return true;
                } else if (scrollNotification is ScrollEndNotification) {
                  widget.onEnd != null
                      ? widget.onEnd!(scrollNotification.metrics.pixels)
                      : null;
                }
                return true;
              },
              child: SizedBox(
                height: 40,
                width: _mainWidth,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      colors: [
                        overlayColor.withValues(alpha: 0),
                        overlayColor.withValues(alpha: 0.8),
                        overlayColor,
                        overlayColor.withValues(alpha: 0.8),
                        overlayColor.withValues(alpha: 0),
                      ],
                    ).createShader(bounds);
                  },
                  child: ListView.builder(
                    controller: scrollController,
                    padding: EdgeInsets.only(
                      left: _mainWidth / 2 - 24.5, // 500 / 2 - 75,
                      right: _mainWidth / 2 - 4.5, // 500 / 2 - 4.5,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.dividers + 1,
                    itemBuilder: (BuildContext context, int index) {
                      return (index % 2 == 0)
                          ? Container(
                              padding: index == 0
                                  ? const EdgeInsets.only(left: 20)
                                  : EdgeInsets.zero,
                              child: SizedBox(
                                width: 10,
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: <Widget>[
                                    Container(
                                      width:
                                          index ==
                                              widget.instructionRatioValue *
                                                  widget.dividers
                                          ? 2
                                          : 1,
                                      height: index % 10 == 0
                                          ? index ==
                                                    widget.instructionRatioValue *
                                                        widget.dividers
                                                ? 20
                                                : 15
                                          : 10,
                                      color: index % 10 == 0
                                          ? widget.color
                                          : widget.color.withValues(alpha: 0.5),
                                    ),
                                    _buildCheckPoint(index),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox();
                    },
                  ),
                ),
              ),
            ),
          ),
          // check needle - Kim
          SizedBox(
            width: 5,
            height: 20,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  width: 3,
                  color:
                      widget.checkPointColor ??
                      Colors.orange.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckPoint(int index) {
    return Positioned.fill(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity:
            (index == widget.instructionRatioValue * widget.dividers &&
                widget.currentRatioValue != widget.instructionRatioValue)
            ? 1
            : 0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              alignment: Alignment.topCenter,
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(),
          ],
        ),
      ),
    );
  }
}
