import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/commons/extension.dart';
import 'package:pass1_/widgets/w_custom_value_notifier.dart';
import 'package:pass1_/widgets/w_segment_custom.dart';
import 'package:pass1_/widgets/w_slider1.dart';
import 'package:pass1_/widgets/w_text.dart';

// ignore: must_be_immutable
class WExportCompression extends StatelessWidget {
  final int currentCompression;
  final int currentIndexImageFormat;
  void Function(int percent) onChangeCompression;
  void Function(int prev, int index) onChangeImageFormat;
  void Function(int percent) onCompressionEnd;

  WExportCompression({
    super.key,
    required this.onChangeCompression,
    required this.onChangeImageFormat,
    required this.currentCompression,
    required this.currentIndexImageFormat,
    required this.onCompressionEnd,
  }) {
    _vIndexSegment = ValueNotifier<int>(currentIndexImageFormat);
    _vSliderPercent = ValueNotifier<double>(currentCompression.toDouble());
  }

  late ValueNotifier<int> _vIndexSegment;
  late ValueNotifier<double> _vSliderPercent;
  double _vMax = 100;
  double _vMin = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
      ),
      height: 172,
      width: 328,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildBlurBg(context),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildTitle(context),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSegments(context: context),
                    _buildSlider(context),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlurBg(BuildContext context) {
    return SizedBox(
      height: 172,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 20,
            sigmaY: 20,
          ),
          child: Container(
            color: Theme.of(context).dialogBackgroundColor,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: WTextContent(
        value: "Format",
        textSize: 13,
        textLineHeight: 15.51,
        textFontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSegments({
    required BuildContext context,
  }) {
    return Flexible(
      child: SizedBox(
        width: 300,
        height: 36,
        child: ValueListenableBuilder(
          valueListenable: ValuesListenablesCustom(valueListenables: [
            _vIndexSegment,
          ]),
          builder: (context, _, child) {
            return buildSegmentControl(
              context: context,
              groupValue: _vIndexSegment.value,
              listSegment: EXPORT_SEGMENT_COMPRESSION_IMAGE_FORMAT,
              onValueChanged: (value) {
                onChangeImageFormat(_vIndexSegment.value, value!);
                _vIndexSegment.value = value;
                // onCaculateFileSize();
              },
              unactiveTextColor:
                  Theme.of(context).textTheme.displayMedium!.color,
              borderRadius: 12,
            );
          },
        ),
      ),
    );
  }

  Widget _buildSlider(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: ValuesListenablesCustom(valueListenables: [
          _vIndexSegment,
        ]),
        builder: (context, _, child) {
          if (_vIndexSegment.value == 1) {
            return Container(
              height: 30,
              color: transparent,
            );
          }
          return Container(
            color: transparent,
            width: 300,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                WTextContent(
                  value: "Compression:",
                  textSize: 13,
                  textLineHeight: 15.51,
                  textFontWeight: FontWeight.w600,
                ),
                ValueListenableBuilder(
                  valueListenable: ValuesListenablesCustom(valueListenables: [
                    _vSliderPercent,
                  ]),
                  builder: (context, _, child) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        child: WSlider1(
                          value: _vSliderPercent.value,
                          max: _vMax,
                          min: _vMin,
                          activeColor:
                              Theme.of(context).textTheme.displayLarge!.color,
                          inactiveColor:
                              Theme.of(context).sliderTheme.inactiveTrackColor,
                          onChanged: (value) {
                            _vSliderPercent.value = value;
                            onChangeCompression(
                              int.parse(value.roundWithUnit(fractionDigits: 0)),
                            );
                          },
                          onChangeEnd: (value) {
                            onCompressionEnd(int.parse(
                                value.roundWithUnit(fractionDigits: 0)));
                            // onCaculateFileSize();
                          },
                        ),
                      ),
                    );
                  },
                ),
                ValueListenableBuilder(
                  valueListenable: ValuesListenablesCustom(valueListenables: [
                    _vSliderPercent,
                  ]),
                  builder: (context, _, child) {
                    return SizedBox(
                      width: 50,
                      child: WTextContent(
                        value:
                            "${(_vSliderPercent.value).roundWithUnit(fractionDigits: 0)}%",
                        textSize: 13,
                        textLineHeight: 15.51,
                        textFontWeight: FontWeight.w600,
                        textAlign: TextAlign.right,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        });
  }
}
