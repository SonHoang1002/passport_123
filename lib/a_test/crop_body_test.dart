import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass1_/commons/extension.dart';
import 'package:pass1_/helpers/export_images/export_cropped.dart';
import 'package:pass1_/helpers/rotate_helper.dart';
import 'package:pass1_/helpers/size_helpers.dart';
import 'package:pass1_/helpers/contain_offset.dart';
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
import 'package:pass1_/widgets/w_text.dart';
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
  final GlobalKey _keyImage = GlobalKey(debugLabel: "_keyImage");
  final GlobalKey _keyCountryDialog = GlobalKey(
    debugLabel: "_keyCountryDialog",
  );
  final GlobalKey _keyGestureArea = GlobalKey(debugLabel: "_keyGestureArea");

  // another
  bool _isOpenCountryDialog = false, _isGesturingImage = false;

  Rect _rectCropHole = Rect.zero,
      _rectCropHoleOriginal = Rect.zero,
      _rectImage = Rect.zero,
      _rectImageInitial = Rect.zero;

  Offset _startGlobalPosition = Offset.zero;
  Rect _startRectImage = Rect.zero;

  bool isInitting = true;

  /// Hai rect phải chung hệ quy chiếu
  (double, double, double, double) generateRatioCropModel(
    Rect rectImage,
    Rect rectCrop,
  ) {
    /// Lấy điểm center của crop, chiếu xuống ảnh, tìm điểm center đã xoay tại focal in image coord
    // _renderBoxImage = _keyImage.currentContext!.findRenderObject() as RenderBox;
    // Offset cropCenterInImageCoord = _renderBoxImage!.globalToLocal(
    //     _renderBoxCountryDialog!.localToGlobal(_rectCropHole.center));
    // Offset imageCenterInImageCoord = _renderBoxImage!.globalToLocal(
    //     _renderBoxCountryDialog!.localToGlobal(_rectImage.center));
    // Offset inverseImageCenterInImageCoord = RotateHelper.getRotatedPointByAngle(
    //   cropCenterInImageCoord,
    //   imageCenterInImageCoord,
    //   -_cropModel.getAngleByRadian,
    // );
    // Offset inverseImageCenterInGestureCoord = _renderBoxGestureArea!
    //     .globalToLocal(
    //         _renderBoxImage!.localToGlobal(inverseImageCenterInImageCoord));

    // Rect inverseImageRect = Rect.fromCenter(
    //   center: inverseImageCenterInGestureCoord,
    //   width: _rectImage.width,
    //   height: _rectImage.height,
    // );
    Rect checkRect = _rectImage;
    double ratioLeftInImage =
        (rectCrop.left - checkRect.left) / checkRect.width;
    double ratioTopInImage = (rectCrop.top - checkRect.top) / checkRect.height;
    double ratioRightInImage =
        (checkRect.right - rectCrop.right) / checkRect.width;
    double ratioBottomInImage =
        (checkRect.bottom - rectCrop.bottom) / checkRect.height;
    return (
      ratioLeftInImage,
      ratioTopInImage,
      ratioRightInImage,
      ratioBottomInImage,
    );
  }

  bool get isHaveLimitWhenGesture => false;
  bool get isHaveSnapCenter => false;

  set setCropModel(CropModel cropModel) {
    consolelog("setCropModel: ${cropModel}");
    _cropModel = cropModel;
  }

  @override
  void initState() {
    super.initState();
    _listCountryModel = BlocProvider.of<CountryBloc>(context).state.listCountry;
    if (_listCountryModel.isEmpty) {
      _listCountryModel = LIST_COUNTRY_PASSPORT;
    }
    setCropModel = CropModel.create(
      instructionRotateValue: 0.5,
      currentRotateValue: 0.5,
      ratioLeftInImage: 0.0,
      ratioTopInImage: 0.0,
      ratioRightInImage: 0.0,
      ratioBottomInImage: 0.0,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initRenderBoxsWhenNull();
      if (_renderBoxGestureArea == null) {
        throw Exception("_renderBoxGestureArea is null");
      }
      final sizeGestureArea = Size(
        _renderBoxGestureArea!.size.width,
        _renderBoxGestureArea!.size.height - 150,
      ); // 150 là khoảng cách của footer, nếu đổi footer thì phải đổi lại chỗ này
      Offset deltaTranslate = _renderBoxGestureArea!.globalToLocal(Offset.zero);
      consolelog(
        "deltaTranslate: $deltaTranslate, sizeGestureArea = $sizeGestureArea, widget.screenSize = ${widget.screenSize}",
      );
      Offset centerGestureArea = Offset(
        sizeGestureArea.width / 2,
        sizeGestureArea.height / 2,
      );
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

      _rectCropHoleOriginal = Rect.fromCenter(
        center: centerGestureArea,
        width: singleSize,
        height: singleSize,
      );
      _rectCropHole = Rect.fromCenter(
        center: centerGestureArea,
        width: widthCropHole,
        height: heightCropHole,
      );
      if (widget.projectModel.cropModel != null) {
        setCropModel = widget.projectModel.cropModel!.copyWith();
        consolelog(
          "widget.projectModel.cropModel != null: new data ${widget.projectModel.cropModel}",
        );
        consolelog(
          "widget.projectModel.cropModel != null: current $_cropModel",
        );
        double imageWidth =
            (widthCropHole /
            (1 - _cropModel.ratioLeftInImage - _cropModel.ratioRightInImage));
        double imageHeight =
            (heightCropHole /
            (1 - _cropModel.ratioTopInImage - _cropModel.ratioBottomInImage));

        _rectImage = Rect.fromLTWH(
          _rectCropHole.left - imageWidth * _cropModel.ratioLeftInImage,
          _rectCropHole.top - imageHeight * _cropModel.ratioTopInImage,
          imageWidth,
          imageHeight,
        );
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
        _rectImage = Rect.fromCenter(
          center: centerGestureArea,
          width: imageWidth,
          height: imageHeight,
        );
        var ratios = generateRatioCropModel(_rectImage, _rectCropHole);
        setCropModel = CropModel.create(
          instructionRotateValue: 0.5,
          currentRotateValue: 0.5,
          ratioLeftInImage: ratios.$1,
          ratioTopInImage: ratios.$2,
          ratioRightInImage: ratios.$3,
          ratioBottomInImage: ratios.$4,
        );
      }
      _rectImageInitial = _rectImage;

      isInitting = false;
      setState(() {});
    });
  }

  Future<void> _onExportCropped() async {
    if (widget.projectModel.uiImageAdjusted == null) return;
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
    //   frameSize: _rectCropHole,
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

  Future<void> _onExportCroppedV1() async {
    if (widget.projectModel.uiImageAdjusted == null) return;
    // export cropped image
    // (File, ui.Image) result = await exportCroppedImageV2(
    //   uiImageAdjusted: widget.projectModel.uiImageAdjusted!,
    //   countryModel: widget.projectModel.countryModel!,
    //   cropModel: _cropModel,
    // );

    (File, ui.Image) result = await exportCroppedImageMatchDisplay(
      uiImageAdjusted: widget.projectModel.uiImageAdjusted!,
      countryModel: widget.projectModel.countryModel!,
      cropModel: _cropModel,
      rectCropHolePreview: _rectCropHole,
      rectImagePreview: _rectImage,
      scaleWithInit: _rectImage.size.scaleWith(_rectImageInitial.size),
    );

    consolelog("result result $result");
    widget.onUpdateProject(
      widget.projectModel
        ..croppedFile = result.$1
        ..uiImageCropped = result.$2
        ..scaledCroppedImage = null,
    );
    // widget.onUpdateMatrix(_transformImageController.value);
    widget.onUpdateCropModel(_cropModel);

    File? scaleCroppedFile = await _handleGenerateScaledCroppedImage(
      result.$1,
      Size(result.$2.width.toDouble(), result.$2.height.toDouble()),
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
    consolelog("result result result $result");
    return result;
  }

  void _onShowFullImage(bool value) {
    _isGesturingImage = value;
    setState(() {});
  }

  void _onRulerChange(double value) {
    if (isInitting) return;
    consolelog("_onRulerChange: $value");
    _isGesturingImage = true;
    double deltaAngle = (value - _cropModel.currentRotateValue) * 90 * pi / 180;
    _cropModel.currentRotateValue = value;

    _renderBoxImage =
        _keyImage.currentContext?.findRenderObject() as RenderBox?;
    if (_renderBoxImage == null) {
      throw Exception("_renderBoxImage is null");
    }

    /// Chiếu điểm focal point ( rect foc) xuống hệ quy chiếu ảnh
    Offset focalPointInImage = _renderBoxImage!.globalToLocal(
      _renderBoxGestureArea!.localToGlobal(_rectCropHole.center),
    );

    /// Chiếu điểm center của ảnh xuống hệ quy chiếu ảnh
    Offset imageCenterInImageCoord = _renderBoxImage!.globalToLocal(
      _renderBoxGestureArea!.localToGlobal(_rectImage.center),
    );

    /// Vector từ focal point đến center của ảnh trong hệ quy chiếu ảnh
    Offset rotationVectorInImageCoord =
        imageCenterInImageCoord - focalPointInImage;

    // Xoay vector theo delta angle ttrong hệ quy cchiếu nhtm===
    Offset rotatedVectorInImageCoord = Offset(
      rotationVectorInImageCoord.dx * cos(deltaAngle) -
          rotationVectorInImageCoord.dy * sin(deltaAngle),
      rotationVectorInImageCoord.dx * sin(deltaAngle) +
          rotationVectorInImageCoord.dy * cos(deltaAngle),
    );

    /// Tính toạ độ center mới của ảnh trong hệ quy chiếu ảnh
    Offset imageCenterInImageCoordRotated =
        rotatedVectorInImageCoord + focalPointInImage;

    /// Chuyển ảnh về quy chiếu gesture area
    Offset newImageCenterInGestureCoord = _renderBoxGestureArea!.globalToLocal(
      _renderBoxImage!.localToGlobal(imageCenterInImageCoordRotated),
    );

    /// Cập nhật lại giá trị của trv
    _rectImage = Rect.fromCenter(
      center: newImageCenterInGestureCoord,
      width: _rectImage.width,
      height: _rectImage.height,
    );

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
    double newWidth = _rectCropHoleOriginal.width,
        newHeight = _rectCropHoleOriginal.height;
    if (ratioWH < 1) {
      newWidth = _rectCropHoleOriginal.width * ratioWH;
    } else if (ratioWH > 1) {
      newHeight = _rectCropHoleOriginal.height * (1 / ratioWH);
    }
    _rectCropHole = Rect.fromCenter(
      center: _rectCropHole.center,
      width: newWidth,
      height: newHeight,
    );
    setState(() {});
    // add to share pref
    await SharedPreferencesHelper().updateCountryPassport(value);
  }

  RenderBox? _renderBoxCountryDialog, _renderBoxImage, _renderBoxGestureArea;

  void _initRenderBoxsWhenNull() {
    _renderBoxCountryDialog ??=
        _keyCountryDialog.currentContext?.findRenderObject() as RenderBox?;
    _renderBoxImage ??=
        _keyImage.currentContext?.findRenderObject() as RenderBox?;
    _renderBoxGestureArea ??=
        _keyGestureArea.currentContext?.findRenderObject() as RenderBox?;
  }

  void _handleCheckFocusCountryDialog(Offset globalPosition) {
    _initRenderBoxsWhenNull();
    if (_renderBoxCountryDialog == null) {
      throw Exception("_renderBoxCountryDialog is null");
    }
    final Offset startGlobalCountryOffset = _renderBoxCountryDialog!
        .localToGlobal(const Offset(0, 0));
    final endGlobalCountryOffset = startGlobalCountryOffset.translate(
      _renderBoxCountryDialog!.size.width,
      _renderBoxCountryDialog!.size.height,
    );
    bool isTapCountryDialog = containOffset(
      globalPosition,
      startGlobalCountryOffset,
      endGlobalCountryOffset,
    );
    if (isTapCountryDialog) {
      if (!_isOpenCountryDialog) {
        _isOpenCountryDialog = true;
      }
    } else {
      if (_isOpenCountryDialog) {
        _isOpenCountryDialog = false;
      }
    }
  }

  void _handleCheckFocusCrop(Offset globalPosition) {
    _initRenderBoxsWhenNull();
    if (_renderBoxGestureArea == null) {
      throw Exception("_renderBoxGestureArea is null");
    }
    final Offset convertedPositionInGestureCoor = _renderBoxGestureArea!
        .globalToLocal(globalPosition);
    bool isTapCrop = _rectCropHole.contains(convertedPositionInGestureCoor);
    if (isTapCrop) {
      _isGesturingImage = true;
    } else {
      _isGesturingImage = false;
    }
  }

  void _onTapUp(TapUpDetails details) {
    _isGesturingImage = false;
    setState(() {});
  }

  void _onTapDown(TapDownDetails details) {
    _startGlobalPosition = details.globalPosition;
    _startRectImage = _rectImage;
    _handleCheckFocusCountryDialog(details.globalPosition);
    _handleCheckFocusCrop(details.globalPosition);
    setState(() {});
  }

  void _onScaleStart(ScaleStartDetails details) {
    _startGlobalPosition = details.focalPoint;
    _startRectImage = _rectImage;
    _handleCheckFocusCountryDialog(details.focalPoint);
    _handleCheckFocusCrop(details.focalPoint);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    consolelog("_isGesturingImage = $_isGesturingImage");
    if (_isGesturingImage) {
      Offset delta = details.focalPoint - _startGlobalPosition;
      double scale = details.scale;
      if (details.pointerCount == 1) {
        Rect newRectImage = _startRectImage.shift(delta);

        if (isHaveSnapCenter) {
          // Thêm snap vào điểm center của crop hole
          Offset centerImage = newRectImage.center;
          Offset centerCropHole = _rectCropHole.center;
          double snapThreshold = 5.0; // ngưỡng snap
          if ((centerImage.dx - centerCropHole.dx).abs() < snapThreshold) {
            centerImage = Offset(centerCropHole.dx, centerImage.dy);
          }
          if ((centerImage.dy - centerCropHole.dy).abs() < snapThreshold) {
            centerImage = Offset(centerImage.dx, centerCropHole.dy);
          }
          newRectImage = Rect.fromCenter(
            center: centerImage,
            width: _rectImage.width,
            height: _rectImage.height,
          );
        }
        if (isHaveLimitWhenGesture) {
          newRectImage = newRectImage.limitSelfToInclude(
            _rectCropHole,
            angleByRadian: _cropModel.getAngleByRadian,
            pivot: newRectImage.center,
          );
        }
        consolelog(
          "_cropModel.getAngleByRadian: ${_cropModel.getAngleByRadian}",
        );
        _rectImage = newRectImage;
        setState(() {});
      } else if (details.pointerCount == 2) {
        // 1. Tính toán kích thước mới sau khi scale
        Size targetSize = _startRectImage.size * scale;

        double minWidth = _rectCropHole.width;
        double minHeight = _rectCropHole.height;
        double aspect = _startRectImage.width / _startRectImage.height;

        // 2. Đảm bảo không nhỏ hơn crop hole
        if (targetSize.width < minWidth) {
          targetSize = Size(minWidth, minWidth / aspect);
        }

        if (targetSize.height < minHeight) {
          targetSize = Size(minHeight * aspect, minHeight);
        }
        _renderBoxImage =
            _keyImage.currentContext?.findRenderObject() as RenderBox?;
        if (_renderBoxImage == null) {
          throw Exception("_renderBoxImage is null");
        }

        /// Đổi điểm center của _startRectImage sang hệ quy chiếu của image
        Offset imageCenterInImage = _renderBoxImage!.globalToLocal(
          _renderBoxGestureArea!.localToGlobal(_startRectImage.center),
        );

        /// Đổi điểm start sang hệ quy chiếu của imgae
        Offset startPositionInImage = _renderBoxImage!.globalToLocal(
          _startGlobalPosition,
        );

        /// Tính vecotr từ center đến start trong hệ quy chiếu image
        Offset vectorFromCenterToStartInImage =
            imageCenterInImage - startPositionInImage;

        /// Scale nó lên
        Offset newVectorFromCenterToStartInImage =
            vectorFromCenterToStartInImage * scale;

        /// Tính toạ độ center mới trong hệ quy chiếu image
        Offset newImageCenterInImage =
            newVectorFromCenterToStartInImage + startPositionInImage;

        /// Đổi hệ quy chiếu về gesture area
        Offset newImageCenterInGestureCoordinate = _renderBoxGestureArea!
            .globalToLocal(
              _renderBoxImage!.localToGlobal(newImageCenterInImage),
            );

        Rect newRectInGestureCoordinate = Rect.fromCenter(
          center: newImageCenterInGestureCoordinate,
          width: targetSize.width,
          height: targetSize.height,
        ).shift(delta);

        if (isHaveSnapCenter) {
          // Thêm snap vào điểm center của crop hole
          Offset centerImage = newRectInGestureCoordinate.center;
          Offset centerCropHole = _rectCropHole.center;
          double snapThreshold = 5.0; // ngưỡng snap
          if ((centerImage.dx - centerCropHole.dx).abs() < snapThreshold) {
            centerImage = Offset(centerCropHole.dx, centerImage.dy);
          }
          if ((centerImage.dy - centerCropHole.dy).abs() < snapThreshold) {
            centerImage = Offset(centerImage.dx, centerCropHole.dy);
          }
          newRectInGestureCoordinate = Rect.fromCenter(
            center: centerImage,
            width: newRectInGestureCoordinate.width,
            height: newRectInGestureCoordinate.height,
          );
        }
        if (isHaveLimitWhenGesture) {
          newRectInGestureCoordinate = newRectInGestureCoordinate
              .limitSelfToInclude(
                _rectCropHole,
                angleByRadian: _cropModel.getAngleByRadian,
                pivot: newRectInGestureCoordinate.center,
              );
        }

        setState(() {
          _rectImage = newRectInGestureCoordinate;
        });
      } else {
        /// Chua ho tro
      }
    }
    var ratios = generateRatioCropModel(_rectImage, _rectCropHole);
    _cropModel
      ..ratioLeftInImage = ratios.$1
      ..ratioTopInImage = ratios.$2
      ..ratioRightInImage = ratios.$3
      ..ratioBottomInImage = ratios.$4;

    consolelog("_cropModel updated: $_cropModel");
  }

  // // cái ảnh xoay -alpha, khung crop xoay -alpha
  // // thì cái ảnh sẽ ở góc 0, khung crop góc -alpha
  // // tính khung bao ngoài khung crop
  // // xong limit vào ảnh góc 0
  // // lúc drag thì tính thế này
  // // còn lúc xoay mà limit thì a chưa nghĩ ra :v

  // void _onScaleEnd(ScaleEndDetails details) {
  //   double angleByRadian = _cropModel.getAngleByRadian;
  //   bool isRotatedImageOctagonContainsCropRect =
  //       RotateHelper.isRotatedSeftOctagonContains(
  //     outerRect: _rectImage,
  //     innerRect: _rectCropHole,
  //     angleByRadianForOuter: angleByRadian,
  //   );
  //   consolelog(
  //       "isRotatedImageOctagonContainsCropRect: $isRotatedImageOctagonContainsCropRect");
  //   Rect limitRectOrigin = _rectImage.limitSelfToInclude(_rectCropHole);
  //   if (!_cropModel.getAngleByRadian.equalTo(0.0)) {
  //     /// Tôi có
  //     /// + _rectImage, angleByRadian, điểm xoay tại center của _rectImage,
  //     /// + cropRect
  //     ///
  //     /// Khi thả tay, tôi cần tính lại rect mới cho _rectImage ( rect mới là X ),
  //     /// mà ở đó, khi xoay X tại center của chính nó,
  //     /// thì crop Rect sẽ luôn luôn nằm trong phần diện tích nối bởi 4 điểm góc đã xoay
  //     Rect surroundingRotatedCropRect = RotateHelper.getRotatedRect(
  //       _rectCropHole,
  //       angleByRadian,
  //       pivotPoint: _rectCropHole.center,
  //     );
  //     limitRectOrigin = _rectImage.limitSelfWith(surroundingRotatedCropRect);
  //   }
  //   final SpringDescription spring = SpringDescription(
  //     mass: 1.0,
  //     stiffness: 100.0,
  //     damping: 15.0,
  //   );
  //   // Animation cho mỗi thuộc tính của Rect
  //   _animateRectWithSpring(
  //     from: _rectImage,
  //     to: limitRectOrigin,
  //     spring: spring,
  //   );
  //   _startGlobalPosition = Offset.zero;
  //   _startRectImage = Rect.zero;
  //   _isGesturingImage = false;
  //   setState(() {});
  // }

  void _onScaleEnd(ScaleEndDetails details) {
    final double angle = _cropModel.getAngleByRadian;

    Rect targetRect = _rectImage;

    if (angle.equalTo(0.0)) {
      /// Trường hợp góc 0° như iOS scroll view
      targetRect = _rectImage.limitSelfToInclude(_rectCropHole);
    } else {
      /// Trường hợp góc ≠ 0°
      /// Tính rect mới sao cho ảnh quay luôn bao trọn cropRect
      targetRect = RotatedCropHelpers.limitOuterOctagonToIncludeInnerOctagon(
        outerRect: _rectImage,
        innerRect: _rectCropHole,
        angleByRadian: angle,
      );
    }

    final spring = SpringDescription(
      mass: 1.0,
      stiffness: 100.0,
      damping: 15.0,
    );

    _animateRectWithSpring(from: _rectImage, to: targetRect, spring: spring);

    _startGlobalPosition = Offset.zero;
    _startRectImage = Rect.zero;
    _isGesturingImage = false;
    setState(() {});
  }

  double durationSpringSimulatorByMilis = 750;
  void _animateRectWithSpring({
    required Rect from,
    required Rect to,
    required SpringDescription spring,
  }) {
    // Tạo animation cho từng thành phần
    final leftSimulation = SpringSimulation(
      spring,
      from.left,
      to.left,
      0.0, // velocity
    );

    final topSimulation = SpringSimulation(spring, from.top, to.top, 0.0);

    final widthSimulation = SpringSimulation(spring, from.width, to.width, 0.0);

    final heightSimulation = SpringSimulation(
      spring,
      from.height,
      to.height,
      0.0,
    );

    // Tạo ticker để update animation
    Ticker? ticker;

    ticker = Ticker((elapsed) {
      final time = elapsed.inMilliseconds / durationSpringSimulatorByMilis;

      // Tính giá trị mới từ simulation
      final newLeft = leftSimulation.x(time);
      final newTop = topSimulation.x(time);
      final newWidth = widthSimulation.x(time);
      final newHeight = heightSimulation.x(time);

      setState(() {
        _rectImage = Rect.fromLTWH(newLeft, newTop, newWidth, newHeight);
      });

      // Kiểm tra xem animation đã done chưa
      if (leftSimulation.isDone(time) &&
          topSimulation.isDone(time) &&
          widthSimulation.isDone(time) &&
          heightSimulation.isDone(time)) {
        ticker?.stop();
        ticker?.dispose();

        // Đảm bảo giá trị cuối chính xác
        setState(() {
          _rectImage = to;
        });
      }
    });

    ticker.start();
  }

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
    return Container(
      decoration: const BoxDecoration(),
      child: GestureDetector(
        key: _keyGestureArea,
        onTapUp: _onTapUp,
        onTapDown: _onTapDown,
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onScaleEnd: _onScaleEnd,
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(),
          child: Column(
            children: [
              // body
              Expanded(
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(),
                  child: Stack(
                    clipBehavior: Clip.antiAlias,
                    // alignment: Alignment.center,
                    children: [
                      // image
                      // goo hole
                      // rectangle frame
                      // crop guide
                      // country dialog
                      // ruler
                      // face arrange + gesture area
                      Stack(
                        children: [
                          Positioned(
                            left: _rectCropHole.left,
                            top: _rectCropHole.top,
                            child: Container(
                              color: black,
                              width: _rectCropHole.width,
                              height: _rectCropHole.height,
                            ),
                          ),
                          // image
                          Positioned(
                            left: _rectImage.left,
                            top: _rectImage.top,
                            child: AnimatedOpacity(
                              opacity: _isGesturingImage ? 1 : 0,
                              duration: const Duration(milliseconds: 300),
                              child: _buildImage(clipBehavior: Clip.hardEdge),
                            ),
                          ),

                          // goo hole
                          AnimatedOpacity(
                            opacity: _isGesturingImage ? 0.4 : 1,
                            duration: const Duration(milliseconds: 300),
                            child: CustomPaint(
                              painter: HolePainter1(
                                backgroundColor: Theme.of(
                                  context,
                                ).scaffoldBackgroundColor,
                                targetCropRect: _rectCropHole,
                              ),
                              size: MediaQuery.sizeOf(context),
                            ),
                          ),

                          // dat hinh anh o day de lang nghe cu chi cua nguoi dung -> sau do ap dung vao anh ben tren de rotate, scale, tranform,...
                          Positioned(
                            left: _rectImage.left,
                            top: _rectImage.top,
                            child: _buildClipImage(
                              clipBehavior: Clip.hardEdge,
                              key: _keyImage,
                            ),
                          ),
                          // rectangle frame
                          Positioned(
                            left: _rectCropHole.left,
                            top: _rectCropHole.top,
                            child: CustomPaint(
                              painter: FrameHolePainter(
                                targetSize: _rectCropHole.size,
                                lineColor: isDarkMode ? white : black,
                              ),
                              size: _rectCropHole.size,
                              // size: MediaQuery.sizeOf(context),
                            ),
                          ),
                          _buildTestWidget(),
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
                              isInitting
                                  ? SizedBox()
                                  : WRulerCustom(
                                      color: isDarkMode ? white : black,
                                      checkPointColor: isDarkMode
                                          ? primaryDark1
                                          : primaryLight1,
                                      instructionRatioValue:
                                          _cropModel.instructionRotateValue,
                                      currentRatioValue:
                                          _cropModel.currentRotateValue,
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
                      Positioned(
                        left: _rectCropHole.left,
                        top: _rectCropHole.top,
                        child: SizedBox(
                          height: _rectCropHole.height,
                          width: _rectCropHole.width,
                          child: WFaceArrangeComponents(
                            projectModel: widget.projectModel,
                            frameSize: _rectCropHole.size,
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
                  await _onExportCroppedV1();
                  await widget.onUpdateStep();
                  widget.onUpdateLoadingStatus(false);
                },
                footerHeight: isPhone ? null : 166,
                isHaveSettingButton: isPhone ? true : false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage({required Clip clipBehavior, Key? key}) {
    if (widget.projectModel.uiImageAdjusted == null) {
      return const CustomLoadingIndicator();
    }
    return Container(
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(),
      child: Transform.rotate(
        alignment: Alignment.center,
        angle: _cropModel.getAngleByRadian,
        child: Container(
          child: widget.uiImageAdjusted != null
              ? RawImage(
                  image: widget.uiImageAdjusted!,
                  key: key,
                  height: _rectImage.height,
                  width: _rectImage.width,
                  fit: BoxFit.fill,
                )
              : Image.memory(
                  key: key,
                  widget.projectModel.selectedFile!.readAsBytesSync(),
                  gaplessPlayback: true,
                  height: _rectImage.height,
                  width: _rectImage.width,
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                        return child;
                      },
                  fit: BoxFit.fill,
                ),
        ),
      ),
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
    //   height: _rectCropHole.height,
    //   width: _rectCropHole.width,
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

  Widget _buildClipImage({required Clip clipBehavior, Key? key}) {
    if (widget.projectModel.uiImageAdjusted == null) {
      return const CustomLoadingIndicator();
    }
    return Transform.rotate(
      alignment: Alignment.center,
      angle: _cropModel.getAngleByRadian,
      child: SizedBox(
        key: key,
        height: _rectImage.height,
        width: _rectImage.width,
        child: widget.uiImageAdjusted != null
            ? RawImage(
                image: widget.uiImageAdjusted!,
                height: _rectImage.height,
                width: _rectImage.width,
                fit: BoxFit.fill,
              )
            : Image.memory(
                widget.projectModel.selectedFile!.readAsBytesSync(),
                gaplessPlayback: true,
                height: _rectImage.height,
                width: _rectImage.width,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  return child;
                },
                fit: BoxFit.fill,
              ),
      ),
    );
  }

  Widget _buildTestWidget() {
    return Positioned(
      left: _rectCropHole.topLeft.dx,
      top: _rectCropHole.topLeft.dy,
      child: Transform.rotate(
        angle: 34 / 180 * pi,
        child: Container(
          color: red.withAlpha(30),
          width: _rectCropHole.width,
          height: _rectCropHole.height,
        ),
      ),
    );
  }

  Widget _buildTestWidget1() {
    return Positioned(
      left: _rectImage.topLeft.dx,
      top: _rectImage.topLeft.dy,
      child: Transform.rotate(
        angle: 0,
        child: Container(
          color: black,
          width: _rectImage.width,
          height: _rectImage.height,
        ),
      ),
    );
  }
}
