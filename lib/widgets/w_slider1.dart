import 'package:flutter/material.dart';
import "dart:math" as math;

import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/helpers/log_custom.dart';

// ignore: must_be_immutable
class WSlider1 extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final void Function(double value) onChanged;
  final void Function(double value)? onChangeEnd;
  final Color? inactiveColor;
  final Color? activeColor;
  final Color? thumbColor;
  final int? divisions;
  final List<double>? snapValues;
  final double? snapDistance;
  WSlider1({
    super.key,
    required this.value,
    required this.max,
    required this.min,
    required this.onChanged,
    this.onChangeEnd,
    this.snapValues,
    this.snapDistance,
    this.inactiveColor,
    this.activeColor,
    this.thumbColor,
    this.divisions,
  });

  late double _distanceSnap;

  @override
  Widget build(BuildContext context) {
    double _max, _min;
    _max = math.max(value, max);
    _min = math.min(value, min);

    _distanceSnap = snapDistance ?? (_max - _min) / (_max + _min);
    return Container(
      color: transparent,
      height: 30,
      child: SliderTheme(
        data: SliderThemeData(
          minThumbSeparation: 0,
          trackShape: const CustomRoundedRectSliderTrackShape(),
          thumbShape: NoShadowSliderThumb(),
          trackHeight: 6.0,
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 30),
        ),
        child: Slider(
          value: value,
          divisions: divisions,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          overlayColor: const MaterialStatePropertyAll(Colors.transparent),
          min: _min,
          max: _max,
          thumbColor: thumbColor,
          onChanged: (value) {
            snapSlider(value);
          },
          onChangeEnd: onChangeEnd,
        ),
      ),
    );
  }

  void snapSlider(double value) {
    if (snapValues != null) {
      double neartestSnapValue = getNearestSnapValue(value, snapValues!);
      consolelog("_distanceSnap ${_distanceSnap}");
      if (handleCheckSnap(value, neartestSnapValue, _distanceSnap)) {
        onChanged(neartestSnapValue);
        return;
      }
    }
    onChanged(value);
  }

  bool handleCheckSnap(double value, double snapValue, double distance) {
    return (value - snapValue).abs() < distance;
  }

  double getNearestSnapValue(double value, List<double> snapValues) {
    double result = snapValues[0];
    double smallestDifference = (value - result).abs();
    for (var snapValue in snapValues) {
      double currentDifference = (value - snapValue).abs();
      if (currentDifference < smallestDifference) {
        result = snapValue;
        smallestDifference = currentDifference;
      }
    }
    return result;
  }
}

class CustomRoundedRectSliderTrackShape extends SliderTrackShape
    with BaseSliderTrackShape {
  const CustomRoundedRectSliderTrackShape();
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    double trackHeight = 4.5;
    double trackLeft = 15.0;
    double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    double trackWidth = parentBox.size.width - 15 * 2;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0.5,
  }) {
    if (sliderTheme.trackHeight == null || sliderTheme.trackHeight! <= 0) {
      return;
    }

    final ColorTween activeTrackColorTween = ColorTween(
      begin: sliderTheme.disabledActiveTrackColor,
      end: sliderTheme.activeTrackColor,
    );
    final ColorTween inactiveTrackColorTween = ColorTween(
      begin: sliderTheme.disabledInactiveTrackColor,
      end: sliderTheme.inactiveTrackColor,
    );
    final Paint activePaint = Paint()
      ..color = activeTrackColorTween.evaluate(enableAnimation)!;
    final Paint inactivePaint = Paint()
      ..color = inactiveTrackColorTween.evaluate(enableAnimation)!;
    final Paint leftTrackPaint;
    final Paint rightTrackPaint;
    switch (textDirection) {
      case TextDirection.ltr:
        leftTrackPaint = activePaint;
        rightTrackPaint = inactivePaint;
      case TextDirection.rtl:
        leftTrackPaint = inactivePaint;
        rightTrackPaint = activePaint;
    }

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final Radius trackRadius = Radius.circular(trackRect.height / 2);
    final Radius activeTrackRadius = Radius.circular(
      (trackRect.height + additionalActiveTrackHeight) / 2,
    );

    context.canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        trackRect.left,
        (textDirection == TextDirection.ltr)
            ? trackRect.top - (additionalActiveTrackHeight / 2)
            : trackRect.top,
        thumbCenter.dx,
        (textDirection == TextDirection.ltr)
            ? trackRect.bottom + (additionalActiveTrackHeight / 2)
            : trackRect.bottom,
        topLeft: (textDirection == TextDirection.ltr)
            ? activeTrackRadius
            : trackRadius,
        bottomLeft: (textDirection == TextDirection.ltr)
            ? activeTrackRadius
            : trackRadius,
      ),
      leftTrackPaint,
    );
    context.canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        thumbCenter.dx,
        (textDirection == TextDirection.rtl)
            ? trackRect.top - (additionalActiveTrackHeight / 2)
            : trackRect.top,
        trackRect.right,
        (textDirection == TextDirection.rtl)
            ? trackRect.bottom + (additionalActiveTrackHeight / 2)
            : trackRect.bottom,
        topRight: (textDirection == TextDirection.rtl)
            ? activeTrackRadius
            : trackRadius,
        bottomRight: (textDirection == TextDirection.rtl)
            ? activeTrackRadius
            : trackRadius,
      ),
      rightTrackPaint,
    );

    final bool showSecondaryTrack =
        (secondaryOffset != null) &&
        ((textDirection == TextDirection.ltr)
            ? (secondaryOffset.dx > thumbCenter.dx)
            : (secondaryOffset.dx < thumbCenter.dx));

    if (showSecondaryTrack) {
      final ColorTween secondaryTrackColorTween = ColorTween(
        begin: sliderTheme.disabledSecondaryActiveTrackColor,
        end: sliderTheme.secondaryActiveTrackColor,
      );
      final Paint secondaryTrackPaint = Paint()
        ..color = secondaryTrackColorTween.evaluate(enableAnimation)!;
      if (textDirection == TextDirection.ltr) {
        context.canvas.drawRRect(
          RRect.fromLTRBAndCorners(
            thumbCenter.dx,
            trackRect.top,
            secondaryOffset.dx,
            trackRect.bottom,
            topRight: trackRadius,
            bottomRight: trackRadius,
          ),
          secondaryTrackPaint,
        );
      } else {
        context.canvas.drawRRect(
          RRect.fromLTRBAndCorners(
            secondaryOffset.dx,
            trackRect.top,
            thumbCenter.dx,
            trackRect.bottom,
            topLeft: trackRadius,
            bottomLeft: trackRadius,
          ),
          secondaryTrackPaint,
        );
      }
    }
  }
}

class NoShadowSliderThumb extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size.fromRadius(10.0);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    Animation<double>? activationAnimation,
    Animation<double>? enableAnimation,
    bool? isDiscrete,
    TextPainter? labelPainter,
    RenderBox? parentBox,
    SliderThemeData? sliderTheme,
    TextDirection? textDirection,
    double? value,
    double? textScaleFactor,
    Size? sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    final Paint paint = Paint()
      ..color = sliderTheme!.thumbColor!
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 9, paint);
  }
}
