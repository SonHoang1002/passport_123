import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass1_/a_test/size_helpers.dart';
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

class BodyCrop extends StatefulWidget {
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
  const BodyCrop({
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
  State<BodyCrop> createState() => _BodyCropState();
}

class _BodyCropState extends State<BodyCrop>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  double _mainRatio = 0.585;
  // main variables
  CropModel? _cropModel;
  late List<CountryModel> _listCountryModel;
  late TransformationController _transformImageController;
  // keys
  final GlobalKey _keyCrop = GlobalKey(debugLabel: "_keyCrop");
  final GlobalKey _keyImage = GlobalKey(debugLabel: "_keyImage");
  final GlobalKey _keyCountryDialog = GlobalKey(
    debugLabel: "_keyCountryDialog",
  );
  // another
  late Size _cropHoleSize, _cropHoleSizeOriginal;
  bool _isOpenCountryDialog = false, _isImageFullScreen = false;
  late AnimationController animationController;

  bool _isPhone = true;

  @override
  void initState() {
    super.initState();
    _transformImageController = TransformationController(widget.matrix4);
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _listCountryModel = BlocProvider.of<CountryBloc>(context).state.listCountry;
    if (_listCountryModel.isEmpty) {
      _listCountryModel = LIST_COUNTRY_PASSPORT;
    }
    _initCropHoleSize();
    _initCropModel();
  }

  void _initCropHoleSize() {
    _isPhone = BlocProvider.of<DevicePlatformCubit>(context).isPhone;
    double singleSize = widget.screenSize.height > MIN_SIZE.height
        ? _isPhone
              ? 274
              : 300
        : widget.screenSize.width * _mainRatio;
    double width = singleSize;
    double height = singleSize;
    final currentPassport = widget.projectModel.countryModel!.currentPassport;
    double ratioWH = currentPassport.width / currentPassport.height;
    if (ratioWH < 1) {
      width = singleSize * ratioWH;
    } else if (ratioWH > 1) {
      height = singleSize * (1 / ratioWH);
    }
    _cropHoleSizeOriginal = Size(singleSize, singleSize);
    _cropHoleSize = Size(width, height);
  }

  void _initCropModel() {
    if (widget.projectModel.cropModel != null) {
      _cropModel = widget.projectModel.cropModel;
    } else {
      double imageWidth = _cropHoleSize.width,
          imageHeight = _cropHoleSize.height;
      double ratioWH =
          widget.imageSelectedSize.width / widget.imageSelectedSize.height;

      if (ratioWH < 1) {
        // fix width
        imageWidth = _cropHoleSize.width;
        imageHeight = (1 / ratioWH) * imageWidth;
      } else if (ratioWH > 1) {
        // fix height
        imageHeight = _cropHoleSize.height;
        imageWidth = ratioWH * imageHeight;
      } else {
        imageHeight = imageWidth = max(
          _cropHoleSize.width,
          _cropHoleSize.height,
        );
      }
      Size imageSize = Size(imageWidth, imageHeight);
      _cropModel =
          widget.projectModel.cropModel ??
          CropModel(
            id: 0,
            instructionRotateValue: 0.5,
            currentRotateValue: 0.5,
            scale: 1,
            size: imageSize,
          );
    }
  }

  Future<void> _onExportCropped() async {
    if (widget.projectModel.uiImageAdjusted == null) return;
    final renderderBoxImage = _keyImage.currentContext?.size;
    // export cropped image
    List<dynamic> result = await exportCroppedImage(
      uiImageAjdusted: widget.projectModel.uiImageAdjusted!,
      countryModel: widget.projectModel.countryModel!,
      scaleByInteractView: _transformImageController.value.getMaxScaleOnAxis(),
      rotation:
          max(
            -45.000001,
            min(
              45.000001,
              ((_cropModel!.currentRotateValue -
                      _cropModel!.instructionRotateValue) *
                  90),
            ),
          ) *
          pi /
          180,
      matrix: _transformImageController.value,
      imageSizePreview: renderderBoxImage!,
      frameSize: _cropHoleSize,
    );

    consolelog("result result ${result}");
    widget.onUpdateProject(
      widget.projectModel
        ..croppedFile = result[0]
        ..uiImageCropped = result[1]
        ..scaledCroppedImage = null,
    );
    widget.onUpdateMatrix(_transformImageController.value);
    widget.onUpdateCropModel(_cropModel);

    File? scaleCroppedFile = await _handleGenerateScaledCroppedImage(
      result[0],
      Size(result[1].width.toDouble(), result[1].height.toDouble()),
    );
    ui.Image image1 = await decodeImageFromList(
      scaleCroppedFile!.readAsBytesSync(),
    );
    widget.onUpdateProject(widget.projectModel..scaledCroppedImage = image1);
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

  void _onTapUp(TapUpDetails details) {
    final RenderBox renderBoxCountryDialog =
        _keyCountryDialog.currentContext!.findRenderObject() as RenderBox;
    final startOffset = renderBoxCountryDialog.localToGlobal(
      const Offset(0, 0),
    );
    final endOffset = startOffset.translate(
      renderBoxCountryDialog.size.width,
      renderBoxCountryDialog.size.height,
    );
    if (containOffset(details.globalPosition, startOffset, endOffset)) {
      if (!_isOpenCountryDialog) {
        _isOpenCountryDialog = true;
        setState(() {});
      }
    } else {
      if (_isOpenCountryDialog) {
        _isOpenCountryDialog = false;
        setState(() {});
      }
    }
  }

  void _onShowFullImage(bool value) {
    _isImageFullScreen = value;
    setState(() {});
  }

  void _onRulerChange(double value) {
    _isImageFullScreen = true;
    final ratio = _cropHoleSizeOriginal.width / _cropHoleSizeOriginal.height;
    if (_cropModel != null) {
      _cropModel!.currentRotateValue = value;
      final deltaRotate = value - _cropModel!.instructionRotateValue;
      final scale = ((deltaRotate) * 90).clamp(-45, 45);
      _cropModel!.scale =
          max(ratio, 1 / ratio) *
          cos((45 - scale.abs()) * pi / 180) /
          (cos(45 * pi / 180));
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
    final ratioWH =
        newCountryModel.currentPassport.width /
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

  void _onInteractionStart(ScaleStartDetails details) {
    _isOpenCountryDialog = false;
    _onShowFullImage(true);
  }

  Future<void> _onInteractionEnd(ScaleEndDetails details) async {
    // _handleAnimateToInnerImage(details.velocity.pixelsPerSecond);
    _onShowFullImage(false);
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) {}
  @override
  Widget build(BuildContext context) {
    bool isDarkMode = BlocProvider.of<ThemeBloc>(
      context,
      listen: false,
    ).isDarkMode;
    bool isPhone = BlocProvider.of<DevicePlatformCubit>(
      context,
      listen: false,
    ).isPhone;
    return GestureDetector(
      onTapUp: (details) {
        _onTapUp(details);
      },
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
                              opacity: _isImageFullScreen ? 1 : 0,
                              duration: const Duration(milliseconds: 300),
                              child: _buildImage(clipBehavior: Clip.none),
                            ),
                            // goo hole
                            AnimatedOpacity(
                              opacity: _isImageFullScreen ? 0.4 : 1,
                              duration: const Duration(milliseconds: 300),
                              child: CustomPaint(
                                painter: HolePainter(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).scaffoldBackgroundColor,
                                  targetSize: _cropHoleSize,
                                ),
                                size: MediaQuery.sizeOf(context),
                              ),
                            ),
                            // dat hinh anh o day de lang nghe cu chi cua nguoi dung -> sau do ap dung vao anh ben tren de rotate, scale, tranform,...
                            _buildImage(
                              clipBehavior: Clip.hardEdge,
                              key: _keyImage,
                            ),
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
                                  context,
                                  isDarkMode,
                                  _cropModel,
                                ),
                                WRulerCustom(
                                  color: isDarkMode ? white : black,
                                  checkPointColor: isDarkMode
                                      ? primaryDark1
                                      : primaryLight1,
                                  instructionRatioValue:
                                      _cropModel?.instructionRotateValue ?? 0.5,
                                  currentRatioValue:
                                      _cropModel?.currentRotateValue ?? 0.5,
                                  dividers: 180,
                                  onValueChange: (value) {
                                    _onRulerChange(value);
                                  },
                                  onEnd: (value) {
                                    _onShowFullImage(false);
                                  },
                                ),
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
                              opacity: _isImageFullScreen ? 1 : 0,
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
                ),
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
    double degree;
    if (_cropModel == null) {
      degree = 0.0;
    } else {
      degree =
          (_cropModel!.currentRotateValue -
              _cropModel!.instructionRotateValue) /
          4; // *90/360
    }
    return SizedBox(
      height: _cropHoleSize.height,
      width: _cropHoleSize.width,
      child: InteractiveViewer(
        boundaryMargin: EdgeInsets.symmetric(
          horizontal: _cropModel != null
              ? (_cropModel!.size.width * 3 / 4)
              : 500,
          vertical: _cropModel != null
              ? (_cropModel!.size.height * 3 / 4)
              : 500,
        ),
        transformationController: _transformImageController,
        clipBehavior: clipBehavior,
        minScale: 1,
        maxScale: 10,
        interactionEndFrictionCoefficient: 1001,
        onInteractionStart: _onInteractionStart,
        onInteractionEnd: _onInteractionEnd,
        onInteractionUpdate: _onInteractionUpdate,
        child: OverflowBox(
          alignment: Alignment.center,
          minWidth: 0.0,
          minHeight: 0.0,
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: RotationTransition(
            turns: AlwaysStoppedAnimation(degree),
            child: Transform.scale(
              scale: 1,
              child: widget.uiImageAdjusted != null
                  ? RawImage(
                      image: widget.uiImageAdjusted!,
                      key: key,
                      height: _cropModel?.size.height,
                      width: _cropModel?.size.width,
                      fit: BoxFit.fill,
                    )
                  : Image.memory(
                      key: key,
                      widget.projectModel.selectedFile!.readAsBytesSync(),
                      gaplessPlayback: true,
                      height: _cropModel?.size.height,
                      width: _cropModel?.size.width,
                      frameBuilder:
                          (context, child, frame, wasSynchronouslyLoaded) {
                            return child;
                          },
                      fit: BoxFit.fill,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
