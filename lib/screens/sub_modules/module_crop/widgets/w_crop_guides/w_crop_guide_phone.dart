import 'dart:math';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/commons/extension.dart';
import 'package:pass1_/helpers/contain_offset.dart';
import 'package:pass1_/helpers/log_custom.dart';
import 'package:pass1_/helpers/native_bridge/method_channel.dart';
import 'package:pass1_/helpers/navigator_route.dart';
import 'package:pass1_/models/country_passport_model.dart';
import 'package:pass1_/providers/blocs/theme_bloc.dart';
import 'package:pass1_/screens/sub_modules/module_crop/widgets/w_bottom_buttons.dart';
import 'package:pass1_/screens/sub_modules/module_crop/widgets/w_dialog_tooltip.dart';
import 'package:pass1_/screens/sub_modules/module_crop/widgets/w_dialog_unit_body.dart';
import 'package:pass1_/screens/sub_modules/module_crop/widgets/w_dot.dart';
import 'package:pass1_/screens/sub_modules/module_crop/widgets/w_infor_box_crop_guide.dart';
import 'package:pass1_/widgets/general_dialog/w_body_dialogs.dart';
import 'package:pass1_/widgets/general_dialog/w_general_dialog.dart';
import 'package:pass1_/widgets/w_dash_line.dart';
import 'package:pass1_/widgets/w_spacer.dart';
import 'package:pass1_/widgets/w_text.dart';

class WCustomCropGuidePhone extends StatefulWidget {
  final CountryModel countrySelected;
  final Function(CountryModel model) onUpdateCountry;
  final Size screenSize;
  const WCustomCropGuidePhone({
    super.key,
    required this.countrySelected,
    required this.onUpdateCountry,
    required this.screenSize,
  });
  @override
  State<WCustomCropGuidePhone> createState() => _WCustomCropGuidePhoneState();
}

class _WCustomCropGuidePhoneState extends State<WCustomCropGuidePhone> {
  final double _sizeBlueCursor = 24.0;
  final double _heightEyes = 40.0;
  final double _heightHeadChin = 12.0;
  final double _heightTooltip = 45.0;
  final double _ratioHeadToChinOnMan = 0.345;
  final double _sizeDot = 6;
  Offset offsetZero = const Offset(0, 0);
  final double _mainRatio = 0.55;

  late Size _size;
  late bool _isDarkMode;
  final GlobalKey _keyImage = GlobalKey(debugLabel: "_keyImage");
  final GlobalKey _keyChin = GlobalKey(debugLabel: "_keyChin");
  final GlobalKey _keyHead = GlobalKey(debugLabel: "_keyHead");
  final GlobalKey _keyCursor = GlobalKey(debugLabel: "_keyCursor");
  final GlobalKey _keyEyes = GlobalKey(debugLabel: "_keyEyes");
  final GlobalKey _keyTooltip0 = GlobalKey(debugLabel: "_keyTooltip0");
  final GlobalKey _keyTooltip1 = GlobalKey(debugLabel: "_keyTooltip1");
  final GlobalKey _keyUnitWidth = GlobalKey(debugLabel: "_keyUnitWidth");
  final GlobalKey _keyUnitHeight = GlobalKey(debugLabel: "_keyUnitHeight");

  RenderBox? _renderImage;
  late RenderBox _renderBoxChin,
      _renderBoxHead,
      _renderBoxEyes,
      _renderBoxCursor; // khu vuc chua anh va cac edit object khac
  late Offset _offsetHead, _offsetChin, _offsetBlueCursor, _offsetEyes;
  int _indexFacePositionSelected = 0;
  late Size _imageSize;
  Size? _imageSizeOriginal;
  bool _isCanPan = false;

  // main
  late TextEditingController _controllerWidth, _controllerHeight
  // , _controllerWidthPrevious,  _controllerHeightPrevious
  ;
  late Unit _currentUnit;
  bool _avoidResizeKeyboard = false;
  late String _previousWidthInputValue, _previousHeightInputValue;
  @override
  void initState() {
    super.initState();
    _initOffsets();
    _size = widget.screenSize;
    final selectedPassport = widget
        .countrySelected
        .listPassportModel[widget.countrySelected.indexSelectedPassport];
    _previousWidthInputValue = selectedPassport.width.toString();
    _previousHeightInputValue = selectedPassport.height.toString();
    _controllerWidth = TextEditingController(
      text: selectedPassport.width.toString(),
    );
    // _controllerWidthPrevious = TextEditingController(
    //   text: selectedPassport.width.toString(),
    // );
    _controllerHeight = TextEditingController(
      text: selectedPassport.height.toString(),
    );
    // _controllerHeightPrevious = TextEditingController(
    //   text: selectedPassport.height.toString(),
    // );
    _currentUnit = selectedPassport.unit;
    _updateImageSize(selectedPassport.width, selectedPassport.height);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _updateRenderBoxs();
      final selectedPassport = widget.countrySelected.currentPassport;
      _updateOffsets(
        selectedPassport.ratioHead,
        selectedPassport.ratioEyes,
        selectedPassport.ratioChin,
      );
      setState(() {});
    });
  }

  void _initOffsets() {
    _offsetHead = _offsetChin = _offsetBlueCursor = _offsetEyes = offsetZero;
  }

  void _updateRenderBoxs() {
    _renderImage = _keyImage.currentContext?.findRenderObject() as RenderBox;
    _renderBoxChin = _keyChin.currentContext?.findRenderObject() as RenderBox;
    _renderBoxHead = _keyHead.currentContext?.findRenderObject() as RenderBox;
    _renderBoxEyes = _keyEyes.currentContext?.findRenderObject() as RenderBox;
    _renderBoxCursor =
        _keyCursor.currentContext?.findRenderObject() as RenderBox;
  }

  void _updateImageSize(double width, double height) {
    _imageSizeOriginal ??= Size(
      _size.width * _mainRatio,
      _size.width * _mainRatio,
    );
    double newWidth, newHeight;
    newHeight = newWidth = _size.width * _mainRatio;
    double ratioWH = 1;
    if (width == 0 || height == 0) {
      ratioWH = 0;
    } else {
      ratioWH = width / height;
    }

    if (ratioWH > 1) {
      newHeight = newWidth * (1 / ratioWH);
    } else if (ratioWH < 1) {
      newWidth = newHeight * ratioWH;
      if (width == 0) {
        newWidth = 0.1;
      }
      if (height == 0) {
        newHeight = 0.1;
      }
    }
    _imageSize = Size(newWidth, newHeight);
  }

  void _onSave() {
    double? width = double.tryParse(_controllerWidth.text.trim());
    double? height = double.tryParse(_controllerHeight.text.trim());

    if (width == null) {
      _controllerWidth.text = _previousWidthInputValue;
      width = double.parse(_previousWidthInputValue);
      MyMethodChannel.showToast("Invalid width value, return previous value.");
    }
    if (height == null) {
      _controllerHeight.text = _previousHeightInputValue;
      height = double.parse(_previousHeightInputValue);
      MyMethodChannel.showToast("Invalid height value, return previous value.");
    }
    if (_currentUnit == PIXEL) {
      if (width > LIMITATION_DIMENSION_BY_PIXEl ||
          height > LIMITATION_DIMENSION_BY_PIXEl) {
        double aspectRatio = width / height;
        if (aspectRatio > 1) {
          width = LIMITATION_DIMENSION_BY_PIXEl;
          height = width / aspectRatio;
        } else if (aspectRatio < 1) {
          height = LIMITATION_DIMENSION_BY_PIXEl;
          width = height * aspectRatio;
        } else {
          width = height = LIMITATION_DIMENSION_BY_PIXEl;
        }
        MyMethodChannel.showToast("Width and height are not over 8000 pixels.");
      }
    } else {
      // khong co limit gi ca
    }

    final ratioHead = 1 - _offsetHead.dy / _renderImage!.size.height;
    final ratioEyes =
        1 - (_offsetEyes.dy + _heightEyes / 2) / _renderImage!.size.height;
    final ratioChin =
        1 - (_offsetChin.dy + _heightHeadChin) / _renderImage!.size.height;
    final CountryModel countryModel = CountryModel.createCustomCountryModel(
      width: double.parse(width.toStringAsFixed(1)),
      height: double.parse(height.toStringAsFixed(1)),
      ratioHead: ratioHead,
      ratioEyes: ratioEyes,
      ratioChin: ratioChin,
      currentUnit: _currentUnit,
    );
    widget.onUpdateCountry(countryModel);
    popNavigator(context);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_renderImage == null || !_isCanPan) return;
    // cham vao cursor mau xanh
    switch (_indexFacePositionSelected) {
      case 0: // head
        double newDy = details.delta.dy + _offsetHead.dy;
        double limitMin = 0;
        double limitMax = _offsetEyes.dy + (_heightEyes / 2 - _heightHeadChin);
        double mainDy = min(limitMax, max(newDy, limitMin));
        _offsetHead = Offset(_offsetHead.dx, mainDy);
        _offsetBlueCursor = _offsetHead.translate(0, -_heightHeadChin);
        setState(() {});
        break;
      case 1: // eyes : khong vuot qua head, chin
        double newDy = details.delta.dy + _offsetEyes.dy;
        double limitMin = _offsetHead.dy - _heightEyes / 2 + _heightHeadChin;
        double limitMax =
            _offsetChin.dy -
            _heightHeadChin -
            (_heightEyes / 2 - _heightHeadChin);
        double mainDy = min(limitMax, max(newDy, limitMin));
        _offsetEyes = Offset(_offsetEyes.dx, mainDy);
        _offsetBlueCursor = _offsetEyes.translate(
          0,
          (_heightEyes / 2) - _sizeBlueCursor / 2,
        ); // tinh tien ve vi tri ban dau cua cursor va vao giua cua eyes
        setState(() {});
        break;
      case 2: // chin
        double newDy = details.delta.dy + _offsetChin.dy;
        double limitMin = _offsetEyes.dy + _heightEyes / 2;
        double limitMax = _renderImage!.size.height - _heightHeadChin;
        double mainDy = min(limitMax, max(newDy, limitMin));
        _offsetChin = Offset(_offsetChin.dx, mainDy);
        _offsetBlueCursor = _offsetChin.translate(0, -3);
        setState(() {});
        break;
      default:
    }
  }

  void _onCheckOffset(Offset globalPosition) {
    FocusManager().primaryFocus?.unfocus();
    // UU TIEN CHO HEAD VA CHIN HON EYES
    // check Cursor
    Offset offsetExpandStart = const Offset(0, -20);
    Offset offsetExpandEnd = const Offset(0, 20);
    final startOffsetCursor = _renderBoxCursor.localToGlobal(offsetZero);
    final endOffsetCursor = startOffsetCursor.translate(
      _renderBoxHead.size.width,
      _renderBoxCursor.size.height,
    );
    if (containOffset(
      globalPosition,
      startOffsetCursor + offsetExpandStart,
      endOffsetCursor + offsetExpandEnd,
    )) {
      _isCanPan = true;
      return;
    }
    // check Head
    final startOffsetHead = _renderBoxHead.localToGlobal(offsetZero);
    final endOffsetHead = startOffsetHead.translate(
      _renderBoxHead.size.width,
      _renderBoxHead.size.height,
    );
    if (containOffset(
      globalPosition,
      startOffsetHead + offsetExpandStart,
      endOffsetHead + offsetExpandEnd,
    )) {
      _indexFacePositionSelected = 0;
      _onChangeOffsetBlueCursor(_indexFacePositionSelected);
      _isCanPan = true;
      return;
    }

    // check Chin
    final startOffsetChin = _renderBoxChin.localToGlobal(offsetZero);
    final endOffsetChin = startOffsetChin.translate(
      _renderBoxChin.size.width,
      _renderBoxChin.size.height,
    );
    if (containOffset(
      globalPosition,
      startOffsetChin + offsetExpandStart,
      endOffsetChin + offsetExpandEnd,
    )) {
      _indexFacePositionSelected = 2;
      _onChangeOffsetBlueCursor(_indexFacePositionSelected);
      _isCanPan = true;
      return;
    }
    // check Eyes
    final startOffsetEyes = _renderBoxEyes.localToGlobal(offsetZero);
    final endOffsetEyes = startOffsetEyes.translate(
      _renderBoxEyes.size.width,
      _renderBoxEyes.size.height,
    );
    if (containOffset(
      globalPosition,
      startOffsetEyes + offsetExpandStart,
      endOffsetEyes + offsetExpandEnd,
    )) {
      _indexFacePositionSelected = 1;
      _onChangeOffsetBlueCursor(_indexFacePositionSelected);
      _isCanPan = true;
      return;
    }
  }

  void _onChangeOffsetBlueCursor(int index) {
    switch (index) {
      case 0:
        _offsetBlueCursor = _offsetHead.translate(0, -_heightHeadChin);
        break;
      case 1:
        _offsetBlueCursor = _offsetEyes.translate(
          0,
          -_sizeBlueCursor / 2 + _heightEyes / 2,
        );
      case 2:
        _offsetBlueCursor = _offsetChin.translate(0, -3);
      default:
    }
  }

  void _showDialogUnit(RenderBox renderBox) {
    bool isHaveKeyboard =
        false; // tranh viec vi tri hien thi cua dialog bi sai khi co keyboard dang hien thi
    if (MediaQuery.of(context).viewInsets.bottom > 100) {
      isHaveKeyboard = true;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    Future.delayed(Duration(milliseconds: isHaveKeyboard ? 300 : 0), () {
      double itemHeight = 40;
      final startOffset = renderBox.localToGlobal(offsetZero);
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
    } else if (isTapHeightInput) {
      double? parsedWidth = double.tryParse(_controllerWidth.text.trim());
      if (parsedWidth == null) {
        _controllerWidth.text = _previousWidthInputValue;
        MyMethodChannel.showToast(
          "Invalid width value, return previous value.",
        );
      }
    } else {
      throw Exception("khong ho tro");
    }
    _previousWidthInputValue = _controllerWidth.text.trim();
    _previousHeightInputValue = _controllerHeight.text.trim();
  }

  /// [ [percent0, value0, offset0],[percent1, value1, offset1] ]
  List _handleCaculateValuesAndOffsets(int index) {
    double percent0, percent1, value0, value1;
    Offset offset0, offset1; // offset of tooltip
    double passportHeight = double.parse(_controllerHeight.text.trim());
    if (_renderImage == null) {
      percent0 = percent1 = value0 = value1 = 0;
      offset0 = offset1 = offsetZero;
    } else {
      final imageHeight = _imageSize.height; //_renderImage!.size.height;
      switch (index) {
        case 0: // head
          percent0 = _offsetHead.dy / imageHeight;
          percent1 =
              (_offsetChin.dy + _heightHeadChin) / imageHeight - percent0;
          value0 = percent0 * passportHeight;
          value1 = percent1 * passportHeight;
          offset0 = Offset(0, _offsetHead.dy / 2);
          offset1 = Offset(
            0,
            _offsetHead.dy +
                _heightHeadChin +
                (_offsetChin.dy - (_offsetHead.dy + _heightHeadChin)) / 2,
          );
          break;
        case 1: // chin
          percent0 = (_offsetEyes.dy + _heightEyes / 2) / imageHeight;
          percent1 = 1 - percent0;
          value0 = percent0 * passportHeight;
          value1 = percent1 * passportHeight;
          offset0 = Offset(0, (_offsetEyes.dy + _heightEyes / 2) / 2);
          offset1 = Offset(
            0,
            _offsetEyes.dy + (imageHeight - _offsetEyes.dy) / 2,
          );
          break;
        case 2: // eyes
          percent0 =
              (_offsetChin.dy + _heightHeadChin - _offsetHead.dy).abs() /
              imageHeight;
          percent1 = 1 - (_offsetChin.dy + _heightHeadChin) / imageHeight;
          value0 = percent0 * passportHeight;
          value1 = percent1 * passportHeight;
          offset0 = Offset(
            0,
            _offsetHead.dy +
                (_offsetChin.dy - _offsetHead.dy + _heightHeadChin) / 2,
          );
          offset1 = Offset(
            0,
            _offsetChin.dy +
                (imageHeight - _offsetChin.dy + _heightHeadChin) / 2,
          );
          break;
        default:
          percent0 = percent1 = value0 = value1 = 0;
          offset0 = offset1 = offsetZero;
      }
    }
    percent0 = min(max(0, percent0), 1);
    percent1 = min(max(0, percent1), 1);
    return [
      [percent0 * 100, value0, offset0],
      [percent1 * 100, value1, offset1],
    ];
  }

  void _showDialogTooltip({
    required GlobalKey key,
    required double percentValue,
    required double unitValue,
    required int indexTooltip,
  }) {
    FocusManager.instance.primaryFocus?.unfocus();
    RenderBox renderBoxTooltip =
        key.currentContext?.findRenderObject() as RenderBox;
    final startOffset = renderBoxTooltip.localToGlobal(offsetZero);
    Offset viTriGiuaBenTraiTooltip = startOffset.translate(
      0,
      renderBoxTooltip.size.height / 2,
    );
    Offset realOffset = Offset(
      viTriGiuaBenTraiTooltip.dx - SIZE_DIALOG_TOOLTIP.width - 10,
      viTriGiuaBenTraiTooltip.dy - SIZE_DIALOG_TOOLTIP.height,
    );
    showCustomDialogWithOffset(
      context: context,
      newScreen: BodyDialogCustom(
        offset: realOffset,
        dialogWidget: BodyDialogCropGuideTooltip(
          currentUnit: INCH,
          percentValue: percentValue,
          unitValue: unitValue,
          passportHeight: double.parse(_controllerHeight.text.trim()),
          dialogSize: SIZE_DIALOG_TOOLTIP,
          onDone: (newPercent, newUnitValue) {
            List listValueHead = _handleCaculateValuesAndOffsets(0);
            List listValueEyes = _handleCaculateValuesAndOffsets(1);
            List listValueChin = _handleCaculateValuesAndOffsets(2);

            final imageHeight = _imageSize.height;
            switch (_indexFacePositionSelected) {
              case 0:
                double mainPercent = listValueHead[0][0];
                switch (indexTooltip) {
                  case 0: //ok
                    mainPercent = max(
                      0,
                      min(
                        newPercent,
                        (listValueEyes[0][0] -
                            _heightHeadChin / imageHeight * 100),
                      ),
                    ); // tru di % height cua head

                    break;
                  case 1: //ok
                    double pMax = listValueHead[0][0] + listValueHead[1][0];
                    double limitEyes =
                        listValueEyes[0][0] -
                        _heightHeadChin / imageHeight * 100;
                    mainPercent =
                        pMax - min(pMax, max(newPercent, pMax - limitEyes));
                    break;
                  default:
                    break;
                }
                _offsetHead = Offset(0, imageHeight * mainPercent / 100);
                _offsetBlueCursor = _offsetHead.translate(0, -_heightHeadChin);
                break;
              case 1:
                double mainPercent = listValueEyes[0][0];
                switch (indexTooltip) {
                  case 0: //ok
                    double pHead =
                        listValueHead[0][0] +
                        _heightHeadChin / imageHeight * 100;
                    double pChin =
                        100.0 -
                        (listValueChin[1][0] +
                            _heightHeadChin / imageHeight * 100);
                    mainPercent = min(pChin, max(newPercent, pHead));
                    break;
                  case 1: //ok
                    double pHead =
                        listValueHead[0][0] +
                        (_heightHeadChin) / imageHeight * 100;
                    double pChin =
                        100.0 -
                        (listValueChin[1][0] +
                            _heightHeadChin / imageHeight * 100);
                    mainPercent =
                        100 -
                        min(100.0 - pHead, max(newPercent, 100.0 - pChin));
                    break;
                  default:
                    break;
                }
                _offsetEyes = Offset(
                  0,
                  (imageHeight * mainPercent / 100) - _heightEyes / 2,
                );
                _offsetBlueCursor = _offsetEyes.translate(
                  0,
                  _heightEyes / 2 - _sizeBlueCursor / 2,
                );
                break;
              case 2:
                double mainPercent = listValueChin[0][0];
                switch (indexTooltip) {
                  case 0: //ok
                    double pMax = 100.0 - listValueHead[0][0];
                    double pEyes =
                        listValueEyes[0][0] +
                        (_heightHeadChin - _heightEyes / 2) / imageHeight * 100;
                    mainPercent =
                        min(pMax, max(newPercent, pEyes)) + listValueHead[0][0];
                    break;
                  case 1: //ok
                    double pMin =
                        listValueEyes[0][0] +
                        _heightHeadChin / imageHeight * 100.0;
                    double pMax = 100.0;
                    mainPercent = min(pMax, max(pMin, 100.0 - newPercent));
                    break;
                  default:
                    break;
                }
                _offsetChin = Offset(
                  0,
                  (imageHeight * mainPercent / 100) - _heightHeadChin,
                );
                _offsetBlueCursor = _offsetChin.translate(0, -2);
                break;
              default:
            }
            setState(() {});
            popNavigator(context);
          },
        ),
        scaleAlignment: Alignment.centerRight,
      ),
    );
  }

  void _onSubmitted() {
    // lay gia tri input
    double newHeight, newWidth;
    String valueHeight = _controllerHeight.text.trim();
    String valueWidth = _controllerWidth.text.trim();
    newHeight = double.parse(valueHeight);
    newWidth = double.parse(valueWidth);
    // luu tru ratio ban dau truoc khi apply height, width moi
    final oldRatioHead = 1 - _offsetHead.dy / _renderImage!.size.height;
    final oldRatioEyes =
        1 - (_offsetEyes.dy + _heightEyes / 2) / _renderImage!.size.height;
    final oldRatioChin =
        1 - (_offsetChin.dy + _heightHeadChin) / _renderImage!.size.height;
    _updateImageSize(newWidth, newHeight);
    _updateRenderBoxs();
    _updateOffsets(oldRatioHead, oldRatioEyes, oldRatioChin);
    setState(() {});
  }

  void _updateOffsets(double ratioHead, double ratioEyes, double ratioChin) {
    _initOffsets();
    // luu y: các chỉ số ratio căn theo cạnh dưới cùng
    // truong hop height qua nho(<12) -> icon Chin nam ben tren icon Head
    // if (_imageSize.height > _heightHeadChin) {
    _offsetHead = _offsetHead.translate(0, _imageSize.height * (1 - ratioHead));
    _offsetChin = _offsetChin
        .translate(0, _imageSize.height * (1 - ratioChin))
        .translate(0, -_heightHeadChin);
    // }
    // chuyen offset vao diem giua
    _offsetEyes = _offsetEyes
        .translate(0, _imageSize.height * (1 - ratioEyes))
        .translate(0, -_heightEyes / 2);
    switch (_indexFacePositionSelected) {
      case 0: // head
        _offsetBlueCursor = _offsetHead.translate(0, -(_heightHeadChin));
        break;
      case 1: // eyes
        _offsetBlueCursor = _offsetEyes.translate(0, _heightEyes / 4 - 2);
        break;
      case 2: // chin
        _offsetBlueCursor = _offsetChin.translate(0, -2);
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = BlocProvider.of<ThemeBloc>(context, listen: true).isDarkMode;
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: _avoidResizeKeyboard,
        body: Container(
          height: _size.height * 0.95,
          width: _size.width,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
          padding: EdgeInsets.only(
            bottom:
                20 + MediaQuery.of(context).padding.top, // _paddingDeviceBottom
            top:
                (_size.width > MIN_SIZE.width ? 50 : 20) +
                MediaQuery.of(context).padding.top, //_paddingDeviceTop
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // title
              // drag area:
              //  + preview image
              //  + crop eyes limit icon
              //  + crop head limit icon
              //  + crop chin limit icon
              //  + line dash
              //  + blue cursor
              //  + tooltips
              //  + line preview
              //  + dots: head, eyes, chin
              // face options
              // ++++++++++++++++++++++++++++ //
              // title
              WTextContent(
                value: "PHOTO SIZE",
                textSize: 14,
                textLineHeight: 16,
              ),
              // drag area + face options
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // drag area - set default equal _imageSizeOriginal.height, constant size after init
                  Container(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    height: _imageSizeOriginal?.height,
                    color: transparent,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        _onPanUpdate(details);
                      },
                      onTapDown: (details) {
                        _onCheckOffset(details.globalPosition);
                      },
                      onPanStart: (details) {
                        _onCheckOffset(details.globalPosition);
                      },
                      onPanEnd: (details) {
                        setState(() {
                          _isCanPan = false;
                        });
                      },
                      onTapUp: (details) {
                        setState(() {
                          _isCanPan = false;
                        });
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          // preview image
                          // preview image to get size before scale
                          Visibility(
                            visible: false,
                            maintainSize: true,
                            maintainAnimation: true,
                            maintainState: true,
                            child: Container(
                              key: _keyImage,
                              height: _imageSize.height,
                              width: _imageSize.width,
                              alignment: Alignment.bottomCenter,
                              child: Image.asset(
                                "${PATH_PREFIX_IMAGE}image_crop_man.png",
                              ),
                            ),
                          ),
                          // main scale image
                          _buildScaleImage(),
                          // crop eyes limit icon
                          _buildEyesWidget(),
                          // crop head limit icon
                          Positioned(
                            key: _keyHead,
                            top: _offsetHead.dy,
                            child: Image.asset(
                              "${PATH_PREFIX_ICON}icon_crop_head.png",
                              height: _heightHeadChin,
                              width: 100,
                              color: _indexFacePositionSelected == 0
                                  ? blue
                                  : null,
                            ),
                          ),
                          // crop chin limit icon
                          Positioned(
                            key: _keyChin,
                            top: _offsetChin.dy,
                            child: Image.asset(
                              "${PATH_PREFIX_ICON}icon_crop_chin.png",
                              height: _heightHeadChin,
                              width: 100,
                              color: _indexFacePositionSelected == 2
                                  ? blue
                                  : null,
                            ),
                          ),
                          // line dash
                          Positioned(
                            top: _offsetBlueCursor.dy + _sizeBlueCursor / 2,
                            child: SizedBox(
                              width:
                                  _size.width *
                                  _mainRatio, //  _imageSize.width,
                              child: WLineDash(
                                color: _isDarkMode
                                    ? primaryDark1
                                    : primaryLight1,
                              ),
                            ),
                          ),
                          // blue cursor
                          Positioned(
                            key: _keyCursor,
                            top: _offsetBlueCursor.dy,
                            left: _offsetBlueCursor.dx,
                            child: Container(
                              margin: const EdgeInsets.only(left: 20),
                              child: Image.asset(
                                "${PATH_PREFIX_ICON}icon_drag_custom_crop.png",
                                height: _sizeBlueCursor,
                              ),
                            ),
                          ),
                          // tooltips
                          _buildTooltipWidget(),
                          // line preview
                          _buildLinePreview(),
                          // dots: head, eyes, chin
                          if (_indexFacePositionSelected != 1)
                            Positioned(
                              top: _offsetHead.dy - _sizeDot / 2,
                              right:
                                  (_size.width * (1 - _mainRatio)) / 2 -
                                  20, // padding :20
                              child: _buildCustomDot(),
                            ),
                          if (_indexFacePositionSelected == 1)
                            Positioned(
                              top:
                                  _offsetEyes.dy +
                                  _heightEyes / 2 -
                                  _sizeDot / 2,
                              right: (_size.width * (1 - _mainRatio)) / 2 - 20,
                              child: _buildCustomDot(),
                            ),
                          if (_indexFacePositionSelected != 1)
                            Positioned(
                              top:
                                  _offsetChin.dy +
                                  _heightHeadChin -
                                  2 -
                                  _sizeDot /
                                      2, // tru 2 do icon export thừa 2 pixel
                              right: (_size.width * (1 - _mainRatio)) / 2 - 20,
                              child: _buildCustomDot(),
                            ),
                          // full screen
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // face options
                  _buildFaceOptions(),
                ],
              ),
              // edit width, height textfield
              Column(
                children: [
                  _buildEditTextFieldWidget(
                    unitKey: _keyUnitWidth,
                    title: "Width",
                    controller: _controllerWidth,
                    // controllerPrevious: _controllerWidthPrevious,
                    currentUnit: _currentUnit,
                    onTapUnitWidget: (renderBox) {
                      _showDialogUnit(renderBox);
                    },
                    onTapInput: () {
                      _onTapInput(0);
                    },
                  ),
                  WSpacer(height: 10),
                  _buildEditTextFieldWidget(
                    unitKey: _keyUnitHeight,
                    title: "Height",
                    controller: _controllerHeight,
                    // controllerPrevious: _controllerHeightPrevious,
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
              // buttons
              buildBottomButtons(context, _isDarkMode, _onSave),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaceOptions() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity:
          (_avoidResizeKeyboard
              ? MediaQuery.of(context).viewInsets.bottom < 100
              : !_avoidResizeKeyboard)
          ? 1
          : 0,
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        width: _size.width * (_mainRatio + 0.1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: LIST_POSITION_FACE.indexed.map((e) {
            final index = e.$1;
            return _buildFaceOptionItem(
              index == _indexFacePositionSelected,
              e.$2,
              () {
                _indexFacePositionSelected = index;
                _onChangeOffsetBlueCursor(_indexFacePositionSelected);
                setState(() {});
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildScaleImage() {
    return Container(
      height: _imageSize.height,
      width: _imageSize.width,
      clipBehavior: Clip.none,
      padding: const EdgeInsets.only(bottom: 2),
      decoration: const BoxDecoration(color: transparent),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            height: _imageSize.height,
            width: _imageSize.width,
            color: white,
          ),
          Positioned(
            top: _offsetHead.dy,
            left: 0,
            right: 0,
            child: Container(
              height: _imageSize.height,
              width: _imageSize.width,
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(),
              child: Transform.scale(
                alignment: Alignment.topCenter,
                scale:
                    8.12 /
                    (1843 /
                        _imageSize.height /
                        ((_offsetChin.dy - _offsetHead.dy + _heightHeadChin) /
                            _imageSize.height) *
                        _ratioHeadToChinOnMan),
                child: Image.asset(
                  height: _imageSize.height,
                  width: _imageSize.width,
                  "${PATH_PREFIX_IMAGE}image_crop_man.png",
                  alignment: Alignment.topCenter,
                  fit: BoxFit.fitHeight,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomDot() {
    return Container(
      child: buildDot(_isDarkMode ? primaryDark1 : primaryLight1, _sizeDot),
    );
  }

  Widget _buildLinePreview() {
    double widthLine = 1;
    double? top, right, bottom, left, height = 0;
    right =
        (_size.width * (1 - _mainRatio)) / 2 - 20 + (_sizeDot - widthLine) / 2;

    double imageHeight = _renderImage != null
        ? _imageSize.height
        : 0; //_renderImage!.size.height
    switch (_indexFacePositionSelected) {
      case 0: // head
        top = 0;
        height = _offsetChin.dy + _heightHeadChin - 1;
      case 1: // chin
        if (_renderImage != null) {
          height = imageHeight;
        }
      case 2: // eyes
        top = _offsetHead.dy;
        if (_renderImage != null) {
          height = imageHeight - _offsetHead.dy;
        }
      default:
    }
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: Container(
        color: _isDarkMode ? primaryDark1 : primaryLight1,
        width: widthLine,
        height: max(height - 2, 0.1),
      ),
    );
  }

  Widget _buildTooltipWidget() {
    List listValue = _handleCaculateValuesAndOffsets(
      _indexFacePositionSelected,
    );
    double percent0, percent1, value0, value1;
    Offset offset0, offset1;
    percent0 = listValue[0][0];
    value0 = listValue[0][1];
    offset0 = listValue[0][2];
    percent1 = listValue[1][0];
    value1 = listValue[1][1];
    offset1 = listValue[1][2];

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerRight,
      children: [
        buildInformationBox(
          key: _keyTooltip0,
          heightTooltip: _heightTooltip,
          isDarkMode: _isDarkMode,
          percentValue: (percent0).abs().roundWithUnit(fractionDigits: 2),
          mainValue: value0.abs().roundWithUnit(fractionDigits: 2),
          currentUnit: _currentUnit,
          offsetBox: offset0.translate(0, -_heightTooltip / 2),
          onTap: () {
            setState(() {
              _avoidResizeKeyboard = false;
            });
            _showDialogTooltip(
              key: _keyTooltip0,
              percentValue: percent0.abs(),
              unitValue: value0.abs(),
              indexTooltip: 0,
            );
          },
        ),
        buildInformationBox(
          key: _keyTooltip1,
          heightTooltip: _heightTooltip,
          isDarkMode: _isDarkMode,
          percentValue: (percent1.abs()).roundWithUnit(fractionDigits: 2),
          mainValue: (value1).abs().roundWithUnit(fractionDigits: 2),
          currentUnit: _currentUnit,
          offsetBox: offset1.translate(0, -_heightTooltip / 2),
          onTap: () {
            setState(() {
              _avoidResizeKeyboard = false;
            });
            _showDialogTooltip(
              key: _keyTooltip1,
              percentValue: percent1.abs(),
              unitValue: value1.abs(),
              indexTooltip: 1,
            );
          },
        ),
      ],
    );
  }

  Widget _buildFaceOptionItem(bool isSelected, String title, Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? _isDarkMode
                    ? primaryDark1
                    : primaryLight1
              : white,
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: WTextContent(
          value: title,
          textSize: 15,
          textLineHeight: 17.9,
          textColor: isSelected ? white : black,
        ),
      ),
    );
  }

  Widget _buildEditTextFieldWidget({
    required GlobalKey unitKey,
    required String title,
    required TextEditingController controller,
    // required TextEditingController controllerPrevious,
    required Unit currentUnit,
    required Function(RenderBox renderBox) onTapUnitWidget,
    required Function() onTapInput,
  }) {
    return SizedBox(
      width: _size.width * 0.78,
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
          WSpacer(width: 10),
          Expanded(
            child: Container(
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: TextField(
                  onTap: () {
                    onTapInput();
                    setState(() {
                      _avoidResizeKeyboard = true;
                    });

                    controller.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: controller.text.length,
                    );
                  },
                  onSubmitted: (value) {
                    _onSave();
                    setState(() {
                      _avoidResizeKeyboard = false;
                    });
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

  Widget _buildEyesWidget() {
    return Positioned(
      key: _keyEyes,
      top: _offsetEyes.dy,
      child: Container(
        width: _size.width * _mainRatio, //  _imageSize.width,
        height: _heightEyes,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _indexFacePositionSelected == 1 ? blue : black015,
            width: 2,
          ),
        ),
        child: const WLineDash(color: black015),
      ),
    );
  }
}
