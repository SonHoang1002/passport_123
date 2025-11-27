import 'package:flutter/material.dart';
import 'package:passport_photo_2/commons/constants.dart';

// ignore: must_be_immutable
class WTextContent extends StatelessWidget {
  final String value;
  double? textSize;
  TextAlign? textAlign;
  Color? textColor;
  double? textLineHeight;
  FontWeight? textFontWeight;
  TextOverflow? textOverflow;
  int? textMaxLength;
  String? textFontFamily;
  List<Shadow>? shadows;
  Alignment? textOverflowAlignment;
  WTextContent({
    required this.value,
    super.key,
    this.textAlign,
    this.textColor,
    this.textFontWeight = FontWeight.w700,
    this.textLineHeight,
    this.textSize = 12,
    this.textOverflow,
    this.textMaxLength,
    this.textFontFamily,
    this.shadows,
    this.textOverflowAlignment,
  });

  @override
  Widget build(BuildContext context) {
    double _textSize = textSize! + 1.0;
    final size = MediaQuery.sizeOf(context);
    int maxLengthText = 16;
    if (size.width < MIN_SIZE.width) {
      maxLengthText = 12;
    }
    if (textOverflowAlignment != null && value.length > maxLengthText) {
      return _buildTextWithOverflow(context, textOverflowAlignment!, textAlign);
    }

    final textStyle = TextStyle(
        decoration: TextDecoration.none,
        fontSize: _textSize,
        shadows: shadows,
        color: textColor ?? Theme.of(context).textTheme.bodySmall!.color,
        fontWeight: textFontWeight,
        fontFamily: textFontFamily ?? FONT_GOOGLESANS,
        overflow: textOverflow,
        height: textLineHeight != null && textSize != null
            ? (textLineHeight! / textSize!)
            : null);

    return Text(
      value,
      textAlign: textAlign,
      maxLines: textMaxLength,
      style: textStyle,
    );
  }

  Widget _buildTextWithOverflow(
    BuildContext context,
    Alignment alignment,
    TextAlign? textAlign,
  ) {
    double _textSize = textSize! + 1.0;
    final textStyle = TextStyle(
        decoration: TextDecoration.none,
        fontSize: _textSize,
        shadows: shadows,
        color: textColor ?? Theme.of(context).textTheme.bodySmall!.color,
        fontWeight: textFontWeight,
        fontFamily: textFontFamily ?? FONT_GOOGLESANS,
        overflow: textOverflow,
        height: textLineHeight != null && textSize != null
            ? (textLineHeight! / textSize!)
            : null);

    switch (alignment) {
      case Alignment.centerRight:
        return RichText(
            textAlign: textAlign ?? TextAlign.start,
            maxLines: textMaxLength,
            text: TextSpan(
              text: value,
              style: textStyle,
            ));
      case Alignment.centerLeft:
        return RichText(
            textAlign: textAlign ?? TextAlign.start,
            maxLines: textMaxLength,
            text: TextSpan(children: [
              TextSpan(
                text: "...",
                style: textStyle,
              ),
              TextSpan(
                text: value.substring(value.length - 14, value.length),
                style: textStyle,
              ),
            ], style: textStyle));
      case Alignment.center:
        return RichText(
            textAlign: textAlign ?? TextAlign.start,
            maxLines: textMaxLength,
            text: TextSpan(children: [
              TextSpan(
                text: value.substring(0, value.length~/2),
                style: textStyle,
              ),
              TextSpan(
                text: "...",
                style: textStyle,
              ),
              TextSpan(
                text: value.substring(value.length~/2, value.length),
                style: textStyle,
              ),
            ], style: textStyle));
      default:
        return RichText(
            textAlign: textAlign ?? TextAlign.start,
            maxLines: textMaxLength,
            text: TextSpan(
              text: value,
              style: textStyle,
            ));
    }
  }
}
