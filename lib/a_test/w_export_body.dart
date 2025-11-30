import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:pass1_/a_test/pdf_function/generate_mimetype.dart';
import 'package:pass1_/a_test/w_export_childs.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/helpers/convert.dart';
import 'package:pass1_/helpers/file_helpers.dart';
import 'package:pass1_/helpers/log_custom.dart';
import 'package:pass1_/helpers/native_bridge/method_channel.dart';
import 'package:pass1_/helpers/navigator_route.dart';
import 'package:pass1_/helpers/random_number.dart';
import 'package:pass1_/models/country_passport_model.dart';
import 'package:pass1_/models/export_size_model.dart';
import 'package:pass1_/models/project_model.dart';
import 'package:pass1_/providers/blocs/device_platform_bloc.dart';
import 'package:pass1_/providers/blocs/theme_bloc.dart';
import 'package:pass1_/screens/module_home/helpers/export_helpers.dart';
import 'package:pass1_/widgets/w_custom_about_dialog.dart';
import 'package:pass1_/widgets/w_custom_value_notifier.dart';
import 'package:pass1_/widgets/w_spacer.dart';
import 'package:share_plus/share_plus.dart';

class WExportBody1 extends StatefulWidget {
  final ProjectModel projectModel;
  final double height;
  final CountryModel countrySelected;
  final File imageCropped;
  final Function(ProjectModel projectModel) onUpdateModel;
  const WExportBody1({
    super.key,
    required this.projectModel,
    required this.height,
    required this.countrySelected,
    required this.imageCropped,
    required this.onUpdateModel,
  });

  @override
  State<WExportBody1> createState() => _WExportBody1State();
}

class _WExportBody1State extends State<WExportBody1> {
  final ValueNotifier<int> _vIndexSegment = ValueNotifier<int>(0);

  final ValueNotifier<int?> _vIndexFocusingFormat = ValueNotifier<int?>(null);

  //copy
  final ValueNotifier<int> _vCopyCount = ValueNotifier<int>(6);
  // size
  final ValueNotifier<ExportSizeModel> _vExportSize =
      ValueNotifier<ExportSizeModel>(LIST_EXPORT_SIZE[1]);
  //
  final ValueNotifier<int> _vIndexImageFormat = ValueNotifier<int>(0);
  final ValueNotifier<int> _vSliderCompressionPercent = ValueNotifier<int>(80);

  final ValueNotifier<int> _vIndexDpiFormat = ValueNotifier<int>(0);
  final ValueNotifier<double> _vSliderDpiResolutionPreview =
      ValueNotifier<double>(600);

  final ValueNotifier<double> _vSliderDpiResolutionMain = ValueNotifier<double>(
    600,
  );

  File? _convertedPhotoFile;
  List<File> _convertedPaperFiles = [];
  late List<double> _listPassportDimensionByInch;
  late Size _size;
  late bool _isPhone;

  final List<GlobalKey> _keysFormat = [];

  final ValueNotifier<List<double>> _vListMinMaxDpi = ValueNotifier(
    LIST_MIN_MAX_RESOLUTION_1,
  );
  final ValueNotifier<Map<int, String>> _vDataSegmentResolution = ValueNotifier(
    DATA_SEGMENT_RESOLUTION_1,
  );

  final ValueNotifier<bool> _isCaculating = ValueNotifier(false);

  /// getters
  int get indexTab => _vIndexSegment.value;
  int get indexImageFormat => _vIndexImageFormat.value;
  bool get isTabPhoto => indexTab == 0;
  bool get isDisableDpiFormat {
    var currentPassport = widget.countrySelected.currentPassport;
    return (isTabPhoto && indexImageFormat != 2) &&
        currentPassport.unit == PIXEL;
  }

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 4; i++) {
      _keysFormat.add(GlobalKey());
    }
  }

  Future<double?> _handleGetFileSize() async {
    if (!_isCaculating.value) {
      _isCaculating.value = true;
    }
    Stopwatch stopwatch = Stopwatch()..start();
    double? result;
    result = 5;
    // result = await _runGetFileSizeOnBackground();
    stopwatch.stop();
    consolelog("_handleGetFileSize call: ${stopwatch.elapsedMilliseconds}");
    if (_isCaculating.value) {
      _isCaculating.value = false;
    }
    return result;
  }

  Future<double?> _runGetFileSizeOnBackground() async {
    var currentPassport = widget.countrySelected.currentPassport;
    bool isOverflowSize = ExportHelpers().checkOverFlowSize(
      _size,
      currentPassport,
      // _vSliderDpiResolutionMain.value,
    );
    if (isOverflowSize) {
      return null;
    }
    if (isTabPhoto) {
      Map<String, dynamic> result = await ExportHelpers.handleGetFileSize(
        indexImageFormat: indexImageFormat,
        imageCropped: widget.imageCropped,
        countrySelected: widget.countrySelected,
        // screenSize: _size,
        valueResolutionDpi: _vSliderDpiResolutionMain.value,
        // listPassportDimensionByInch: _listPassportDimensionByInch,
        quality: _vSliderCompressionPercent.value,
      );

      File? outputFile = result["outputFile"];
      if (outputFile != null && _convertedPhotoFile?.path != outputFile.path) {
        _convertedPhotoFile = outputFile;
      }
      return result['fileSize'];
    } else {
      double sum = 0.0;
      List<File> listPaperFile = await ExportHelpers.onGenerateExportFiles(
        projectModel: widget.projectModel,
        exportSize: _vExportSize.value,
        copyNumber: _vCopyCount.value,
        valueResolutionDpi: _vSliderDpiResolutionMain.value,
        indexImageFormat: indexImageFormat,
        countrySelected: widget.countrySelected,
        screenSize: _size,
        listPassportDimensionByInch: _listPassportDimensionByInch,
        quality: _vSliderCompressionPercent.value,
      );
      _convertedPaperFiles = listPaperFile;

      for (var item in listPaperFile) {
        sum += (await item.length());
      }
      return sum / MB_TO_KB;
    }
  }

  Future<bool> _onSaveTo({
    required int indexImageFormat,
    required List<File> files,
    required List<String> listFileName,
  }) async {
    if (files.isNotEmpty) {
      String mimeType = generateMimeType(indexImageFormat);

      final pickedDirectory = await FlutterFileDialog.pickDirectory();
      if (pickedDirectory != null) {
        for (var i = 0; i < files.length; i++) {
          File? item = files[i];
          String fileName = listFileName[i];
          await FlutterFileDialog.saveFileToDirectory(
            directory: pickedDirectory,
            data: item.readAsBytesSync(),
            mimeType: mimeType,
            fileName: fileName,
            replace: false,
          );
        }
        return true;
      } else {
        return false;
      }
    } else {
      showCustomAboutDialog(
        context,
        360,
        "Error",
        "Cannot save your photo.",
        titleColor: red,
      );
      return false;
    }
  }

  Future<bool> _onShare({
    required int indexImageFormat,
    required List<File> files,
    required List<String> listFileName,
  }) async {
    if (files.isNotEmpty) {
      ShareResult result = await Share.shareXFiles(
        files.map((e) => XFile(e.path)).toList(),
      );
      return result.status == ShareResultStatus.success;
    } else {
      showCustomAboutDialog(
        context,
        360,
        "Error",
        "Cannot save your photo.",
        titleColor: red,
      );
      return false;
    }
  }

  Future<void> _onSaveToLibrary({
    required List<File> listFile,
    required int indexImageFormat,
    required List<String> listFileName,
  }) async {
    if (listFile.isNotEmpty) {
      if (indexImageFormat == 2) {
        await MyMethodChannel.createActionDocument([
          listFile[0].path,
        ], indexImageFormat);
      } else {
        List<File?> resultFiles = [];
        for (var i = 0; i < listFile.length; i++) {
          var item = listFile[i];
          String fileName = listFileName[i];

          File outputFile = await saveToLibrary(
            indexImageFormat: indexImageFormat,
            inputFile: item,
            fileName: fileName,
          );
          resultFiles.add(outputFile);
        }
        consolelog("resultFiles on Save toLibrary ${resultFiles}");
      }

      double dialogWidth = 360;
      String content = "Your photo is saved successfully.";
      String title = "Saved";
      // ignore: use_build_context_synchronously
      showCustomAboutDialog(context, dialogWidth, title, content);
    } else {
      showCustomAboutDialog(
        context,
        360,
        "Error",
        "Cannot save your photo.",
        titleColor: red,
      );
    }
  }

  ///
  /// output: [ listFile, fileName]
  ///
  List<dynamic> preparSavedData() {
    List<File> listFile = [];
    if (indexTab == 0) {
      listFile.add(_convertedPhotoFile!);
    } else {
      for (var i = 0; i < _convertedPaperFiles.length; i++) {
        File item = _convertedPaperFiles[i];
        listFile.add(item);
      }
    }
    List<String> listFileName = [];
    int randomNumber = randomInt();
    for (var i = 0; i < listFile.length; i++) {
      String fileName =
          ("passport_$randomNumber.${EXPORT_SEGMENT_COMPRESSION_IMAGE_FORMAT[indexImageFormat]!.toLowerCase()}");

      if (i != 0) {
        fileName =
            ("passport_$randomNumber ($i).${EXPORT_SEGMENT_COMPRESSION_IMAGE_FORMAT[indexImageFormat]!.toLowerCase()}");
      }
      listFileName.add(fileName);
    }

    return [listFile, listFileName];
  }

  @override
  Widget build(BuildContext context) {
    // consolelog("widget.projectModel.scaledCroppedImage ${widget.projectModel.scaledCroppedImage}");
    _size = MediaQuery.sizeOf(context);
    _size = Size(min(SIZE_EXAMPLE.width, _size.width), _size.height);
    _isPhone = BlocProvider.of<DevicePlatformCubit>(context).isPhone;
    final currentPassport = widget
        .countrySelected
        .listPassportModel[widget.countrySelected.indexSelectedPassport];

    if (currentPassport.unit == PIXEL) {
      _listPassportDimensionByInch = [
        currentPassport.width / _vSliderDpiResolutionMain.value,
        currentPassport.height / _vSliderDpiResolutionMain.value,
      ];
    } else {
      _listPassportDimensionByInch = [
        FlutterConvert.convertUnit(
          currentPassport.unit,
          INCH,
          currentPassport.width,
        ),
        FlutterConvert.convertUnit(
          currentPassport.unit,
          INCH,
          currentPassport.height,
        ),
      ];
    }
    consolelog("_listPassportDimensionByInch: $_listPassportDimensionByInch");
    Color backgroundColor = Theme.of(context).appBarTheme.backgroundColor!;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        color: backgroundColor,
        child: Stack(children: [_buildBlurBg(backgroundColor), _buildBody()]),
      ),
    );
  }

  Widget _buildBlurBg(Color color) {
    return WExports.buildBlurBackground(widget.height, color);
  }

  Widget _buildBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildAnalyze(),
        WSpacer(height: 15),
        _buildSegments(),
        WSpacer(height: 15),
        Expanded(child: _buildPreview()),
        WSpacer(height: 15),
        _buildFormats(),
        WSpacer(height: 15),
        _buildButtons(),
      ],
    );
  }

  Widget _buildAnalyze() {
    bool isDarkMode = BlocProvider.of<ThemeBloc>(
      context,
      listen: true,
    ).isDarkMode;
    var countrySelected = widget.countrySelected;
    return Container(
      margin: const EdgeInsets.only(top: 15),
      child: Stack(
        alignment: Alignment.center,
        children: [
          FittedBox(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                WExports.buildAnalyzePaperSize(
                  context,
                  countrySelected,
                  isDarkMode,
                ),
                WExports.buildAnalyzeDot(context, isDarkMode),
                ValueListenableBuilder(
                  valueListenable: ValuesListenablesCustom(
                    valueListenables: [_vSliderDpiResolutionPreview],
                  ),
                  builder: (context, _, child) {
                    return WExports.buildAnalyzeDimension(
                      context: context,
                      screenSize: _size,
                      isDarkMode: isDarkMode,
                      countrySelected: countrySelected,
                      dpi: _vSliderDpiResolutionPreview.value,
                      indexImageFormat: indexImageFormat,
                      indexTab: indexTab,
                      textColorWhenOverSize: red,
                    );
                  },
                ),
                WExports.buildAnalyzeDot(context, isDarkMode),
                ValueListenableBuilder(
                  valueListenable: ValuesListenablesCustom(
                    valueListenables: [_vIndexImageFormat],
                  ),
                  builder: (context, _, child) {
                    return WExports.buildAnalyzeOutputFormat(
                      context,
                      isDarkMode,
                      EXPORT_SEGMENT_COMPRESSION_IMAGE_FORMAT[indexImageFormat]!,
                    );
                  },
                ),
                WExports.buildAnalyzeDot(context, isDarkMode),
                ValueListenableBuilder(
                  valueListenable: ValuesListenablesCustom(
                    valueListenables: [
                      _vIndexSegment,
                      _vCopyCount,
                      _vExportSize,
                      _vIndexImageFormat,
                      _vSliderCompressionPercent,
                      _vSliderDpiResolutionMain,
                    ],
                  ),
                  builder: (context, _, child) {
                    return FutureBuilder<double?>(
                      future: _handleGetFileSize(),
                      builder: (context, snapshot) {
                        double? data;
                        if (snapshot.connectionState == ConnectionState.done) {
                          data = snapshot.data;
                        }
                        return WExports.buildAnalyzeFileSize(
                          context: context,
                          isDarkMode: isDarkMode,
                          fileSize: data,
                          size: _size,
                          countrySelected: countrySelected,
                          valueResolution: _vSliderDpiResolutionMain.value,
                          listPassportDimensionByInch:
                              _listPassportDimensionByInch,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                popNavigator(context);
              },
              child: Container(
                height: 28,
                width: 28,
                margin: const EdgeInsets.only(right: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: isDarkMode ? white005 : black005,
                ),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: isDarkMode ? white04 : black04,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegments() {
    return ValueListenableBuilder(
      valueListenable: ValuesListenablesCustom(
        valueListenables: [_vIndexSegment],
      ),
      builder: (context, _, child) {
        return WExports.buildSegments(
          context: context,
          indexSelectedSegment: indexTab,
          isPhone: _isPhone,
          onSegmentChange: (value, prev) {
            if (value != prev) {
              if (value == 0) {
                _vListMinMaxDpi.value = LIST_MIN_MAX_RESOLUTION_1;
                _vDataSegmentResolution.value = DATA_SEGMENT_RESOLUTION_1;
                _vIndexDpiFormat.value = 0;
                // _vSliderDpiResolutionPreview.value = 600;
                // _vSliderDpiResolutionMain.value = 600;
              } else {
                _vListMinMaxDpi.value = LIST_MIN_MAX_RESOLUTION_2;
                _vDataSegmentResolution.value = DATA_SEGMENT_RESOLUTION_2;
                _vIndexDpiFormat.value = 1;
                // _vSliderDpiResolutionPreview.value = 600;
                // _vSliderDpiResolutionMain.value = 600;
              }
              _vIndexSegment.value = value;
            }
          },
        );
      },
    );
  }

  Widget _buildPreview() {
    return ValueListenableBuilder(
      valueListenable: ValuesListenablesCustom(
        valueListenables: [
          _vIndexSegment,
          _vExportSize,
          _vCopyCount,
          // _vSliderDpiResolutionMain
        ],
      ),
      builder: (context, _, child) {
        return WExports.buildPreview(
          context: context,
          exportSize: _vExportSize.value,
          indexSelectedSegment: indexTab,
          screenSize: _size,
          projectModel: widget.projectModel,
          copyNumber: _vCopyCount.value,
          valueResolutionDpi: _vSliderDpiResolutionMain.value,
        );
      },
    );
  }

  Widget _buildFormats() {
    return ValueListenableBuilder(
      valueListenable: ValuesListenablesCustom(
        valueListenables: [
          _vCopyCount,
          _vExportSize,
          _vIndexSegment,
          _vIndexFocusingFormat,
          _vSliderCompressionPercent,
          _vIndexImageFormat,
          _vSliderDpiResolutionPreview,
          _vIndexDpiFormat,
          _vListMinMaxDpi,
          _vDataSegmentResolution,
        ],
      ),
      builder: (context, _, child) {
        return WExports.buildFormats(
          isDisableDpiFormat: isDisableDpiFormat,
          context: context,
          screenSize: _size,
          indexSelectedSegment: indexTab,
          projectModel: widget.projectModel,
          keysFormat: _keysFormat,
          copyNumber: _vCopyCount.value,
          exportSize: _vExportSize.value,
          compressionPercent: _vSliderCompressionPercent.value,
          dpiResolution: _vSliderDpiResolutionMain.value,
          indexImageFormat: indexImageFormat,
          listMinMaxDpi: _vListMinMaxDpi.value,
          dataSegmentResolution: _vDataSegmentResolution.value,
          indexDpiFormat: _vIndexDpiFormat.value,
          indexFocusingFormat: _vIndexFocusingFormat.value,
          onChangeCopy: (value) {
            _vCopyCount.value = value;
          },
          onChangeSizeFormat: (value) {
            _vExportSize.value = value;
          },
          onChangeCompressionPercent: (percent) {
            // _vSliderCompressionPercent.value = percent;
          },
          onCompressionEnd: (percent) {
            _vSliderCompressionPercent.value = percent;
          },
          onChangeImageFormat: (index) {
            _vIndexImageFormat.value = index;
          },
          onChangeDPIResolution: (dpi) {
            _vSliderDpiResolutionPreview.value = dpi;
          },
          onChangeDPIResolutionEnd: (dpi) {
            _vSliderDpiResolutionMain.value = dpi;
          },
          onChangeDpiFormat: (index) {
            _vIndexDpiFormat.value = index;
          },
          onTapFormat: (index) {
            _vIndexFocusingFormat.value = index;
          },
        );
      },
    );
  }

  Widget _buildButtons() {
    return ValueListenableBuilder(
      valueListenable: ValuesListenablesCustom(
        valueListenables: [
          _vIndexImageFormat,
          // _isCaculating,
        ],
      ),
      builder: (context, _, child) {
        return WExports.buildButtons(
          context: context,
          screenSize: _size,
          indexImageFormat: indexImageFormat,
          onSaveTo: () async {
            if (_isCaculating.value) return;
            List<dynamic> listData = preparSavedData();
            // check overflow size
            var overFlowSize = ExportHelpers().checkOverFlowSize(
              _size,
              widget.countrySelected.currentPassport,
              // _vSliderDpiResolutionMain.value,
            );
            if (overFlowSize) {
              ExportHelpers().showWarningExport(context);
              return;
            }
            _onShare(
              indexImageFormat: indexImageFormat,
              files: listData[0],
              listFileName: listData[1],
            );
          },
          onSaveToLibrary: () async {
            if (_isCaculating.value) return;
            // check overflow size
            var overFlowSize = ExportHelpers().checkOverFlowSize(
              _size,
              widget.countrySelected.currentPassport,
              // _vSliderDpiResolutionMain.value,
            );
            if (overFlowSize) {
              ExportHelpers().showWarningExport(context);
              return;
            }
            List<dynamic> listData = preparSavedData();
            _onSaveToLibrary(
              indexImageFormat: indexImageFormat,
              listFile: listData[0],
              listFileName: listData[1],
            );
          },
        );
      },
    );
  }
}
