import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/helpers/adjust_helper.dart';
import 'package:pass1_/helpers/contain_offset.dart';
import 'package:pass1_/helpers/log_custom.dart';

class CustomSlider extends StatefulWidget {
  final Color? thumbColor;
  final Color? activeColor;
  final Color? inactiveColor;
  final Function(double percent)? onChanged;
  final Function(double percent)? onChangeEnd;
  final double value;
  final double min;
  final double max;

  const CustomSlider({
    super.key,
    this.thumbColor,
    this.activeColor,
    this.inactiveColor,
    required this.min,
    required this.max,
    required this.value,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  State<CustomSlider> createState() => _CustomSliderState();
}

class _CustomSliderState extends State<CustomSlider> {
  final Size thumbSize = const Size(16, 16);
  late RenderBox _renderBoxSlider;
  late Offset _offsetThumb;
  final GlobalKey _keySlider = GlobalKey(debugLabel: "_keySlider");
  bool _isFocus = false;
  late double _percent;
  bool _isSnaping = false;
  Duration? _lastTime;

  @override
  void initState() {
    super.initState();
    _percent = (widget.value - widget.min) / (widget.max - widget.min);
    _offsetThumb = const Offset(0, 0);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _renderBoxSlider =
          _keySlider.currentContext?.findRenderObject() as RenderBox;
      double mainLength =
          _renderBoxSlider.size.width - thumbSize.width - thumbSize.width / 2;
      double newWidth = _percent * mainLength;
      _offsetThumb = Offset(newWidth, 0);
      setState(() {});
    });
  }

  void _onTapUp(TapUpDetails details, double sliderWidth) {
    if (_isFocus) {
      double mainLength = sliderWidth - thumbSize.width / 2 - thumbSize.width;
      Offset temp = _renderBoxSlider.globalToLocal(
        details.globalPosition.translate(-thumbSize.width, 0),
      );
      _offsetThumb = Offset(
        clampDouble(temp.dx, -thumbSize.width / 2, mainLength),
        temp.dy,
      );
      _percent = clampDouble(_offsetThumb.dx / (mainLength), 0, 1);
      if (widget.onChanged != null) {
        widget.onChanged!((_percent) * (widget.max - widget.min) + widget.min);
      }
      setState(() {});
    }
  }

  void _onPanUpdateWithGlobalPosition(
    DragUpdateDetails details,
    double sliderWidth,
  ) {
    if (_isFocus) {
      bool isPanIncrease = details.delta.dx > 0;
      double mainLength = sliderWidth - thumbSize.width / 2 - thumbSize.width;
      Offset offsetLocalPosition = _renderBoxSlider.globalToLocal(
        details.globalPosition.translate(-thumbSize.width, 0),
      );

      double tempValue =
          clampDouble(offsetLocalPosition.dx / (mainLength), 0, 1) *
              (widget.max - widget.min) +
          widget.min;
      int checkSnapValue =
          AdjustHelpers.getNearestNumberAndDivisibleTargetNumber(
            tempValue,
            50,
            isGreatThan: isPanIncrease,
          );
      double mainValue = tempValue;

      if ((checkSnapValue.toDouble() - tempValue).abs() < 5) {
        mainValue = checkSnapValue.toDouble();
        offsetLocalPosition = Offset(
          (checkSnapValue.toDouble() - widget.min) /
              (widget.max - widget.min) *
              (mainLength),
          offsetLocalPosition.dy,
        );
        _isSnaping = true;
        Future.delayed(const Duration(milliseconds: 300), () {
          _isSnaping = false;
        });
      }
      Offset checkedOffset = Offset(
        clampDouble(offsetLocalPosition.dx, -thumbSize.width / 2, mainLength),
        offsetLocalPosition.dy,
      );
      _offsetThumb = checkedOffset;
      _percent = clampDouble(_offsetThumb.dx / (mainLength), 0, 1);
      if (widget.onChanged != null) {
        widget.onChanged!(mainValue);
      }
      setState(() {});
    }
  }

  void _onPanUpdateWithDelta(DragUpdateDetails details, double sliderWidth) {
    if (_isFocus) {
      bool isPanIncrease = details.delta.dx > 0;
      double mainLength = sliderWidth - thumbSize.width / 2 - thumbSize.width;
      Offset offsetLocalPosition = _offsetThumb.translate(details.delta.dx, 0);

      double tempValue =
          clampDouble(offsetLocalPosition.dx / (mainLength), 0, 1) *
              (widget.max - widget.min) +
          widget.min;
      int checkSnapValue =
          AdjustHelpers.getNearestNumberAndDivisibleTargetNumber(
            tempValue,
            100,
            isGreatThan: isPanIncrease,
          );
      double mainValue = tempValue;
      // snap slider
      if ((checkSnapValue.toDouble() - tempValue).abs() < 5) {
        mainValue = checkSnapValue.toDouble();
        offsetLocalPosition = Offset(
          (checkSnapValue.toDouble() - widget.min) /
              (widget.max - widget.min) *
              (mainLength),
          offsetLocalPosition.dy,
        );
        _isSnaping = true;
        Future.delayed(const Duration(milliseconds: 300), () {
          _isSnaping = false;
        });
      }
      Offset checkedOffset = Offset(
        clampDouble(offsetLocalPosition.dx, -thumbSize.width / 2, mainLength),
        offsetLocalPosition.dy,
      );
      _offsetThumb = checkedOffset;
      _percent = clampDouble(_offsetThumb.dx / (mainLength), 0, 1);
      if (widget.onChanged != null) {
        widget.onChanged!(mainValue);
      }
      setState(() {});
    }
  }

  void _onCheckOffset(Offset globalOffset) {
    Offset startOffset = _renderBoxSlider.localToGlobal(Offset.zero);
    Offset endOffset = startOffset.translate(
      _renderBoxSlider.size.width,
      _renderBoxSlider.size.height,
    );
    if (containOffset(globalOffset, startOffset, endOffset)) {
      setState(() {
        _isFocus = true;
      });
    }
  }

  void resetFocus() {
    if (widget.onChangeEnd != null) {
      widget.onChangeEnd!((_percent) * (widget.max - widget.min) + widget.min);
    }
    setState(() {
      _isFocus = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      key: _keySlider,
      builder: (context, constraint) {
        double maxWidth = constraint.maxWidth;
        double activeWidth = clampDouble(
          _offsetThumb.dx + thumbSize.width / 2,
          0,
          maxWidth,
        );

        return GestureDetector(
          onPanUpdate: (details) {
            // check velocity
            final deltaTime =
                (details.sourceTimeStamp?.inMilliseconds ?? 1) -
                (_lastTime?.inMilliseconds ?? 0);
            final velocity = details.delta.distance / max(0.001, deltaTime);
            print("velocity ${velocity}");
            if (velocity > 0.1) {
              _onPanUpdateWithDelta(details, maxWidth);
            } else {
              if (!_isSnaping) {
                _onPanUpdateWithDelta(details, maxWidth);
              }
            }

            _lastTime = details.sourceTimeStamp;
          },
          onPanStart: (details) {
            consolelog("call onPanStart");
            _onCheckOffset(details.globalPosition);
          },
          onPanEnd: (details) {
            resetFocus();
          },
          onTapUp: (details) {
            _onCheckOffset(details.globalPosition);
            _onTapUp(details, maxWidth);
            resetFocus();
          },
          child: Container(
            color: transparent,
            width: maxWidth,
            height: 40,
            padding: EdgeInsets.symmetric(horizontal: thumbSize.width / 2),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 4,
                  width: maxWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: widget.inactiveColor ?? grey.withValues(alpha: 0.3),
                  ),
                ),
                Container(
                  height: 5,
                  width: activeWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: widget.activeColor ?? black,
                  ),
                ),
                Positioned(
                  left: _offsetThumb.dx,
                  child: Container(
                    height: thumbSize.height,
                    width: thumbSize.width,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: widget.thumbColor ?? black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
