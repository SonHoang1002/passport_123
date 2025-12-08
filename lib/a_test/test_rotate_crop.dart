import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass1_/commons/extension.dart';
import 'package:pass1_/helpers/crop_helpers.dart';
import 'package:pass1_/helpers/log_custom.dart';
import 'package:pass1_/widgets/w_custom_painter.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/models/crop_model.dart';
import 'package:pass1_/providers/blocs/theme_bloc.dart';
import 'package:pass1_/widgets/w_custom_ruler.dart';
import 'package:pass1_/widgets/w_text.dart';

class TestRotateCrop extends StatefulWidget {
  const TestRotateCrop({super.key});

  @override
  State<TestRotateCrop> createState() => _TestRotateCropState();
}

class _TestRotateCropState extends State<TestRotateCrop>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final imagePath = "${PATH_PREFIX_IMAGE}IMG_0829_111.JPG";
  Size originalPhysicalSize = Size(2000, 2667);
  // main variables
  late CropModel _cropModel;

  // keys
  final GlobalKey _keyImage = GlobalKey(debugLabel: "_keyImage");
  final GlobalKey _keyGestureArea = GlobalKey(debugLabel: "_keyGestureArea");

  bool _isGesturingImage = false;

  Rect _rectCropHole = Rect.zero;
  Rect _rectImage = Rect.zero;
  Rect _startRectImage = Rect.zero;

  Offset _startGlobalPosition = Offset.zero;
  bool isInitting = true;
  RenderBox? _renderBoxImage, _renderBoxGestureArea;
  double durationSpringSimulatorByMilis = 750;

  bool get isHaveLimitWhenGesture => false;
  bool get isHaveSnapCenter => false;
  double get ratioCurrentPassport => 2000 / 1500;
  double get ratioImage => originalPhysicalSize.aspectRatio;

  ui.Image? _cropUiImage;

  set setCropModel(CropModel cropModel) {
    _cropModel = cropModel;
  }

  set setRectImage(Rect newRect) {
    _rectImage = newRect;
    setCropModel = _cropModel.copyWith(
      ratioLeftInImage:
          (_rectCropHole.left - _rectImage.left) / _rectImage.width,
      ratioTopInImage: (_rectCropHole.top - _rectImage.top) / _rectImage.height,
      ratioRightInImage:
          -(_rectCropHole.right - _rectImage.right) / _rectImage.width,
      ratioBottomInImage:
          -(_rectCropHole.bottom - _rectImage.bottom) / _rectImage.height,
    );
  }

  double get angleByDegree => _cropModel.getAngleByDegree;
  double get angleByRadian => _cropModel.getAngleByRadian;

  @override
  void initState() {
    super.initState();

    setCropModel = CropModel.create(
      instructionRotateValue: 0.5,
      currentRotateValue: 0.5,
      ratioLeftInImage: 0.0,
      ratioTopInImage: 0.0,
      ratioRightInImage: 0.0,
      ratioBottomInImage: 0.0,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Size screenSize = MediaQuery.sizeOf(context);
      _initRenderBoxsWhenNull();
      if (_renderBoxGestureArea == null) {
        throw Exception("_renderBoxGestureArea is null");
      }
      final sizeGestureArea = Size(
        _renderBoxGestureArea!.size.width,
        _renderBoxGestureArea!.size.height,
      );
      Offset centerGestureArea = Offset(
        sizeGestureArea.width / 2,
        sizeGestureArea.height / 2,
      );
      double singleSize = screenSize.width * 0.567;

      double widthCropHole, heightCropHole;

      if (ratioCurrentPassport < 1) {
        heightCropHole = singleSize;
        widthCropHole = singleSize * ratioCurrentPassport;
      } else if (ratioCurrentPassport > 1) {
        heightCropHole = singleSize / ratioCurrentPassport;
        widthCropHole = heightCropHole * ratioCurrentPassport;
      } else {
        widthCropHole = heightCropHole = singleSize;
      }

      _rectCropHole = Rect.fromCenter(
        center: centerGestureArea,
        width: widthCropHole,
        height: heightCropHole,
      );

      double imageWidth, imageHeight;

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
      setRectImage = Rect.fromCenter(
        center: centerGestureArea,
        width: imageWidth,
        height: imageHeight,
      );

      setCropModel = CropModel.create(
        instructionRotateValue: 0.5,
        currentRotateValue: 0.5,
        ratioLeftInImage:
            (_rectCropHole.left - _rectImage.left) / _rectImage.width,
        ratioTopInImage:
            (_rectCropHole.top - _rectImage.top) / _rectImage.height,
        ratioRightInImage:
            -(_rectCropHole.right - _rectImage.right) / _rectImage.width,
        ratioBottomInImage:
            -(_rectCropHole.bottom - _rectImage.bottom) / _rectImage.height,
      );

      isInitting = false;
      setState(() {});
    });
  }

  void _onRulerChange(double value) {
    consolelog("valuevalue: $value");
    double customValue = value;
    if (isInitting) return;
    _isGesturingImage = true;
    double deltaAngle =
        (customValue - _cropModel.currentRotateValue) * 90 * pi / 180;
    _cropModel.currentRotateValue = customValue;

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
    setRectImage = Rect.fromCenter(
      center: newImageCenterInGestureCoord,
      width: _rectImage.width,
      height: _rectImage.height,
    );
    setState(() {});
  }

  void _initRenderBoxsWhenNull() {
    _renderBoxImage ??=
        _keyImage.currentContext?.findRenderObject() as RenderBox?;
    _renderBoxGestureArea ??=
        _keyGestureArea.currentContext?.findRenderObject() as RenderBox?;
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

  void _onShowFullImage(bool value) {
    _isGesturingImage = value;
  }

  void _onScaleStart(ScaleStartDetails details) {
    _startGlobalPosition = details.focalPoint;
    _startRectImage = _rectImage;
    _handleCheckFocusCrop(details.focalPoint);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    consolelog("_isGesturingImage = ${details.focalPoint}");
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
            angleByRadian: angleByRadian,
            pivot: newRectImage.center,
          );
        }
        setRectImage = newRectImage;
        setState(() {});
      } else if (details.pointerCount == 2) {
        // 1. Tính toán kích thước mới sau khi scale
        Size targetSize = _startRectImage.size * scale;

        targetSize = CropHelpers.limitScaleSize(
          angleByRadian: angleByRadian,
          innerRect: _rectCropHole,
          outerSize: targetSize,
        );
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
                angleByRadian: angleByRadian,
                pivot: newRectInGestureCoordinate.center,
              );
        }
        setRectImage = newRectInGestureCoordinate;
        setState(() {});
      } else {
        /// Chua ho tro
      }
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    Rect targetRect = _rectImage;

    if (angleByRadian.equalTo(0.0)) {
      /// Trường hợp góc 0° như iOS scroll view
      targetRect = _rectImage.limitSelfToInclude(_rectCropHole);
    } else {
      /// Trường hợp góc ≠ 0°
      /// Tính rect mới sao cho ảnh quay luôn bao trọn cropRect
      targetRect = CropHelpers.limitOuterOctagonToIncludeInnerOctagon(
        outerRect: _rectImage,
        innerRect: _rectCropHole,
        angleByRadian: angleByRadian,
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
  }

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

      setRectImage = Rect.fromLTWH(newLeft, newTop, newWidth, newHeight);
      setState(() {});

      // Kiểm tra xem animation đã done chưa
      if (leftSimulation.isDone(time) &&
          topSimulation.isDone(time) &&
          widthSimulation.isDone(time) &&
          heightSimulation.isDone(time)) {
        ticker?.stop();
        ticker?.dispose();

        // Đảm bảo giá trị cuối chính xác

        setRectImage = to;
        setState(() {});
      }
    });

    ticker.start();
  }

  void _generate() async {
    ui.Image uiImage = await loadUiImageFromAsset(imagePath);

    double currentRotation = _cropModel.getAngleByRadian;
    final Size originalImageSize = originalPhysicalSize;

    final double cropLeft =
        _cropModel.ratioLeftInImage * originalImageSize.width;
    final double cropTop =
        _cropModel.ratioTopInImage * originalImageSize.height;
    final double cropRight =
        _cropModel.ratioRightInImage * originalImageSize.width;
    final double cropBottom =
        _cropModel.ratioBottomInImage * originalImageSize.height;

    final double cropWidth = originalImageSize.width - cropLeft - cropRight;
    final double cropHeight = originalImageSize.height - cropTop - cropBottom;

    final Rect cropRect = Rect.fromLTWH(
      cropLeft,
      cropTop,
      cropWidth,
      cropHeight,
    );
    final Offset cropCenter = cropRect.center;
    final Offset imageCenter = Offset(
      originalImageSize.width / 2,
      originalImageSize.height / 2,
    );

    consolelog("Image center: $imageCenter");
    consolelog("Crop center: $cropCenter");
    consolelog("Rotation: ${currentRotation * 180 / pi}°");

    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder);

    // Đổ màu đen background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, cropWidth, cropHeight),
      Paint()..color = const Color(0xFF000000),
    );

    canvas.save();

    canvas.translate(cropWidth / 2, cropHeight / 2);

    final Offset vectorFromCropToImage = imageCenter - cropCenter;
    canvas.translate(vectorFromCropToImage.dx, vectorFromCropToImage.dy);

    canvas.rotate(currentRotation);

    canvas.drawImageRect(
      uiImage,
      Rect.fromLTWH(0, 0, originalImageSize.width, originalImageSize.height),
      Rect.fromCenter(
        center: Offset.zero,
        width: originalImageSize.width,
        height: originalImageSize.height,
      ),
      Paint(),
    );

    canvas.restore();

    final ui.Picture picture = recorder.endRecording();
    consolelog("Crop size: $cropWidth x $cropHeight");

    final ui.Image resultImage = await picture.toImage(
      cropWidth.toInt(),
      cropHeight.toInt(),
    );

    _cropUiImage = resultImage;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = BlocProvider.of<ThemeBloc>(
      context,
      listen: false,
    ).isDarkMode;
    return Container(
      decoration: const BoxDecoration(),
      child: GestureDetector(
        key: _keyGestureArea,
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onScaleEnd: _onScaleEnd,
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(),
                  child: Stack(
                    clipBehavior: Clip.antiAlias,
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
                        ),
                      ),
                      ..._buildTestWidget(),
                      if (!isInitting)
                        Positioned(
                          bottom: 30,
                          child: WRulerCustom(
                            color: isDarkMode ? white : black,
                            checkPointColor: isDarkMode
                                ? primaryDark1
                                : primaryLight1,
                            instructionRatioValue:
                                _cropModel.instructionRotateValue,
                            currentRatioValue: _cropModel.currentRotateValue,
                            dividers: 360,
                            onValueChange: (value) {
                              _onRulerChange(value);
                            },
                            onEnd: () {
                              _onShowFullImage(false);
                            },
                          ),
                        ),
                      _buildReverseCropRectButton(),
                      _buildGenerateCanvasButton(),

                      if (_cropUiImage != null) _buildCropUiImageWidget(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClipImage({required Clip clipBehavior, Key? key}) {
    return Transform.rotate(
      alignment: Alignment.center,
      angle: angleByRadian * 1,
      child: Container(
        key: key,
        height: _rectImage.height,
        width: _rectImage.width,
        child: Image.asset(
          imagePath,
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

  List<Widget> _buildTestWidget() {
    Map<String, Offset> listRotatedCropPoint =
        CropHelpers.getRotatedRectCorners(_rectCropHole, angleByRadian);
    Rect surroundingRotatedCropRect = CropHelpers.getRotatedRect(
      _rectCropHole,
      angleByRadian,
    );
    Offset topLeft = listRotatedCropPoint["topLeft"]!;
    Offset topRight = listRotatedCropPoint["topRight"]!;
    Offset bottomLeft = listRotatedCropPoint["bottomLeft"]!;
    Offset bottomRight = listRotatedCropPoint["bottomRight"]!;

    Widget topLeftWidget = Positioned(
      left: topLeft.dx - 10,
      top: topLeft.dy - 10,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: red,
        ),
        child: Center(
          child: WTextContent(value: "TL", textSize: 10, textColor: white),
        ),
      ),
    );
    Widget topRightWidget = Positioned(
      left: topRight.dx - 10,
      top: topRight.dy - 10,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: black,
        ),
        child: Center(
          child: WTextContent(value: "TR", textSize: 10, textColor: white),
        ),
      ),
    );

    Widget bottomLeftWidget = Positioned(
      left: bottomLeft.dx - 10,
      top: bottomLeft.dy - 10,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: greenColorLight,
        ),
        child: Center(
          child: WTextContent(value: "BL", textSize: 10, textColor: white),
        ),
      ),
    );
    Widget bottomRightWidget = Positioned(
      left: bottomRight.dx - 10,
      top: bottomRight.dy - 10,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: blue,
        ),
        child: Center(
          child: WTextContent(value: "BR", textSize: 10, textColor: white),
        ),
      ),
    );

    Widget mainWidget = Positioned(
      left: surroundingRotatedCropRect.topLeft.dx,
      top: surroundingRotatedCropRect.topLeft.dy,
      child: Transform.rotate(
        angle: 0, // angleByRadian * 1,
        child: Container(
          color: red.withAlpha(70),
          width: surroundingRotatedCropRect.width,
          height: surroundingRotatedCropRect.height,
          child: Center(
            child: Container(
              color: white,
              child: WTextContent(
                value:
                    "getAngleByDegree: ${(CropHelpers.limitAngleRadian(_cropModel.getAngleByRadian).toDegreeFromRadian * 1).toStringAsFixed(2)}",
                textColor: black,
              ),
            ),
          ),
        ),
      ),
    );

    return [
      topLeftWidget,
      topRightWidget,
      bottomLeftWidget,
      bottomRightWidget,
      mainWidget,
    ];
  }

  Widget _buildReverseCropRectButton() {
    return Positioned(
      top: 40,
      left: 20,
      child: GestureDetector(
        onTap: () {
          _rectCropHole = _rectCropHole.reverse;
          setState(() {});
        },
        child: Container(
          color: red,
          height: 40,
          width: 130,
          child: Center(child: WTextContent(value: "Reverse Crop Rect")),
        ),
      ),
    );
  }

  Widget _buildGenerateCanvasButton() {
    return Positioned(
      top: 40,
      right: 20,
      child: GestureDetector(
        onTap: () {
          _generate();
        },
        child: Container(
          color: blue,
          height: 40,
          width: 130,
          child: Center(child: WTextContent(value: "Generate")),
        ),
      ),
    );
  }

  Widget _buildCropUiImageWidget() {
    return _Preview(
      cropImage: _cropUiImage!,
      onTap: () {
        _cropUiImage = null;
        setState(() {});
      },
    );
  }
}

class _Preview extends StatefulWidget {
  final ui.Image cropImage;
  final void Function() onTap;
  const _Preview({super.key, required this.cropImage, required this.onTap});

  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  late Size imageSize;
  Size boundingSize = Size(300, 300);
  @override
  void initState() {
    super.initState();
    double ratio = widget.cropImage.width / widget.cropImage.height;
    if (ratio > 1) {
      imageSize = Size(boundingSize.width, boundingSize.width / ratio);
    } else if (ratio < 1) {
      imageSize = Size(boundingSize.width * ratio, boundingSize.height);
    } else {
      imageSize = boundingSize;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: transparent,
      body: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: transparent,
          child: Center(
            child: Container(
              width: boundingSize.width,
              height: boundingSize.height,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RawImage(
                    width: imageSize.width,
                    height: imageSize.height,
                    image: widget.cropImage,
                  ),
                  Container(
                    child: WTextContent(
                      value:
                          "${widget.cropImage.width}x${widget.cropImage.height}",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<ui.Image> loadUiImageFromAsset(
  String assetPath, {
  int? targetWidth,
  int? targetHeight,
}) async {
  final ByteData assetImageByteData = await rootBundle.load(assetPath);
  final ui.Codec codec = await ui.instantiateImageCodec(
    assetImageByteData.buffer.asUint8List(),
    targetWidth: targetWidth,
    targetHeight: targetHeight,
  );
  final ui.FrameInfo frameInfo = await codec.getNextFrame();
  return frameInfo.image;
}
