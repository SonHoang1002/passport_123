import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passport_photo_2/commons/colors.dart';
import 'package:passport_photo_2/commons/constants.dart';
import 'package:passport_photo_2/commons/extension.dart';
import 'package:passport_photo_2/models/country_passport_model.dart';
import 'package:passport_photo_2/providers/blocs/theme_bloc.dart';
import 'package:passport_photo_2/widgets/w_text.dart';

class BodyDialogCropGuideTooltip extends StatefulWidget {
  final Unit currentUnit;
  final double percentValue;
  final double passportHeight;
  final double unitValue;
  final Size dialogSize;
  final Function(double newPercent, double newUnitValue) onDone;

  const BodyDialogCropGuideTooltip({
    super.key,
    required this.currentUnit,
    required this.percentValue,
    required this.unitValue,
    required this.onDone,
    required this.dialogSize,
    required this.passportHeight,
  });

  @override
  State<BodyDialogCropGuideTooltip> createState() =>
      _BodyDialogCropGuideTooltipState();
}

class _BodyDialogCropGuideTooltipState
    extends State<BodyDialogCropGuideTooltip> {
  double rWidth = 136;
  double rHeight = 96;
  late TextEditingController _controllerPercent, _controllerUnit;
  // int _indexSelectInput = 0;
  final FocusNode _focusNodePercent = FocusNode();

  @override
  void initState() {
    super.initState();
    _controllerPercent = TextEditingController(
        text: widget.percentValue.roundWithUnit(fractionDigits: 2));
    _controllerUnit = TextEditingController(
        text: widget.unitValue.roundWithUnit(fractionDigits: 2));
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controllerPercent.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controllerPercent.text.length,
      );
      _focusNodePercent.requestFocus();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        BlocProvider.of<ThemeBloc>(context, listen: false).isDarkMode;
    return Container(
      width: widget.dialogSize.width,
      height: widget.dialogSize.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDarkMode ? blurDark : blurLight,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: SizedBox(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 20,
                    sigmaY: 20,
                  ),
                  child: Container(
                    color: transparent,
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTextField(
                  _controllerPercent,
                  0,
                  isDarkMode,
                  "%",
                  focusNode: _focusNodePercent,
                ),
                _buildTextField(
                  _controllerUnit,
                  1,
                  isDarkMode,
                  widget.currentUnit.title,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateValuesWhenChanged(int index) {
    String valuePercent = _controllerPercent.value.text.trim();
    String valueUnit = _controllerUnit.value.text.trim();
    double newPercentValue, newUnitValue;
    if (valuePercent == "") {
      newPercentValue = 0.0;
    } else {
      newPercentValue = double.parse(valuePercent);
    }
    if (valueUnit == "") {
      newUnitValue = 0.0;
    } else {
      newUnitValue = double.parse(valueUnit);
    }
    switch (index) {
      case 0: // thay doi % -> thay doi unit
        newUnitValue = newPercentValue / 100 * widget.passportHeight;
        _controllerUnit.value = TextEditingValue(text: newUnitValue.toString());
        break;
      case 1: // thay doi unit -> thay doi %
        newPercentValue = newUnitValue / widget.passportHeight * 100;
        _controllerPercent.value =
            TextEditingValue(text: newPercentValue.toString());
        break;
      default:
    }
  }

  void _checkValidValue() {
    double newPercentValue = double.parse(_controllerPercent.value.text.trim());
    double newUnitValue = double.parse(_controllerUnit.value.text.trim());
    // if (newPercentValue < 0) {
    //   newPercentValue = widget.percentValue;
    // }
    // if (newUnitValue < 0) {
    //   newUnitValue = widget.unitValue;
    // }
    widget.onDone(newPercentValue, newUnitValue);
  }

  Widget _buildTextField(
    TextEditingController controller,
    int index,
    bool isDarkMode,
    String suffixValue, {
    FocusNode? focusNode,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onTap: () {
            controller.selection = TextSelection(
              baseOffset: 0,
              extentOffset: controller.text.length,
            );
          },
          onSubmitted: (value) {
            if (value.trim() == "") {
              controller.text = "0.0";
            }
            _checkValidValue();
          },
          onChanged: (value) {
            _updateValuesWhenChanged(index);
          },
          keyboardType: TextInputType.number,
          textAlign: TextAlign.start,
          style: TextStyle(
            fontSize: 13,
            height: 1,
            fontWeight: FontWeight.w600,
            fontFamily: FONT_GOOGLESANS,
            color: Theme.of(context).textTheme.displayLarge!.color,
          ),
          decoration: InputDecoration(
            hintText: "",
            contentPadding:
                const EdgeInsets.only(left: 10, right: 10, bottom: 14),
            enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: transparent, width: 2),
                borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: blue, width: 2),
                borderRadius: BorderRadius.circular(10)),
            fillColor: isDarkMode ? white003 : black003,
            filled: true,
            suffix: Container(
              margin: const EdgeInsets.only(left: 10),
              child: WTextContent(
                value: suffixValue,
                textSize: 13,
              ),
            ),
            border: OutlineInputBorder(
              borderSide: const BorderSide(color: blue),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}
