import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass1_/helpers/size_helpers.dart';
import 'package:pass1_/helpers/contain_offset.dart';
import 'package:pass1_/helpers/export_images/export_cropped.dart';
import 'package:pass1_/helpers/log_custom.dart';
import 'package:pass1_/helpers/native_bridge/method_channel.dart';
import 'package:pass1_/helpers/share_preferences_helpers.dart';
import 'package:pass1_/models/project_model.dart';
import 'package:pass1_/models/step_model.dart';
import 'package:pass1_/providers/blocs/device_platform_bloc.dart';
import 'package:pass1_/screens/module_home/widgets/w_footer.dart';
import 'package:pass1_/screens/sub_modules/module_crop/widgets/w_arrange_face.dart';
import 'package:pass1_/screens/sub_modules/module_crop/widgets/w_radian_preview.dart';
import 'package:pass1_/widgets/w_custom_painter.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/models/country_passport_model.dart';
import 'package:pass1_/models/crop_model.dart';
import 'package:pass1_/providers/blocs/country_bloc.dart';
import 'package:pass1_/providers/blocs/theme_bloc.dart';
import 'package:pass1_/screens/sub_modules/module_crop/widgets/w_dialog_country.dart';
import 'package:pass1_/widgets/w_circular.dart';
import 'package:pass1_/widgets/w_custom_ruler.dart';
import 'package:path_provider/path_provider.dart';

class BodyCropTest extends StatefulWidget {
  final ProjectModel projectModel;
  final Size imageSelectedSize;
  final Size screenSize;
  final Matrix4 matrix4;
  final Function(CropModel? cropModel) onUpdateCropModel;
  final Function(Matrix4 matrix) onUpdateMatrix;
  final void Function(ProjectModel projectModel) onUpdateProject;
  final StepModel currentStep;
  final Function() onUpdateStep;
  final Function(StepModel stepModel) onSelectStep;
  final ui.Image? uiImageAdjusted;
  final Function(bool value) onUpdateLoadingStatus;
  const BodyCropTest({
    super.key,
    required this.projectModel,
    required this.imageSelectedSize,
    required this.screenSize,
    required this.matrix4,
    required this.onUpdateProject,
    required this.onUpdateMatrix,
    required this.onUpdateCropModel,
    required this.currentStep,
    required this.onUpdateStep,
    required this.onSelectStep,
    required this.uiImageAdjusted,
    required this.onUpdateLoadingStatus, // tranh viec moi lan setState tai file nay dan den viec phai doijw readUnit8ListSync() delay -> loi setState or mark ....
  });

  @override
  State<BodyCropTest> createState() => _BodyCropTestState();
}

class _BodyCropTestState extends State<BodyCropTest>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  double _mainRatio = 0.585;
  // main variables
  late CropModel _cropModel;
  late List<CountryModel> _listCountryModel;

  // keys
  final GlobalKey _keyCrop = GlobalKey(debugLabel: "_keyCrop");
  final GlobalKey _keyImage = GlobalKey(debugLabel: "_keyImage");
  final GlobalKey _keyCountryDialog =
      GlobalKey(debugLabel: "_keyCountryDialog");
  // another
  late Size _cropHoleSize, _cropHoleSizeOriginal;
  bool _isOpenCountryDialog = false, _isGesturingImage = false;
  late AnimationController animationController;

  bool _isPhone = true;

  late Rect _rectImage;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _listCountryModel = BlocProvider.of<CountryBloc>(context).state.listCountry;
    if (_listCountryModel.isEmpty) {
      _listCountryModel = LIST_COUNTRY_PASSPORT;
    }
    _isPhone = BlocProvider.of<DevicePlatformCubit>(context).isPhone;
    double singleSize = widget.screenSize.width * _mainRatio;
    // widget.screenSize.height > MIN_SIZE.height
    //     ? _isPhone
    //         ? 274
    //         : 300
    //     :
    // widget.screenSize.width * _mainRatio;
    double widthCropHole, heightCropHole;
    PassportModel currentPassport =
        widget.projectModel.countryModel!.currentPassport;
    double ratioCurrentPassport = currentPassport.aspectRatio;
    if (ratioCurrentPassport < 1) {
      heightCropHole = singleSize;
      widthCropHole = singleSize * ratioCurrentPassport;
    } else if (ratioCurrentPassport > 1) {
      heightCropHole = singleSize / ratioCurrentPassport;
      widthCropHole = heightCropHole * ratioCurrentPassport;
    } else {
      widthCropHole = heightCropHole = singleSize;
    }

    /// Update crop size
    _cropHoleSizeOriginal = Size(singleSize, singleSize);
    _cropHoleSize = Size(widthCropHole, heightCropHole);

    if (widget.projectModel.cropModel != null) {
      _cropModel = widget.projectModel.cropModel!.copyWith();
    } else {
      double imageWidth, imageHeight;
      double ratioImage = widget.imageSelectedSize.aspectRatio;

      if (ratioImage > ratioCurrentPassport) {
        imageHeight = heightCropHole;
        imageWidth = imageHeight * ratioImage;
      } else if (ratioImage < ratioCurrentPassport) {
        imageWidth = widthCropHole;
        imageHeight = imageWidth / ratioImage;
      } else {
        imageWidth = widthCropHole;
        imageHeight = heightCropHole;
      }

      _cropModel = CropModel.create(
        instructionRotateValue: 0.5,
        currentRotateValue: 0.5,
        cropRect: Rect.fromCenter(
          center: Offset(widget.screenSize.width, widget.screenSize.height),
          width: imageWidth,
          height: imageHeight,
        ),
      );
    }
  }

  Future<void> _onExportCropped() async {
    if (widget.projectModel.uiImageAdjusted == null) return;
    final renderderBoxImage = _keyImage.currentContext?.size;
    throw Exception("_onExportCropped chua lam");
    // export cropped image
    // (File, ui.Image) result = await exportCroppedImage(
    //   uiImageAdjusted: widget.projectModel.uiImageAdjusted!,
    //   countryModel: widget.projectModel.countryModel!,
    //   scaleByInteractView: _transformImageController.value.getMaxScaleOnAxis(),
    //   rotation: max(
    //           -45.000001,
    //           min(
    //               45.000001,
    //               ((_cropModel!.currentRotateValue -
    //                       _cropModel!.instructionRotateValue) *
    //                   90))) *
    //       pi /
    //       180,
    //   matrix: _transformImageController.value,
    //   imageSizePreview: renderderBoxImage!,
    //   frameSize: _cropHoleSize,
    // );

    // consolelog("result result ${result}");
    // widget.onUpdateProject(
    //   widget.projectModel
    //     ..croppedFile = result.$1
    //     ..uiImageCropped = result.$2
    //     ..scaledCroppedImage = null,
    // );
    // // widget.onUpdateMatrix(_transformImageController.value);
    // widget.onUpdateCropModel(_cropModel);

    // File? scaleCroppedFile = await _handleGenerateScaledCroppedImage(
    //   result.$1 ,
    //   Size(
    //     result.$2.width.toDouble(),
    //     result.$2.height.toDouble(),
    //   ),
    // );
    // ui.Image image1 =
    //     await decodeImageFromList(scaleCroppedFile!.readAsBytesSync());
    // widget.onUpdateProject(
    //   widget.projectModel..scaledCroppedImage = image1,
    // );
  }

  Future<File?> _handleGenerateScaledCroppedImage(
    File? croppedImage,
    Size imageCroppedSize,
  ) async {
    if (croppedImage == null) return null;
    String scaleCroppedImagePath =
        "${(await getExternalStorageDirectory())!.path}/scaled_cropped.png";
    Size newSize = FlutterSizeHelpers.handleScaleWithSpecialDimension(
      originalSize: imageCroppedSize,
    );
    var result = await MyMethodChannel.resizeAndResoluteImage(
      inputPath: croppedImage.path,
      format: 1,
      listWH: [newSize.width, newSize.height],
      scaleWH: [1, 1],
      outPath: scaleCroppedImagePath,
      quality: 90,
    );
    consolelog("result result result ${result}");
    return result;
  }

  void _onShowFullImage(bool value) {
    _isGesturingImage = value;
    setState(() {});
  }

  void _onRulerChange(double value) {
    _isGesturingImage = true;
    final ratio = _cropHoleSizeOriginal.width / _cropHoleSizeOriginal.height;
    if (_cropModel != null) {
      _cropModel!.currentRotateValue = value;
      final deltaRotate = value - _cropModel!.instructionRotateValue;
      final scale = ((deltaRotate) * 90).clamp(-45, 45);
      // _cropModel!.scale = max(ratio, 1 / ratio) *
      //     cos((45 - scale.abs()) * pi / 180) /
      //     (cos(45 * pi / 180));
    }
    setState(() {});
  }

  // change hole size
  Future<void> _onChangePassport(CountryModel value) async {
    // gia tri Country cu -> dung de so sanh xem co thuc su thay doi Country hay khong
    CountryModel currentCountryModel = widget.projectModel.countryModel!;
    if (value.id == ID_CUSTOM_COUNTRY_MODEL) {
      widget.onUpdateProject(widget.projectModel..countryModel = value);
    } else {
      if (widget.projectModel.countryModel!.id != value.id ||
          (widget.projectModel.countryModel!.id == value.id &&
              currentCountryModel.indexSelectedPassport !=
                  value.indexSelectedPassport)) {
        widget.onUpdateProject(widget.projectModel..countryModel = value);
      }
    }
    CountryModel newCountryModel = widget.projectModel.countryModel!;
    final ratioWH = newCountryModel.currentPassport.width /
        newCountryModel.currentPassport.height;
    double newWidth = _cropHoleSizeOriginal.width,
        newHeight = _cropHoleSizeOriginal.height;
    if (ratioWH < 1) {
      newWidth = _cropHoleSizeOriginal.width * ratioWH;
    } else if (ratioWH > 1) {
      newHeight = _cropHoleSizeOriginal.height * (1 / ratioWH);
    }
    _cropHoleSize = Size(newWidth, newHeight);
    setState(() {});
    // add to share pref
    await SharedPreferencesHelper().updateCountryPassport(value);
  }

  RenderBox? _renderBoxCountryDialog, _renderBoxImage, _renderBoxCrop;

  void _initRenderBoxsWhenNull() {
    _renderBoxCountryDialog ??=
        _keyCountryDialog.currentContext?.findRenderObject() as RenderBox?;
    _renderBoxImage ??=
        _keyImage.currentContext?.findRenderObject() as RenderBox?;
    _renderBoxCrop ??=
        _keyCrop.currentContext?.findRenderObject() as RenderBox?;
  }

  void _onStartGesture(Offset globalPosition) {
    _initRenderBoxsWhenNull();
    if (_renderBoxCountryDialog == null) {
      throw Exception("_renderBoxCountryDialog is null");
    }
    final Offset startGlobalCountryOffset =
        _renderBoxCountryDialog!.localToGlobal(const Offset(0, 0));
    final endGlobalCountryOffset = startGlobalCountryOffset.translate(
      _renderBoxCountryDialog!.size.width,
      _renderBoxCountryDialog!.size.height,
    );
    bool isTapCountryDialog = containOffset(
        globalPosition, startGlobalCountryOffset, endGlobalCountryOffset);
    if (isTapCountryDialog) {
      if (!_isOpenCountryDialog) {
        _isOpenCountryDialog = true;
        _isGesturingImage = false;
        setState(() {});
        return;
      }
    } else {
      _isOpenCountryDialog = false;
      // check gesture image
      if (_renderBoxCrop == null) {
        throw Exception("_renderBoxCrop is null");
      }
      final Offset startGlobalCropOffset =
          _renderBoxCrop!.localToGlobal(const Offset(0, 0));
      final endGlobalCropOffset = startGlobalCropOffset.translate(
        _renderBoxCrop!.size.width,
        _renderBoxCrop!.size.height,
      );
      bool isTapHoleArea = containOffset(
        globalPosition,
        startGlobalCropOffset,
        endGlobalCropOffset,
      );
      consolelog("isTapHoleArea: $isTapHoleArea");
      if (isTapHoleArea) {
        _isOpenCountryDialog = false;
        _isGesturingImage = true;
        setState(() {});
      } else {
        _isOpenCountryDialog = false;
        _isGesturingImage = false;
        setState(() {});
      }
    }
  }

  void _onTapUp(TapUpDetails details) {
    _onStartGesture(details.globalPosition);
  }

  void _onScaleStart(ScaleStartDetails details) {
    consolelog("_onScaleStart call");
    _onStartGesture(details.focalPoint);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {}

  void _onScaleEnd(ScaleEndDetails details) {
    _isGesturingImage = false;
    setState(() {});
  }x

  @override
  Widget build(BuildContext context) {
    bool isDarkMode =
        BlocProvider.of<ThemeBloc>(context, listen: false).isDarkMode;
    bool isPhone =
        BlocProvider.of<DevicePlatformCubit>(context, listen: false).isPhone;
    return GestureDetector(
      onTapUp: _onTapUp,
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: _onScaleEnd,
      child: Container(
        color: transparent,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Column(
              children: [
                // body
                Expanded(
                  child: Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(),
                    child: Stack(
                      key: _keyCrop,
                      clipBehavior: Clip.antiAlias,
                      alignment: Alignment.center,
                      children: [
                        // image
                        // goo hole
                        // rectangle frame
                        // crop guide
                        // country dialog
                        // ruler
                        // face arrange + gesture area
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              color: black,
                              height: _cropHoleSize.height,
                              width: _cropHoleSize.width,
                            ),
                            // image
                            AnimatedOpacity(
                              opacity: _isGesturingImage ? 1 : 0,
                              duration: const Duration(milliseconds: 300),
                              child: _buildImage(
                                clipBehavior: Clip.none,
                              ),
                            ),
                            // goo hole
                            AnimatedOpacity(
                              opacity: _isGesturingImage ? 0.4 : 1,
                              duration: const Duration(milliseconds: 300),
                              child: CustomPaint(
                                painter: HolePainter(
                                  backgroundColor:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  targetSize: _cropHoleSize,
                                ),
                                size: MediaQuery.sizeOf(context),
                              ),
                            ),
                            // dat hinh anh o day de lang nghe cu chi cua nguoi dung -> sau do ap dung vao anh ben tren de rotate, scale, tranform,...
                            _buildImage(
                                clipBehavior: Clip.hardEdge, key: _keyImage),
                            // rectangle frame
                            CustomPaint(
                              painter: FrameHolePainter(
                                targetSize: _cropHoleSize,
                                lineColor: isDarkMode ? white : black,
                              ),
                            ),
                          ],
                        ),
                        //country dialog + slider ruler
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // country dialog
                            Container(
                              margin: const EdgeInsets.only(top: 20),
                              child: WDialogCountry(
                                key: _keyCountryDialog,
                                isOpen: _isOpenCountryDialog,
                                onClose: () {},
                                onSelect: (value) {
                                  _onChangePassport(value);
                                },
                                listCountryModel: _listCountryModel,
                                countrySelected:
                                    widget.projectModel.countryModel!,
                              ),
                            ),
                            // slider ruler
                            Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                buildPreviewRadianWidget(
                                    context, isDarkMode, _cropModel),
                                WRulerCustom(
                                  color: isDarkMode ? white : black,
                                  checkPointColor:
                                      isDarkMode ? primaryDark1 : primaryLight1,
                                  instructionRatioValue:
                                      _cropModel.instructionRotateValue ?? 0.5,
                                  currentRatioValue:
                                      _cropModel.currentRotateValue ?? 0.5,
                                  dividers: 180,
                                  onValueChange: (value) {
                                    _onRulerChange(value);
                                  },
                                  onEnd: (value) {
                                    _onShowFullImage(false);
                                  },
                                )
                              ],
                            ),
                          ],
                        ),
                        // face arrange + gesture area
                        Center(
                          child: SizedBox(
                            height: _cropHoleSize.height,
                            width: _cropHoleSize.width,
                            child: WFaceArrangeComponents(
                              projectModel: widget.projectModel,
                              frameSize: _cropHoleSize,
                              opacity: _isGesturingImage ? 1 : 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // footer
                WFooter(
                  projectModel: widget.projectModel,
                  currentStep: widget.currentStep,
                  isDarkMode: isDarkMode,
                  onNext: () async {
                    widget.onUpdateLoadingStatus(true);
                    await _onExportCropped();
                    await widget.onUpdateStep();
                    widget.onUpdateLoadingStatus(false);
                  },
                  footerHeight: isPhone ? null : 166,
                  isHaveSettingButton: isPhone ? true : false,
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage({required Clip clipBehavior, Key? key}) {
    if (widget.projectModel.uiImageAdjusted == null) {
      return const CustomLoadingIndicator();
    }

    return RotationTransition(
      turns: AlwaysStoppedAnimation(
          _cropModel.currentRotateValue - _cropModel.instructionRotateValue),
      child: Transform.scale(
          scale: 1,
          child: widget.uiImageAdjusted != null
              ? RawImage(
                  image: widget.uiImageAdjusted!,
                  key: key,
                  height: _cropModel.size.height,
                  width: _cropModel.size.width,
                  fit: BoxFit.fill,
                )
              : Image.memory(
                  key: key,
                  widget.projectModel.selectedFile!.readAsBytesSync(),
                  gaplessPlayback: true,
                  height: _cropModel.size.height,
                  width: _cropModel.size.width,
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                    return child;
                  },
                  fit: BoxFit.fill,
                )),
    );

    // if (widget.projectModel.uiImageAdjusted == null) {
    //   return const CustomLoadingIndicator();
    // }
    // double degree;
    // if (_cropModel == null) {
    //   degree = 0.0;
    // } else {
    //   degree = (_cropModel!.currentRotateValue -
    //           _cropModel!.instructionRotateValue) /
    //       4; // *90/360
    // }
    // return SizedBox(
    //   height: _cropHoleSize.height,
    //   width: _cropHoleSize.width,
    //   child: InteractiveViewer(
    //     boundaryMargin: EdgeInsets.symmetric(
    //       horizontal:
    //           _cropModel != null ? (_cropModel!.width * 3 / 4) : 500,
    //       vertical:
    //           _cropModel != null ? (_cropModel!.height * 3 / 4) : 500,
    //     ),
    //     transformationController: _transformImageController,
    //     clipBehavior: clipBehavior,
    //     minScale: 1,
    //     maxScale: 10,
    //     interactionEndFrictionCoefficient: 1001,
    //     onInteractionStart: _onInteractionStart,
    //     onInteractionEnd: _onInteractionEnd,
    //     onInteractionUpdate: _onInteractionUpdate,
    //     child: OverflowBox(
    //       alignment: Alignment.center,
    //       minWidth: 0.0,
    //       minHeight: 0.0,
    //       maxWidth: double.infinity,
    //       maxHeight: double.infinity,
    //       child: RotationTransition(
    //         turns: AlwaysStoppedAnimation(degree),
    //         child: Transform.scale(
    //             scale: 1,
    //             child: widget.uiImageAdjusted != null
    //                 ? RawImage(
    //                     image: widget.uiImageAdjusted!,
    //                     key: key,
    //                     height: _cropModel?.size.height,
    //                     width: _cropModel?.size.width,
    //                     fit: BoxFit.fill,
    //                   )
    //                 : Image.memory(
    //                     key: key,
    //                     widget.projectModel.selectedFile!.readAsBytesSync(),
    //                     gaplessPlayback: true,
    //                     height: _cropModel?.size.height,
    //                     width: _cropModel?.size.width,
    //                     frameBuilder:
    //                         (context, child, frame, wasSynchronouslyLoaded) {
    //                       return child;
    //                     },
    //                     fit: BoxFit.fill,
    //                   )),
    //       ),
    //     ),
    //   ),
    // );
  }
}
