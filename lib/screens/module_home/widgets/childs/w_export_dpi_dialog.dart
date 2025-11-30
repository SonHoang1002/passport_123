import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/commons/extension.dart';
import 'package:pass1_/widgets/w_custom_value_notifier.dart';
import 'package:pass1_/widgets/w_segment_custom.dart';
import 'package:pass1_/widgets/w_slider1.dart';
import 'package:pass1_/widgets/w_text.dart';

// ignore: must_be_immutable
class WExportDpiDialog extends StatefulWidget {
  final double currentDpiResolution;
  final int currentIndexDpiFormat;
  final int indexImageFormat;
  void Function(double value) onChangeDpiResolution;
  void Function(int index) onChangeDpiFormat;
  void Function(double value) onChangeDPIResolutionEnd;
  // void Function() onCaculateFileSize;
  final List<double> listMinMaxDpi;

  final Map<int, String> dataSegmentResolution;
  final int indexSegmentMain;

  WExportDpiDialog({
    super.key,
    required this.currentIndexDpiFormat,
    required this.listMinMaxDpi,
    required this.indexImageFormat,
    required this.currentDpiResolution,
    required this.indexSegmentMain,
    required this.dataSegmentResolution,
    required this.onChangeDpiResolution,
    required this.onChangeDPIResolutionEnd,
    required this.onChangeDpiFormat,
    // required this.onCaculateFileSize,
  });

  @override
  State<WExportDpiDialog> createState() => _WExportDpiDialogState();
}

class _WExportDpiDialogState extends State<WExportDpiDialog> {
  late ValueNotifier<int> _vIndexSegment;
  late ValueNotifier<double> _vSliderValue;

  @override
  void initState() {
    _vIndexSegment = ValueNotifier<int>(widget.currentIndexDpiFormat);
    _vSliderValue =
        ValueNotifier<double>(widget.currentDpiResolution.toDouble());
    _vIndexSegment.addListener(listenerSegment);
    _vSliderValue.addListener(listenerSlider);
    super.initState();
  }

  void listenerSegment() {
    widget.onChangeDpiFormat(_vIndexSegment.value);
    widget.onChangeDPIResolutionEnd(_vSliderValue.value);
    // widget.onCaculateFileSize();
  }

  void listenerSlider() {
    widget.onChangeDpiResolution(_vSliderValue.value);
  }

  @override
  void dispose() {
    _vIndexSegment.removeListener(listenerSegment);
    _vSliderValue.removeListener(listenerSlider);
    _vIndexSegment.dispose();
    _vSliderValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // color: Theme.of(context).dialogBackgroundColor,
        borderRadius: BorderRadius.circular(22),
      ),
      height: 172,
      width: 328,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildBlurBg(),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildTitle(),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSegments(),
                    _buildSlider(),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlurBg() {
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

  Widget _buildTitle() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: WTextContent(
        value: "Resolution",
        textSize: 13,
        textLineHeight: 15.51,
        textFontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSegments() {
    return Flexible(
      child: Container(
        width: 300,
        height: 36,
        color: transparent,
        child: ValueListenableBuilder(
          valueListenable: ValuesListenablesCustom(valueListenables: [
            _vIndexSegment,
          ]),
          builder: (context, _, child) {
            return buildSegmentControl(
              context: context,
              groupValue: _vIndexSegment.value,
              listSegment: widget.dataSegmentResolution,
              onValueChanged: (value) {
                if (value == 0) {
                  if (widget.indexSegmentMain == 0) {
                    _vSliderValue.value = 600;
                  } else {
                    _vSliderValue.value = 300;
                  }
                } else if (value == 1) {
                  if (widget.indexSegmentMain == 0) {
                    _vSliderValue.value = 1200;
                  } else {
                    _vSliderValue.value = 600;
                  }
                }
                _vIndexSegment.value = value!;
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

  Widget _buildSlider() {
    return Container(
      width: 300,
      color: transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ValueListenableBuilder(
            valueListenable: ValuesListenablesCustom(valueListenables: [
              _vSliderValue,
            ]),
            builder: (context, _, child) {
              return Expanded(
                child: WSlider1(
                  value: _vSliderValue.value,
                  min: widget.listMinMaxDpi[0],
                  max: widget.listMinMaxDpi[1],
                  activeColor: Theme.of(context).textTheme.displayLarge!.color,
                  inactiveColor:
                      Theme.of(context).sliderTheme.inactiveTrackColor,
                  onChanged: (value) {
                    _vIndexSegment.value = 2;
                    _vSliderValue.value = value;
                  },
                  onChangeEnd: (value) {
                    widget.onChangeDPIResolutionEnd(value);
                    // widget.onCaculateFileSize();
                  },
                  // snapValues: const [600, 1200],
                  // snapDistance: 5,
                ),
              );
            },
          ),
          ValueListenableBuilder(
            valueListenable: ValuesListenablesCustom(valueListenables: [
              _vSliderValue,
            ]),
            builder: (context, _, child) {
              return SizedBox(
                width: 40,
                child: WTextContent(
                  value: (_vSliderValue.value).roundWithUnit(fractionDigits: 0),
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
  }
}
