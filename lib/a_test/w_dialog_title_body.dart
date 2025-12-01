// ignore: must_be_immutable
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pass1_/models/export_size_model.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/helpers/convert.dart';
import 'package:pass1_/helpers/native_bridge/method_channel.dart';
import 'package:pass1_/helpers/navigator_route.dart';
import 'package:pass1_/models/country_passport_model.dart';
import 'package:pass1_/models/export_size_model.dart';
import 'package:pass1_/providers/blocs/theme_bloc.dart';
import 'package:pass1_/screens/sub_modules/module_crop/widgets/w_dialog_unit_body.dart';
import 'package:pass1_/widgets/general_dialog/w_body_dialogs.dart';
import 'package:pass1_/widgets/general_dialog/w_general_dialog.dart';
import 'package:pass1_/widgets/w_spacer.dart';
import 'package:pass1_/widgets/w_text.dart';

// ignore: must_be_immutable
class WBodyDialogCustomSize extends StatefulWidget {
  void Function(ExportSizeModel) onComplete;
  ExportSizeModel exportSizeModel;
  WBodyDialogCustomSize({
    super.key,
    required this.onComplete,
    required this.exportSizeModel,
  });

  @override
  State<WBodyDialogCustomSize> createState() => _WBodyDialogCustomSizeState();
}

class _WBodyDialogCustomSizeState extends State<WBodyDialogCustomSize> {
  GlobalKey keyWidth = GlobalKey();
  GlobalKey keyHeight = GlobalKey();
  late Size _size;
  late bool _isDarkMode;
  late TextEditingController _controllerWidth, _controllerHeight;
  late Unit _currentUnit;
  final FocusNode _focusNodeWidth = FocusNode();
  late ExportSizeModel _currentExportSizeModel;
  late String _previousWidthInputValue, _previousHeightInputValue;

  @override
  void initState() {
    super.initState();
    _currentExportSizeModel = widget.exportSizeModel.copyWith();
    _previousWidthInputValue = widget.exportSizeModel.size.width.toString();
    _previousHeightInputValue = widget.exportSizeModel.size.height.toString();
    _controllerWidth = TextEditingController(
      text: widget.exportSizeModel.size.width.toString(),
    );
    _handleFillSelectiontextField(_controllerWidth);
    _controllerHeight = TextEditingController(
      text: widget.exportSizeModel.size.height.toString(),
    );
    _currentUnit = widget.exportSizeModel.unit;
    _focusNodeWidth.requestFocus();
  }

  void _handleFillSelectiontextField(TextEditingController controller) {
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  void _onTapInput(int indexInput) {
    bool isTapWidthInput = indexInput == 0;
    bool isTapHeightInput = indexInput == 1;

    if (isTapWidthInput) {
      double? parsedHeight = double.tryParse(_controllerHeight.text.trim());
      if (parsedHeight == null) {
        _controllerHeight.text = _previousHeightInputValue;
        MyMethodChannel.showToast(
          "Invalid height value, return previous value.",
        );
      }
      _handleFillSelectiontextField(_controllerHeight);
    } else if (isTapHeightInput) {
      double? parsedWidth = double.tryParse(_controllerWidth.text.trim());
      if (parsedWidth == null) {
        _controllerWidth.text = _previousWidthInputValue;
        MyMethodChannel.showToast(
          "Invalid width value, return previous value.",
        );
      }
      _handleFillSelectiontextField(_controllerWidth);
    } else {
      throw Exception("khong ho tro");
    }
    _previousWidthInputValue = _controllerWidth.text.trim();
    _previousHeightInputValue = _controllerHeight.text.trim();
    setState(() {});
  }

  void _onSubmitted() {
    /// Xử lý như thế nào với margin, limit như thế nà
    ///
    double? width = double.tryParse(_controllerWidth.text.trim());
    double? height = double.tryParse(_controllerHeight.text.trim());

    if (width == null) {
      _controllerWidth.text = _previousWidthInputValue;
      width = double.parse(_previousWidthInputValue);
      // MyMethodChannel.showToast("Invalid width value, return previous value.");
    }
    if (height == null) {
      _controllerHeight.text = _previousHeightInputValue;
      height = double.parse(_previousHeightInputValue);
      // MyMethodChannel.showToast("Invalid height value, return previous value.");
    }

    // if (width != null && height != null) {
    //   double widthByPixel = FlutterConvert.convertUnit(
    //     _currentUnit,
    //     PIXEL,
    //     width,
    //   );
    //   double heightByPixel = FlutterConvert.convertUnit(
    //     _currentUnit,
    //     PIXEL,
    //     width,
    //   );
    //   if (width > 0 && height > 0) {
    //     if (width > LIMITATION_DIMENSION_BY_PIXEl ||
    //         height > LIMITATION_DIMENSION_BY_PIXEl) {
    //       return;
    //     }
    //   }
    // }

    _currentExportSizeModel = _currentExportSizeModel.copyWith(
      size: Size(width, height),
    );
    widget.onComplete(_currentExportSizeModel);
    popNavigator(context);
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = BlocProvider.of<ThemeBloc>(context, listen: true).isDarkMode;
    _size = MediaQuery.sizeOf(context);
    return Dialog(
      child: FittedBox(
        child: Container(
          width: 350,
          height: 182,
          decoration: BoxDecoration(
            color: Theme.of(context).dialogBackgroundColor,
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Center(
                child: WTextContent(
                  value: "Custom Size",
                  textSize: 18,
                  textLineHeight: 20,
                  textFontWeight: FontWeight.w600,
                ),
              ),
              Column(
                children: [
                  _buildInputWidget(
                    unitKey: keyWidth,
                    title: "Width",
                    controller: _controllerWidth,
                    currentUnit: _currentUnit,
                    onTapUnitWidget: (renderBox) {
                      _showDialogUnit(renderBox);
                    },
                    onTapInput: () {
                      _onTapInput(0);
                    },
                    focusNode: _focusNodeWidth,
                  ),
                  WSpacer(height: 10),
                  _buildInputWidget(
                    unitKey: keyHeight,
                    title: "Height",
                    controller: _controllerHeight,
                    currentUnit: _currentUnit,
                    onTapUnitWidget: (renderBox) {
                      _showDialogUnit(renderBox);
                    },
                    onTapInput: () {
                      _onTapInput(1);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputWidget({
    required GlobalKey unitKey,
    required String title,
    required TextEditingController controller,
    required Unit currentUnit,
    required void Function(RenderBox renderBox) onTapUnitWidget,
    required void Function() onTapInput,
    FocusNode? focusNode,
  }) {
    return SizedBox(
      width: _size.width * 0.8,
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: AutoSizeText(
              title,
              maxFontSize: 14,
              minFontSize: 10,
              style: TextStyle(
                height: 16 / 14,
                fontFamily: FONT_GOOGLESANS,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.displayLarge!.color,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: TextField(
                  focusNode: focusNode,
                  onTap: onTapInput,
                  cursorColor: red,
                  onSubmitted: (value) {
                    _onSubmitted();
                  },
                  keyboardType: TextInputType.number,
                  controller: controller,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1,
                    fontWeight: FontWeight.w600,
                    fontFamily: FONT_GOOGLESANS,
                    color: Theme.of(context).textTheme.displayLarge!.color,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.only(bottom: 7, right: 10),
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Theme.of(context).badgeTheme.backgroundColor!,
                    filled: true,
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(color: blue),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              final renderBoxUnit =
                  unitKey.currentContext?.findRenderObject() as RenderBox;
              onTapUnitWidget(renderBoxUnit);
            },
            child: Container(
              key: unitKey,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _isDarkMode ? white : black,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  WTextContent(
                    value: currentUnit.title,
                    textSize: 14,
                    textLineHeight: 16,
                    textColor: !_isDarkMode ? white : black,
                  ),
                  WSpacer(width: 5),
                  Icon(
                    FontAwesomeIcons.caretDown,
                    size: 12,
                    color: !_isDarkMode ? white : black,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDialogUnit(RenderBox renderBox) {
    bool isHaveKeyboard = false;
    // ignore: deprecated_member_use
    if (WidgetsBinding.instance.window.viewInsets.bottom > 100) {
      isHaveKeyboard = true;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    Future.delayed(Duration(milliseconds: isHaveKeyboard ? 400 : 0), () {
      double itemHeight = 40;
      final startOffset = renderBox.localToGlobal(const Offset(0, 0));
      Offset endOffset = startOffset.translate(
        -120 + renderBox.size.width,
        -(LIST_UNIT.length - 1) * itemHeight - renderBox.size.height - 15,
      );
      showCustomDialogWithOffset(
        context: context,
        newScreen: BodyDialogCustom(
          offset: endOffset,
          dialogWidget: buildDialogUnitBody(
            context: context,
            currentUnit: _currentUnit,
            onSelected: (value) {
              if (_currentUnit == value) return;
              _currentExportSizeModel = _currentExportSizeModel.changeUnit(
                value,
              );
              setState(() {
                _currentUnit = value;
              });
              popNavigator(context);
            },
            width: 120,
            height: itemHeight,
          ),
          scaleAlignment: Alignment.bottomRight,
        ),
      );
    });
  }
}
