import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
// import 'package:color_picker_android/color_picker_flutter.dart';
// import 'package:color_picker_android/helpers/convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_filters/flutter_image_filters.dart';
import 'package:pass1_/commons/shaders/brightness_custom.dart';
import 'package:pass1_/commons/shaders/combine_shader.dart';
import 'package:pass1_/helpers/adjust_helper.dart';
import 'package:pass1_/helpers/convert.dart';
import 'package:pass1_/helpers/generate_preview_image.dart';
import 'package:pass1_/helpers/log_custom.dart';
import 'package:pass1_/helpers/share_preferences_helpers.dart';
import 'package:pass1_/models/project_model.dart';
import 'package:pass1_/models/step_model.dart';
import 'package:pass1_/providers/blocs/device_platform_bloc.dart';
import 'package:pass1_/screens/module_home/widgets/w_footer.dart';
import 'package:pass1_/screens/sub_modules/module_adjust/helpers/ratio_to_shader.dart';
import 'package:pass1_/screens/sub_modules/module_adjust/widgets/w_original_image.dart';
import 'package:pass1_/widgets/w_circular.dart';
import 'package:pass1_/widgets/w_custom_ruler.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/helpers/contain_offset.dart';
import 'package:pass1_/helpers/navigator_route.dart';
import 'package:pass1_/models/adjust_subject_model.dart';
import 'package:pass1_/providers/blocs/adjust_subject_bloc.dart';
import 'package:pass1_/providers/blocs/theme_bloc.dart';
import 'package:pass1_/providers/events/adjust_subject_event.dart';
import 'package:pass1_/screens/sub_modules/module_adjust/widgets/w_adjust.dart';
import 'package:pass1_/screens/sub_modules/module_adjust/widgets/w_slider_color.dart';
import 'package:pass1_/widgets/w_segment_custom.dart';
import 'package:pass1_/widgets/w_spacer.dart';
import 'package:scroll_snap_list/scroll_snap_list.dart';

// ignore: must_be_immutable
class BodyAdjustTablet extends StatefulWidget {
  final ProjectModel projectModel;
  final Function(ProjectModel model) onUpdateProject;
  final Offset? offsetTrackerBrightness;
  final Function(Offset value) onUpdateOffsetTracker;
  final int indexSegment;
  final Function(int index) onUpdateSegment;
  final int indexSnapList;
  final Function(int index) onUpdateSnapList;
  TransformationController transformationController;
  final StepModel currentStep;
  final Function() onNextStep;
  // final Function(StepModel step) onSelectStep;
  final Function(bool value) onUpdateLoadingStatus;
  BodyAdjustTablet({
    super.key,
    required this.projectModel,
    required this.onUpdateProject,
    required this.offsetTrackerBrightness,
    required this.transformationController,
    required this.onUpdateOffsetTracker,
    required this.indexSegment,
    required this.onUpdateSegment,
    required this.indexSnapList,
    required this.onUpdateSnapList,
    required this.currentStep,
    required this.onNextStep,
    // required this.onSelectStep,
    required this.onUpdateLoadingStatus,
  });

  @override
  State<BodyAdjustTablet> createState() => _TestBodyAdjustTabletState();
}

class _TestBodyAdjustTabletState extends State<BodyAdjustTablet> {
  // constant
  final double _dotSize = 26;
  final double _sliderWidth = 284;
  final double _snapItemSize = 56.0;

  // importance variables
  // data
  final List<dynamic> _listBackground = List.from(LIST_BACKGROUND_ADJUST);
  late List<AdjustSubjectModel> _listSubject;
  late Offset _offsetTracker;

  // ui
  late Size _size;
  late bool isDarkMode;
  Size? _sizeConvertedImage;

  final GlobalKey _keySliderBrightness = GlobalKey(
    debugLabel: "_keySliderBrightness",
  );
  final GlobalKey _keyConvertedImage = GlobalKey(
    debugLabel: "_keyConvertedImage",
  );
  final GlobalKey _keyAdjustArea = GlobalKey(debugLabel: "_keyAdjustArea");
  late RenderBox _renderBoxBrightness;
  RenderBox? _renderBoxConvertedImage;
  late final ScrollController _controllerSnapList = ScrollController();

  late int _indexBackgroundSelected, _brightnessSelected;

  /// preview tren image, khi end gesture thi gan gia tri cho _indexSubjectSelected, tranh truong hop ruler update llien tuc khi nguoi dung cuon snap list
  late int _indexSubjectSelectedPreview;

  // dung de show slider subject slider bar
  bool? _isShowSliderSubject = true,
      _isFocusBrightness = false,
      _isFocusConvertedImage = false,
      _isLoadImageFilter;
  // original
  TextureSource? _textureOriginal, _textureConverted;
  late ui.Image _uiImageObject;
  //1
  late CustomBrightnessShaderConfiguration _brightnessShaderConfiguration;
  //2
  late CombineShaderCustomConfiguration _combineShaderCustomConfiguration;

  // dung de preview anh co kich thuoc nho hon
  File? _previewFileConverted, _previewFileOriginal;
  late ui.Image _decodedOriginalImage;
  final Size _standardOriginalImageSize = const Size(480, 640),
      _standardOriginalImageFramePreviewSize = const Size(210, 280);

  /// dựa vào preview image ban đầu: Size(480, 640) với độ blur được fix sẵn
  ///
  /// ->   tính lại tỉ lệ blur cho từng ảnh mỗi khi truyền ảnh có size khác
  Paint? _paintBlurShadowLeft, _paintBlurShadowRight;

  @override
  void initState() {
    super.initState();
    consolelog("call init adjust body");
    _listBackground.insert(0, widget.projectModel.selectedFile);
    _listBackground.add("${PATH_PREFIX_ICON}icon_background_option.png");
    _listSubject = BlocProvider.of<AdjustSubjectBloc>(
      context,
      listen: false,
    ).state.listAdjustSubjectModel;
    _indexSubjectSelectedPreview = widget.indexSnapList;
    _brightnessSelected = (widget.projectModel.brightness * _sliderWidth)
        .toInt();
    _offsetTracker =
        widget.offsetTrackerBrightness ??
        Offset(
          0.5 * _sliderWidth - _dotSize / 2 - 2,
          0,
        ); // tru 2 do border cua dot tracker
    _indexBackgroundSelected = 0;
    _initShaderConfiguration();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      _controllerSnapList.animateTo(
        (widget.indexSnapList + 1 / 2) * _snapItemSize,
        duration: const Duration(milliseconds: 10),
        curve: Curves.linear,
      );
      _renderBoxBrightness =
          _keySliderBrightness.currentContext?.findRenderObject() as RenderBox;

      _previewFileOriginal = widget.projectModel.selectedFile;
      _previewFileConverted = widget.projectModel.bgRemovedFile;

      final newIndexbg = _listBackground.indexOf(
        widget.projectModel.background,
      );
      if (newIndexbg != -1) {
        _indexBackgroundSelected = newIndexbg;
      }
      _decodedOriginalImage = await decodeImageFromList(
        widget.projectModel.bgRemovedFile!.readAsBytesSync(),
      );
      if (_decodedOriginalImage.width > 1000 &&
          _decodedOriginalImage.height > 1000) {
        double ratioWidth, ratioHeight;
        ratioHeight = 800 / _decodedOriginalImage.height;
        ratioWidth = 800 / _decodedOriginalImage.width;
        _previewFileOriginal = await generateSmallImage(
          widget.projectModel.selectedFile!.path,
          [
            _decodedOriginalImage.width.toDouble(),
            _decodedOriginalImage.height.toDouble(),
          ],
          newName: "preview_original",
          ratios: [ratioWidth, ratioHeight],
        );
        _previewFileConverted = await generateSmallImage(
          widget.projectModel.bgRemovedFile!.path,
          [
            _decodedOriginalImage.width.toDouble(),
            _decodedOriginalImage.height.toDouble(),
          ],
          newName: "preview_converted",
          ratios: [ratioWidth, ratioHeight],
        );
      }
      // chuyển xuống đây vì nếu _keyConvertedImage chưa được render ra
      // -> _sizeConvertedImage sẽ bằng 0.0 -> không thể drag image
      // (( chỉ thấy xuất hiện từ màn hình phía sau trở lại))
      _renderBoxConvertedImage =
          _keyConvertedImage.currentContext?.findRenderObject() as RenderBox;
      _sizeConvertedImage = (_renderBoxConvertedImage?.size);
      _uiImageObject = (await TextureSource.fromFile(
        widget.projectModel.bgRemovedFile!,
      )).image;
      _textureOriginal = await TextureSource.fromFile(_previewFileOriginal!);
      _textureConverted = await TextureSource.fromFile(_previewFileConverted!);
      _isLoadImageFilter = true;
      _initBlurShadowProperties();
      _onUpdateBrightnessProperty(0.0);
      setState(() {});
    });
  }

  void _initBlurShadowProperties() {
    //(480, 640) la size ảnh chuẩn với blur được định sẵn (constant.dart)
    _paintBlurShadowLeft = Paint()
      ..imageFilter = ui.ImageFilter.blur(
        sigmaX:
            _decodedOriginalImage.width / _standardOriginalImageSize.width * 15,
        sigmaY:
            _decodedOriginalImage.height /
            _standardOriginalImageSize.height *
            15,
        tileMode: TileMode.decal,
      );
    _paintBlurShadowRight = Paint()
      ..imageFilter = ui.ImageFilter.blur(
        sigmaX:
            _decodedOriginalImage.width / _standardOriginalImageSize.width * 30,
        sigmaY:
            _decodedOriginalImage.height /
            _standardOriginalImageSize.height *
            30,
        tileMode: TileMode.decal,
      );
  }

  void _onUpdateBrightnessProperty(double delta) {
    double brightnessValue = delta * 2 / 100 / 2;
    _brightnessShaderConfiguration.brightness = brightnessValue + 0.5;
    if (_indexBackgroundSelected == 0) {
      widget.onUpdateProject(
        widget.projectModel..brightness = brightnessValue + 0.5,
      );
    } else if ([1, 2, 3].contains(_indexBackgroundSelected)) {
      ///   Giảm shadow default, tăng độ trắng background default
      ///
      /// Đọ chênh lệch blur
      ///
      double _deltaBlur = 0;
      double s1 = FlutterConvert.convertMappingRange(
        -(brightnessValue - _deltaBlur),
        -0.5 - _deltaBlur,
        0.5 + _deltaBlur,
        0.02,
        0.15,
      );
      double s2 = FlutterConvert.convertMappingRange(
        -(brightnessValue - _deltaBlur),
        -0.5 - _deltaBlur,
        0.5 + _deltaBlur,
        0.02,
        0.1,
      );
      // old : 0.02 - 0.15 - 0.3  --- 0.02 - 0.1 - 0.2
      // new : 0.02 - 0.85 - 0.15 --- 0.02 - 0.06 - 0.1
      widget.onUpdateProject(widget.projectModel..listBlurShadow = [s1, s2]);
    }
  }

  void _initShaderConfiguration() {
    //1
    _brightnessShaderConfiguration = CustomBrightnessShaderConfiguration()
      ..brightness = widget.projectModel.brightness;
    //2
    _combineShaderCustomConfiguration = CombineShaderCustomConfiguration();
  }

  void _onCheckOffsetInside(Offset globalPosition) {
    // check inside brightness area
    final startOffsetBrightness = _renderBoxBrightness.localToGlobal(
      const Offset(0, 0),
    );
    final endOffsetBrightness = startOffsetBrightness.translate(
      _renderBoxBrightness.size.width,
      _renderBoxBrightness.size.height,
    );
    if (containOffset(
      globalPosition,
      startOffsetBrightness,
      endOffsetBrightness,
    )) {
      setState(() {
        _isFocusBrightness = true;
      });
      return;
    }
  }

  void _onResetStatusGesture() {
    if (_isFocusBrightness == true || _isFocusConvertedImage == true) {
      setState(() {
        _isFocusBrightness = false;
        _isFocusConvertedImage = false;
      });
    }
  }

  void _onSelectBackground(dynamic newBackground) async {
    // open sheet background
    // if (_listBackground.last == newBackground) {
    //   // lay cac mau da luu trong SharedPreferences
    //   List<String> listColorString = await SharedPreferencesHelper()
    //       .getColorSaved();
    //   List<Color> listSavedColor = listColorString
    //       .map((e) => convertHexStringToColor(e))
    //       .toList();
    //   dynamic currentColor = widget.projectModel.background;
    //   if (currentColor is File ||
    //       currentColor is String ||
    //       currentColor == null) {
    //     currentColor = isDarkMode ? black : white;
    //   }
    //   // ignore: use_build_context_synchronously
    //   showModalBottomSheet(
    //     context: context,
    //     builder: (context) {
    //       return ColorPickerTablet(
    //         currentColor: currentColor,
    //         onDone: (value) {
    //           _indexBackgroundSelected = _listBackground.length - 1;
    //           _onUpdateBackgroundProperty(value);
    //           setState(() {});
    //           popNavigator(context);
    //         },
    //         listColorSaved: listSavedColor,
    //         isLightMode: !isDarkMode,
    //         onColorSave: (color) async {
    //           if (color == null) return;
    //           if (listSavedColor.contains(color)) {
    //             listSavedColor = List.from(
    //               listSavedColor.where((element) => element != color).toList(),
    //             );
    //           } else {
    //             listSavedColor = [color, ...List.from(listSavedColor)];
    //           }
    //           await SharedPreferencesHelper().updateColorSaved(
    //             listSavedColor.map((e) => convertColorToHexString(e)).toList(),
    //           );
    //         },
    //       );
    //     },
    //     isScrollControlled: true,
    //     backgroundColor: transparent,
    //   );
    //   return;
    // }
    // final index = _listBackground.indexOf(newBackground);
    // if (index != -1) {
    //   _indexBackgroundSelected = index;
    // }
    // _onUpdateBackgroundProperty(newBackground);
    // setState(() {});
  }

  void _onUpdateOffset(Offset globalPosition) {
    if (_isFocusBrightness == true) {
      final newOffset = _renderBoxBrightness.globalToLocal(globalPosition);
      final sliderWidth = _renderBoxBrightness.size.width - _dotSize - 4;
      double dx = max(0, min(newOffset.dx - _dotSize / 2 - 2, sliderWidth));
      _offsetTracker = Offset(dx, 0);
      _brightnessSelected = ((dx / sliderWidth) * 100).toInt();
      double delta = (_brightnessSelected - 50);
      widget.onUpdateOffsetTracker(_offsetTracker);
      _onUpdateBrightnessProperty(delta);
    }
  }

  void _onUpdateBackgroundProperty(dynamic value) {
    final oldBgValue = widget.projectModel.background;
    widget.onUpdateProject(widget.projectModel..background = value);
    if (oldBgValue != value) {
      // check xem co trung voi gia tri background hien tai hay khong
      _onUpdateBrightnessProperty(0.0);
      _offsetTracker = Offset(0.5 * _sliderWidth - _dotSize / 2 - 2, 0);
    }
    setState(() {});
  }

  void _onUpdateAdjustProperty() {
    List<double> listValue = convertRatioToShaderValue(_listSubject);
    _combineShaderCustomConfiguration.updateValues(listValue);
  }

  Future _onExportAdjust() async {
    await AdjustHelpers.onExportAdjust(
      projectModel: widget.projectModel,
      listValueForShader: convertRatioToShaderValue(_listSubject),
      brightnessShaderConfiguration: _brightnessShaderConfiguration,
      keyConvertedImage: _keyConvertedImage,
      combineShaderCustomConfiguration: _combineShaderCustomConfiguration,
      indexBackgroundSelected: _indexBackgroundSelected,
      imageSize: _getImageSize(),
      transformationController: widget.transformationController,
      newSizeConvertedImage: _sizeConvertedImage!,
      standardOriginalImageFramePreviewSize:
          _standardOriginalImageFramePreviewSize,
      onUpdateProject: widget.onUpdateProject,
      paintBlurShadowLeft: _paintBlurShadowLeft,
      paintBlurShadowRight: _paintBlurShadowRight,
    );
    setState(() {});
  }

  Size _getImageSize() {
    double imageHeight = _sizeConvertedImage!.height;
    double imageWidth = _sizeConvertedImage!.width;
    if (imageHeight == 0.0 || imageWidth == 0.0) {
      consolelog("_getImageSize $_sizeConvertedImage");
      final renderBox =
          _keyConvertedImage.currentContext?.findRenderObject() as RenderBox;
      imageHeight = renderBox.size.height;
      imageWidth = renderBox.size.width;
    }
    var abc = Size(imageWidth, imageHeight);
    consolelog("abc ${abc}");
    return abc;
  }

  @override
  Widget build(BuildContext context) {
    consolelog(
      "_renderBoxConvertedImage?.size ${widget.transformationController}",
    );

    _size = MediaQuery.sizeOf(context);
    isDarkMode = BlocProvider.of<ThemeBloc>(context).isDarkMode;
    bool isPhone = BlocProvider.of<DevicePlatformCubit>(context).isPhone;

    _listSubject = BlocProvider.of<AdjustSubjectBloc>(
      context,
      listen: true,
    ).state.listAdjustSubjectModel;
    Size _mainSize;
    _mainSize = isPhone ? _size : Size(SIZE_EXAMPLE.width, _size.height);
    return GestureDetector(
      key: _keyAdjustArea,
      onPanStart: (details) {
        if (widget.indexSegment == 0) {
          _onCheckOffsetInside(details.globalPosition);
        }
      },
      onPanUpdate: (details) {
        if (widget.indexSegment == 0) {
          _onUpdateOffset(details.globalPosition);
        }
      },
      onPanEnd: (details) {
        if (widget.indexSegment == 0) {
          _onResetStatusGesture();
        }
      },
      onTapUp: (details) {
        if (widget.indexSegment == 0) {
          _onUpdateOffset(details.globalPosition);
          _onResetStatusGesture();
        }
      },
      onTapDown: (details) {
        if (widget.indexSegment == 0) {
          _onCheckOffsetInside(details.globalPosition);
        }
      },
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                /// flow:
                /// + khi người dùng drag, chọn bg, thay đổi brightnesss và adjust properties properties ( sau khi end )
                /// + sau khi ui đã đươc binding lần đầu
                /// ==> export image
                ///
                // header
                // image (images original, preview original, preview converted + title for adjust properties)
                //_indexCurrentSegment == 0
                // background options
                // brightness slider
                // _indexCurrentSegment == 1
                // segment
                // footer
                WSpacer(height: 10),
                // image
                Expanded(
                  child: Center(
                    child: Stack(
                      children: [
                        // images original, preview original, preview converted
                        Container(
                          constraints: _mainSize.height <= MIN_SIZE.height
                              ? const BoxConstraints(
                                  minHeight: 100,
                                  minWidth: 100,
                                  maxHeight: 220,
                                  maxWidth: 220,
                                )
                              : const BoxConstraints(
                                  maxHeight: 280,
                                  maxWidth: 280,
                                ),
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // start original image
                              Image.file(
                                key:
                                    _keyConvertedImage, // dat key tai day vi cac anh duoc xep chong len nhau
                                widget.projectModel.selectedFile!,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                                color: widget.projectModel.background is Color
                                    ? widget.projectModel.background
                                    : null,
                              ),
                              // ( include gradient, noise, color )
                              _buildImageOriginal(),
                              // preview original with small image, apply for indexBG = 0,
                              // and only have brightness configuration
                              if (_isLoadImageFilter == true &&
                                  widget.projectModel.background is! Color)
                                Positioned.fill(
                                  child: ImageShaderPreview(
                                    texture: _textureOriginal!,
                                    configuration:
                                        _brightnessShaderConfiguration,
                                  ),
                                ),
                              // - original image background when indexBG = 0
                              // - another background (color, color from picker)
                              //   --> ( include shadows, reflection, human ) at indexBG == 1,2,3
                              (_isLoadImageFilter == true)
                                  ? LayoutBuilder(
                                      builder: (context, constraints) {
                                        Size size = _getImageSize();
                                        return _indexBackgroundSelected == 0
                                            ? SizedBox(
                                                height: size.height,
                                                width: size.width,
                                                child: ImageShaderPreview(
                                                  texture: _textureConverted!,
                                                  configuration:
                                                      _combineShaderCustomConfiguration,
                                                ),
                                              )
                                            : SizedBox(
                                                height: size.height,
                                                width: size.width,
                                                child: InteractiveViewer(
                                                  boundaryMargin:
                                                      EdgeInsets.symmetric(
                                                        vertical:
                                                            ((_sizeConvertedImage
                                                                    ?.height) ??
                                                                _mainSize
                                                                    .height) /
                                                            2,
                                                        horizontal:
                                                            ((_sizeConvertedImage
                                                                    ?.width) ??
                                                                _mainSize
                                                                    .width) /
                                                            2,
                                                      ),
                                                  panEnabled: false,
                                                  scaleEnabled: false,
                                                  transformationController: widget
                                                      .transformationController,
                                                  child: _buildInteractiveChild(
                                                    imageHeight: size.height,
                                                    imageWidth: size.width,
                                                  ),
                                                ),
                                              );
                                      },
                                    )
                                  : const CustomLoadingIndicator(),
                            ],
                          ),
                        ),
                        // title for adjust properties
                        if (widget.indexSegment == 1)
                          Positioned.fill(
                            child: buildAdjustSubjectTitlePreview(
                              isDarkMode: isDarkMode,
                              model: _listSubject[_indexSubjectSelectedPreview],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // _indexCurrentSegment == 0
                // { include background options, brightness slider }
                Visibility(
                  visible: widget.indexSegment == 0,
                  maintainState: true,
                  child: Column(
                    children: [
                      // background options
                      Container(
                        margin: const EdgeInsets.only(bottom: 19),
                        height: 46,
                        width: 262,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _listBackground.map((e) {
                            File? image;
                            Color? color;
                            String? mediaSrc;
                            if (e is File) image = e;
                            if (e is Color) color = e;
                            if (e is String) mediaSrc = e;
                            bool isSelected = false;
                            if (_indexBackgroundSelected != -1) {
                              isSelected =
                                  _listBackground[_indexBackgroundSelected] ==
                                  e;
                            }
                            Color? selectedColor;
                            if (mediaSrc is String &&
                                _indexBackgroundSelected == 4 &&
                                widget.projectModel.background is Color) {
                              selectedColor = widget.projectModel.background;
                            }
                            return buildBackgroundOptionItem(
                              context: context,
                              isSelected: isSelected,
                              onTap: () {
                                _onSelectBackground(e);
                              },
                              size: 46,
                              image: image,
                              color: color,
                              mediaSrc: mediaSrc,
                              selectedColor: selectedColor,
                            );
                          }).toList(),
                        ),
                      ),
                      // brightness slider
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: SliderColor(
                          key: _keySliderBrightness,
                          dotSize: _dotSize,
                          listGradientColor: const [
                            Color.fromRGBO(212, 215, 241, 1),
                            white,
                          ],
                          offsetTracker: _offsetTracker,
                          sliderWidth: _sliderWidth,
                        ),
                      ),
                    ],
                  ),
                ),
                // _indexCurrentSegment == 1
                // { include subjects( snap list ), slider subject ( ruler ) }
                Visibility(
                  visible: widget.indexSegment == 1,
                  maintainState: true,
                  child: SizedBox(
                    width: _mainSize.width,
                    child: Column(
                      children: [
                        // subjects
                        Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          height: 40,
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification is ScrollEndNotification) {
                                _isShowSliderSubject = true;
                                widget.onUpdateSnapList(
                                  _indexSubjectSelectedPreview,
                                );
                              }
                              if (notification is ScrollStartNotification) {
                                _isShowSliderSubject = false;
                              }
                              return true;
                            },
                            child: ScrollSnapList(
                              itemBuilder: (context, index) {
                                return buildAdjustSubjectItem(
                                  isDarkMode,
                                  index == _indexSubjectSelectedPreview,
                                  _listSubject[index],
                                  () {},
                                );
                              },
                              listController: _controllerSnapList,
                              itemCount: _listSubject.length,
                              itemSize: _snapItemSize,
                              duration: 250,
                              updateOnScroll: true,
                              focusOnItemTap: true,
                              dispatchScrollNotifications: true,
                              scrollPhysics:
                                  const AlwaysScrollableScrollPhysics(),
                              onItemFocus: (index) {
                                _indexSubjectSelectedPreview = index;
                                setState(() {});
                              },
                            ),
                          ),
                        ),
                        // slider subject
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: _isShowSliderSubject! ? 1 : 0.4,
                          child: WRulerCustom(
                            color: isDarkMode ? white : black,
                            instructionRatioValue:
                                _listSubject[widget.indexSnapList]
                                    .rootRatioValue,
                            currentRatioValue:
                                _listSubject[widget.indexSnapList]
                                    .currentRatioValue,
                            dividers:
                                _listSubject[widget.indexSnapList].dividers,
                            onValueChange: (newRatio) {
                              AdjustSubjectModel newModel =
                                  _listSubject[widget.indexSnapList].copyWith(
                                    currentRatioValue: newRatio,
                                  );
                              BlocProvider.of<AdjustSubjectBloc>(
                                context,
                              ).add(UpdateAdjustSubjectEvent(model: newModel));
                              _onUpdateAdjustProperty();
                            },
                            checkPointColor: isDarkMode
                                ? Colors.yellow
                                : Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // segment
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  width: 300,
                  height: 36,
                  child: buildSegmentControl(
                    context: context,
                    groupValue: widget.indexSegment,
                    listSegment: {0: "Background", 1: "Adjust"},
                    onValueChanged: (value) {
                      if (widget.indexSegment == value) return;
                      widget.onUpdateSegment(value!);
                    },
                    unactiveTextColor: isDarkMode
                        ? white05
                        : Theme.of(context).textTheme.bodySmall!.color,
                  ),
                ),
              ],
            ),
          ),
          // footer
          WFooter(
            projectModel: widget.projectModel,
            currentStep: widget.currentStep,
            isDarkMode: isDarkMode,
            onNext: () async {
              widget.onUpdateLoadingStatus(true);
              await _onExportAdjust();
              widget.onNextStep();
              widget.onUpdateLoadingStatus(false);
            },
            isHaveSettingButton: false,
            footerHeight: 166,
          ),
        ],
      ),
    );
  }

  Widget _buildImageOriginal() {
    if ([1, 2, 3].contains(_indexBackgroundSelected) &&
        _isLoadImageFilter == true) {
      Size size = _getImageSize();
      return buildImageOriginal(
        projectModel: widget.projectModel,
        imageHeight: size.height,
        imageWidth: size.width,
      );
    }
    return const SizedBox();
  }

  Widget _buildInteractiveChild({double? imageHeight, double? imageWidth}) {
    consolelog(
      "_decodedOriginalImage ${_decodedOriginalImage}-${imageWidth}-${imageWidth}",
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if ([1, 2, 3].contains(_indexBackgroundSelected) &&
            _isLoadImageFilter == true)
          Stack(
            clipBehavior: Clip.none,
            children: [
              buildBlurShadowImage(
                _uiImageObject,
                imageHeight,
                imageWidth,
                (_paintBlurShadowLeft ?? PAINT_BLURREDRED_SHADOW_LEFT)
                  ..colorFilter = ColorFilter.mode(
                    black.withValues(
                      alpha: widget.projectModel.listBlurShadow[0],
                    ),
                    BlendMode.srcIn,
                  ),
                top:
                    SHADOW_EDGE_INSET_LEFT.top /
                    _standardOriginalImageFramePreviewSize.height *
                    imageHeight!,
                left:
                    SHADOW_EDGE_INSET_LEFT.left /
                    _standardOriginalImageFramePreviewSize.width *
                    imageWidth!,
              ),
              buildBlurShadowImage(
                _uiImageObject,
                imageHeight,
                imageWidth,
                (_paintBlurShadowRight ?? PAINT_BLURREDRED_SHADOW_RIGHT)
                  ..colorFilter = ColorFilter.mode(
                    black.withValues(
                      alpha: widget.projectModel.listBlurShadow[1],
                    ),
                    BlendMode.srcIn,
                  ),
                top:
                    SHADOW_EDGE_INSET_RIGHT.top /
                    _standardOriginalImageFramePreviewSize.height *
                    imageHeight,
                left:
                    SHADOW_EDGE_INSET_RIGHT.left /
                    _standardOriginalImageFramePreviewSize.width *
                    imageWidth,
              ),
              buildBlursReflection(_uiImageObject, imageHeight, imageWidth),
            ],
          ),
        SizedBox(
          height: imageHeight,
          width: imageWidth,
          child: ImageShaderPreview(
            texture: _textureConverted!,
            configuration: _combineShaderCustomConfiguration,
          ),
        ),
      ],
    );
  }
}
