import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:pass1_/a_test/crop_body_test.dart';
import 'package:pass1_/helpers/size_helpers.dart';
import 'package:pass1_/a_test/w_export_body.dart';
import 'package:pass1_/helpers/file_helpers.dart';
import 'package:pass1_/helpers/native_bridge/method_channel.dart';
import 'package:pass1_/helpers/remove_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/helpers/log_custom.dart';
import 'package:pass1_/models/project_model.dart';
import 'package:pass1_/providers/blocs/adjust_subject_bloc.dart';
import 'package:pass1_/providers/blocs/device_platform_bloc.dart';
import 'package:pass1_/providers/events/adjust_subject_event.dart';
import 'package:pass1_/screens/module_home/widgets/w_footer.dart';
import 'package:pass1_/screens/module_home/widgets/w_print.dart';
import 'package:pass1_/screens/sub_modules/module_adjust/adjust_body_tablet.dart';
import 'package:pass1_/screens/sub_modules/module_import/import_body_tablet.dart';
import 'package:pass1_/services/dio_api.dart';
import 'package:pass1_/widgets/bottom_sheet/show_bottom_sheet.dart';
import 'package:pass1_/models/step_model.dart';
import 'package:pass1_/providers/blocs/theme_bloc.dart';
import 'package:pass1_/screens/sub_modules/module_finish/finish_body.dart';
import 'package:pass1_/widgets/w_circular.dart';
import 'package:pass1_/widgets/w_header.dart';
import 'package:pass1_/widgets/w_setting_navi_button.dart';
import 'package:path_provider/path_provider.dart';

// ignore: must_be_immutable
class HomePageTablet extends StatefulWidget {
  ProjectModel project;
  HomePageTablet({super.key, required this.project});
  @override
  State<HomePageTablet> createState() => _HomePagePhoneState();
}

class _HomePagePhoneState extends State<HomePageTablet>
    with
        SingleTickerProviderStateMixin,
        AutomaticKeepAliveClientMixin<HomePageTablet> {
  // general
  late Size _size;
  late bool _isDarkMode;
  late StepModel _currentStep;
  Size? _imageSelectedSize;
  bool? _isLoading = false;
  bool _isShowFooterMask =
      false; // ngan chan hieu ung slider cuar tab phan footer
  late ProjectModel _projectModel;
  late final TabController _tabController = TabController(
    length: 4,
    vsync: this,
  );
  // adjust properties
  Offset? _offsetTrackerBrightness;
  TransformationController _transformationAdjustController =
      TransformationController();
  int _indexSegment = 0;
  int _indexSnapList = 0;
  // crop properties
  late Matrix4 _matrix4Crop = Matrix4.identity();
  // export properties

  @override
  void initState() {
    super.initState();
    _projectModel = widget.project;
    _currentStep = LIST_STEP_SELECTION[0];
  }

  Future<void> _onUpdateSelectedImage(File? file) async {
    if (file != null) {
      var decodedImage = await decodeImageFromList(file.readAsBytesSync());
      _imageSelectedSize = Size(
        double.parse(decodedImage.width.toString()),
        double.parse(decodedImage.height.toString()),
      );
    } else {
      _offsetTrackerBrightness = null;
      _projectModel.resetAllImage();
      // adjust properties
      _indexSegment = _indexSnapList = 0;
      _resetAdjustProperties();
      // crop properties
      _resetCropProperties();
    }
    _projectModel.selectedFile = file;
    List<dynamic> listScaled = await _handleGenerateScaleSelectedImage(
      file,
      _imageSelectedSize,
    );
    if (listScaled.isNotEmpty) {
      _projectModel
        ..scaledSelectedFile = listScaled[0]
        ..scaledSelectedImage = listScaled[1];
    }
    setState(() {});
  }

  Future<List<dynamic>> _handleGenerateScaleSelectedImage(
    File? selectedImage,
    Size? imageSelectedSize,
  ) async {
    if (selectedImage == null) return [];
    String scaleSelectedImagePath =
        "${(await getExternalStorageDirectory())!.path}/scaled_original.png";
    Size selectedSize;
    if (imageSelectedSize != null) {
      selectedSize = imageSelectedSize;
    } else {
      var image = await decodeImageFromList(selectedImage.readAsBytesSync());
      selectedSize = Size(image.width.toDouble(), image.height.toDouble());
    }
    Size newSize = FlutterSizeHelpers.handleScaleWithSpecialDimension(
      originalSize: selectedSize,
    );
    File? resultFile = await MyMethodChannel.resizeAndResoluteImage(
      inputPath: selectedImage.path,
      format: 1,
      listWH: [newSize.width, newSize.height],
      scaleWH: [1, 1],
      outPath: scaleSelectedImagePath,
      quality: 90,
    );
    ui.Image image = await decodeImageFromList(resultFile!.readAsBytesSync());

    return [resultFile, image];
  }

  Future<void> _onRemoveImageBackground() async {
    try {
      // api
      Stopwatch stopwatch = Stopwatch();
      stopwatch.start();

      File? resizeImage =
          (await resizeImageBeforeAPI(_projectModel.selectedFile!.path)) ??
          _projectModel.selectedFile!;
      bool isHasNetworkConnection =
          await MyMethodChannel.checkNetworkConnection();
      if (isHasNetworkConnection) {
        final result = await Api().postBackgroundRemove(resizeImage.path);
        if (result == null) {
          _projectModel.bgRemovedFile = _projectModel.selectedFile;
        } else {
          // local -  note.txt
          final newConvertedImage = await RemoveBackgroundHelpers()
              .cutBackgroundRemoverWithMethodChannelWithOriginalSize(
                _projectModel.selectedFile!.path,
              );
          if (newConvertedImage != null) {
            _projectModel.bgRemovedFile = newConvertedImage;
          }
        }
      } else {
        _projectModel.bgRemovedFile = _projectModel.selectedFile;
        MyMethodChannel.showToast("No network connection!!");
      }

      stopwatch.stop();
    } catch (e) {
      _projectModel.bgRemovedFile = _projectModel.selectedFile;
      consolelog("_onRemoveImageBackground error: ${e}");
    }
    setState(() {});
  }

  void _updateLoadingStatus(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  Future<void> _onNext() async {
    setState(() {
      // _isLoading = true;
      _isShowFooterMask = true;
    });
    switch (_currentStep.id) {
      case 0:
        if (_projectModel.bgRemovedFile == null ||
            _projectModel.bgRemovedFile == _projectModel.selectedFile) {
          /// Nếu chưa convert hoặc bị lỗi mạng trước đó đều sẽ được gen lại
          await _onRemoveImageBackground();
        }
        break;
      case 1:
        break;
      case 2:
        break;
      case 3:
        break;
      default:
        break;
    }
    if ([LIST_STEP_SELECTION.length - 1].contains(_currentStep.id)) return;
    setState(() {
      // _isLoading = false;
      _currentStep = LIST_STEP_SELECTION[_currentStep.id + 1];
      _tabController.index = _currentStep.id;
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      setState(() {
        _isShowFooterMask = false;
      });
    });
  }

  void _onSelectStepOption(StepModel selectedStepModel) {
    if (selectedStepModel.id < _currentStep.id) {
      _currentStep = selectedStepModel;
      _tabController.index = _currentStep.id;
      _isShowFooterMask = true;
      setState(() {});
      Future.delayed(const Duration(milliseconds: 350), () {
        setState(() {
          _isShowFooterMask = false;
        });
      });
    }
  }

  Future<void> _onExport() async {
    bool isPhone = BlocProvider.of<DevicePlatformCubit>(context).isPhone;

    double height;
    height = (_size.height * 0.5);
    if (isPhone) {
      height = (_size.height * 0.5);
    } else {
      height = min(800, _size.height * 0.9);
    }
    showCustomBottomSheetWithDragIcon(
      context: context,
      child: WExportBody1(
        projectModel: _projectModel,
        height: height,
        countrySelected: _projectModel.countryModel!,
        imageCropped: _projectModel.croppedFile!,
        onUpdateModel: (file) {},
      ),
      height: height,
    );
  }

  Future<void> _onPrint() async {
    double height = _size.height * 0.4;
    showCustomBottomSheetWithDragIcon(
      context: context,
      child: WPrintBody(
        height: height,
        countrySelected: _projectModel.countryModel!,
        croppedFile: _projectModel.croppedFile!,
        uiImageCropped: _projectModel.uiImageCropped!,
      ),
      height: height,
    );
  }

  void _resetAdjustProperties() {
    _projectModel.background = _offsetTrackerBrightness = null;
    _indexSegment = _indexSnapList = 0;
    _projectModel.brightness = 0.0;
    _transformationAdjustController = TransformationController();
    context.read<AdjustSubjectBloc>().add(ResetAdjustSubjectEvent());
  }

  void _resetCropProperties() {
    _matrix4Crop = Matrix4.identity();
    _projectModel.cropModel = null;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _size = MediaQuery.sizeOf(context);
    _isDarkMode = BlocProvider.of<ThemeBloc>(context).isDarkMode;
    return Scaffold(
      backgroundColor: _isDarkMode ? black : white,
      body: Stack(
        children: [
          // header + body
          Column(
            children: [
              //header
              Stack(
                alignment: Alignment.center,
                children: [
                  WHeader(
                    currentStep: _currentStep,
                    onSelectStep: (currentStep) {
                      _onSelectStepOption(currentStep);
                    },
                    isDarkMode: _isDarkMode,
                    isHaveSettingButton: true,
                    width: SIZE_EXAMPLE.width,
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      margin: const EdgeInsets.only(right: 30, top: 20),
                      child: WSettingNavigatorButton(isDarkMode: _isDarkMode),
                    ),
                  ),
                ],
              ),
              //body
              Expanded(
                child: Container(
                  width: _size.width,
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // body
                      Expanded(
                        child: ClipRRect(
                          child: Stack(
                            children: [
                              _buildBodyWithTabView(),
                              // hien footer tam thoi de che hieu ung chuyen canh cho nhung screen tiep theo
                              // chi hien thi khi nguoi dung bam next
                              // sau khi chuyen man hinh xong thi an no di
                              if (_isShowFooterMask)
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: WFooter(
                                    projectModel: _projectModel,
                                    currentStep: _currentStep,
                                    isDarkMode: _isDarkMode,
                                    onNext: _onNext,
                                    onExport: _onExport,
                                    onPrint: _onPrint,
                                    footerHeight: 166,
                                    isHaveSettingButton: false,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // overlay widget
          if (_isLoading == true)
            Positioned.fill(
              child: Container(color: grey.withValues(alpha: 0.2)),
            ),

          // Circular widget
          if (_isLoading == true) const CustomLoadingIndicator(),
        ],
      ),
    );
  }

  Widget _buildBodyWithTabView() {
    return TabBarView(
      physics: const NeverScrollableScrollPhysics(),
      controller: _tabController,
      children: [
        BodyImportTablet(
          projectModel: _projectModel,
          currentStep: _currentStep,
          onUpdateImage: _onUpdateSelectedImage,
          onUpdateStep: _onNext,
          onUpdateLoadingStatus: _updateLoadingStatus,
        ),
        BodyAdjustTablet(
          projectModel: _projectModel,
          offsetTrackerBrightness: _offsetTrackerBrightness,
          indexSegment: _indexSegment,
          indexSnapList: _indexSnapList,
          transformationController: _transformationAdjustController,
          currentStep: _currentStep,
          onUpdateProject: (newModel) {
            _projectModel = newModel;
            setState(() {});
          },
          onNextStep: _onNext,
          // onSelectStep: _onSelectStepOption,
          onUpdateOffsetTracker: (offset) {
            _offsetTrackerBrightness = offset;
            setState(() {});
          },
          onUpdateSegment: (index) {
            _indexSegment = index;
            setState(() {});
          },
          onUpdateSnapList: (index) {
            _indexSnapList = index;
            setState(() {});
          },
          onUpdateLoadingStatus: _updateLoadingStatus,
        ),
        BodyCropTest(
          projectModel: _projectModel,
          matrix4: _matrix4Crop,
          imageSelectedSize: _imageSelectedSize ?? const Size(240, 240),
          screenSize: _size,
          currentStep: _currentStep,
          onSelectStep: (stepModel) {
            _onSelectStepOption(stepModel);
          },
          onUpdateProject: (model) {
            _projectModel = model;
            setState(() {});
          },
          onUpdateMatrix: (matrix) {
            _matrix4Crop = matrix;
            setState(() {});
          },
          onUpdateCropModel: (cropModel) {
            _projectModel = _projectModel..cropModel = cropModel;
            setState(() {});
          },
          uiImageAdjusted: (_projectModel.uiImageAdjusted),
          onUpdateStep: _onNext,
          onUpdateLoadingStatus: _updateLoadingStatus,
        ),
        BodyFinish(
          projectModel: _projectModel,
          screenSize: _size,
          currentStep: _currentStep,
          onExport: _onExport,
          onPrint: _onPrint,
          onUpdateStep: _onNext,
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
