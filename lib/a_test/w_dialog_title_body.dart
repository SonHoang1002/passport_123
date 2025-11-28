// ignore: must_be_immutable
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:passport_photo_2/commons/colors.dart';
import 'package:passport_photo_2/commons/constants.dart';
import 'package:passport_photo_2/helpers/convert.dart';
import 'package:passport_photo_2/helpers/navigator_route.dart';
import 'package:passport_photo_2/models/country_passport_model.dart';
import 'package:passport_photo_2/models/export_size_model.dart';
import 'package:passport_photo_2/providers/blocs/theme_bloc.dart';
import 'package:passport_photo_2/screens/sub_modules/module_crop/widgets/w_dialog_unit_body.dart';
import 'package:passport_photo_2/widgets/general_dialog/w_body_dialogs.dart';
import 'package:passport_photo_2/widgets/general_dialog/w_general_dialog.dart';
import 'package:passport_photo_2/widgets/w_spacer.dart';
import 'package:passport_photo_2/widgets/w_text.dart';

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
  @override
  void initState() {
    super.initState();
    _currentExportSizeModel = widget.exportSizeModel.copyWith();
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
                    keyWidth,
                    "Width",
                    _controllerWidth,
                    _currentUnit,
                    (renderBox) {
                      _showDialogUnit(renderBox);
                    },
                    focusNode: _focusNodeWidth,
                  ),
                  WSpacer(height: 10),
                  _buildInputWidget(
                    keyHeight,
                    "Height",
                    _controllerHeight,
                    _currentUnit,
                    (renderBox) {
                      _showDialogUnit(renderBox);
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputWidget(
    GlobalKey unitKey,
    String title,
    TextEditingController controller,
    Unit currentUnit,
    void Function(RenderBox renderBox) onTapUnitWidget, {
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
                  onTap: () {
                    _handleFillSelectiontextField(controller);
                  },
                  cursorColor: red,
                  onSubmitted: (value) {
                    if (value.trim() == "") {
                      controller.text = "0.0";
                    }
                    double? width =
                        double.tryParse(_controllerWidth.value.text.trim());
                    double? height =
                        double.tryParse(_controllerHeight.value.text.trim());
                    if (width != null && height != null) {

                      double widthByPixel = FlutterConvert.convertUnit(_currentUnit, PIXEL, width);
                      double heightByPixel = FlutterConvert.convertUnit(_currentUnit, PIXEL, width);
                      if (width > 0 && height > 0) {
                        if (width > LIMITATION_DIMENSION_BY_PIXEl ||
                            height > LIMITATION_DIMENSION_BY_PIXEl) {
                          return;
                        }
                        onChangeSize(
                          sizeModel!.copyWith(size: Size(width, height)),
                        );
                      }
                      widget.onComplete(_currentExportSizeModel);
                      popNavigator(context);
                    }
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
                  color: _isDarkMode ? white : black),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  WTextContent(
                    value: currentUnit.title,
                    textSize: 14,
                    textLineHeight: 16,
                    textColor: !_isDarkMode ? white : black,
                  ),
                  WSpacer(
                    width: 5,
                  ),
                  Icon(
                    FontAwesomeIcons.caretDown,
                    size: 12,
                    color: !_isDarkMode ? white : black,
                  )
                ],
              ),
            ),
          )
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
    Future.delayed(
      Duration(milliseconds: isHaveKeyboard ? 400 : 0),
      () {
        double itemHeight = 40;
        final startOffset = renderBox.localToGlobal(const Offset(0, 0));
        Offset endOffset = startOffset.translate(-120 + renderBox.size.width,
            -(LIST_UNIT.length - 1) * itemHeight - renderBox.size.height - 15);
        showCustomDialogWithOffset(
          context: context,
          newScreen: BodyDialogCustom(
            offset: endOffset,
            dialogWidget: buildDialogUnitBody(
              context: context,
              currentUnit: _currentUnit,
              onSelected: (value) {
                if (_currentUnit == value) return;
                _currentExportSizeModel =
                    _currentExportSizeModel.changeUnit(value);
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
      },
    );
  }
}
