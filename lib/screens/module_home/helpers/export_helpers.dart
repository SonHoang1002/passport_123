import 'dart:math';

import 'package:passport_photo_2/commons/colors.dart';
import 'package:passport_photo_2/commons/extension.dart';
import 'package:passport_photo_2/helpers/convert.dart';
import 'package:passport_photo_2/widgets/w_custom_about_dialog.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:passport_photo_2/a_test/pdf_function/generate_pdf_helpers.dart';
import 'package:passport_photo_2/models/project_model.dart';
import 'package:pdf/pdf.dart';
import 'package:flutter/cupertino.dart';
import 'package:passport_photo_2/a_test/w_dialog_title_body.dart';
import 'package:passport_photo_2/a_test/w_export_childs.dart';
import 'package:passport_photo_2/commons/constants.dart';
import 'package:passport_photo_2/helpers/caculate_file_size.dart';
import 'package:passport_photo_2/helpers/log_custom.dart';
import 'package:passport_photo_2/helpers/native_bridge/method_channel.dart';
import 'package:passport_photo_2/helpers/navigator_route.dart';
import 'package:passport_photo_2/models/country_passport_model.dart';
import 'package:passport_photo_2/models/export_size_model.dart';
import 'package:passport_photo_2/screens/module_home/widgets/childs/w_export_compression_dialog.dart';
import 'package:passport_photo_2/screens/module_home/widgets/childs/w_export_dpi_dialog.dart';
import 'package:passport_photo_2/widgets/general_dialog/w_body_dialogs.dart';
import 'package:passport_photo_2/widgets/general_dialog/w_general_dialog.dart';
import 'package:path_provider/path_provider.dart';

class ExportHelpers {
  static Future<List<File>> onGenerateExportFiles({
    required ProjectModel projectModel,
    required ExportSizeModel exportSize,
    required int copyNumber,
    required double valueResolutionDpi,
    required int indexImageFormat,
    required CountryModel countrySelected,
    required Size screenSize,
    required List<double> listPassportDimensionByInch,
    required int quality,
  }) async {
    (ui.Image, Uint8List) imageData = await _loadImageData(
      projectModel,
      indexImageFormat,
      countrySelected,
      screenSize,
      valueResolutionDpi,
      listPassportDimensionByInch,
      quality,
    );

    Map<String, dynamic> drawResult = GeneratePdfHelpers().draw(
      projectModel,
      exportSize,
      copyNumber,
      imageData.$1,
      valueResolutionDpi,
    );
    List<ui.Image> images = drawResult["listUiImage"];
    Size paperSizeDraw = drawResult[
        "paperSizeConvertedByPoint"]; // Kích thước giấy PDF, đơn vij pixel
    Size passportSizeDrawByPoint = drawResult[
        "passportSizeLimitedByPoint"]; // Kích thước ảnh hộ chiếu sau khi đã limit, đơn vị pixel
    double spacingHorizontalByPoint = drawResult["spacingHorizontalByPoint"];
    double spacingVerticalByPoint = drawResult["spacingVerticalByPoint"];
    EdgeInsets marginByPoint = drawResult["marginByPoint"];

    Stopwatch stopwatch = Stopwatch();
    stopwatch.start();

    List<File> listMainFile = [];

    // Trường hợp
    // số lượng ảnh lớn hơn 2 -> generate ra 2 ảnh duy nhất : ảnh đầu tiên và ảnh cuối cùng
    // con truong hop images.length == copynumber -> gen 1 anh duy nhat
    if (images.length > 2) {
      List<File> listTempFile = [];
      List<ui.Image> collapseList = [images.first, images.last];
      for (var i = 0; i < collapseList.length; i++) {
        var item = collapseList[i];
        Uint8List? bytes =
            (await item.toByteData(format: ui.ImageByteFormat.png))
                ?.buffer
                .asUint8List();

        final directory = await getExternalStorageDirectory();
        final String path = '${directory!.path}/test_save_to_$i.png';

        File file = File(path);
        await file.writeAsBytes(bytes!);
        listTempFile.add(file);
      }
      for (var i = 0; i < images.length; i++) {
        if (i < images.length - 1) {
          listMainFile.add(listTempFile[0]);
        } else {
          listMainFile.add(listTempFile[1]);
        }
      }
    } else {
      for (var i = 0; i < images.length; i++) {
        var item = images[i];
        Uint8List? bytes =
            (await item.toByteData(format: ui.ImageByteFormat.png))
                ?.buffer
                .asUint8List();
        final directory = await getExternalStorageDirectory();
        final String path = '${directory!.path}/test_save_to_$i.png';
        File file = File(path);
        await file.writeAsBytes(bytes!);
        listMainFile.add(file);
      }
    }
    bool isPDFFormat =
        indexImageFormat == EXPORT_SEGMENT_COMPRESSION_IMAGE_FORMAT.length - 1;
    if (isPDFFormat) {
      File result = await GeneratePdfHelpers().generatePaperPdf(
        projectModel,
        paperSizeDraw,
        passportSizeDrawByPoint,
        copyNumber,
        valueResolutionDpi,
        [spacingHorizontalByPoint, spacingVerticalByPoint],
        marginByPoint,
        quality,
      );
      consolelog(
          "multi pdf: image data length: ${imageData.$2.length} - pdf data length: ${result.readAsBytesSync().length}");
      listMainFile = [result];
    }

    stopwatch.stop();
    consolelog("stopwatch abc listMainFile ${listMainFile.length}");
    return listMainFile;
  }

  static Future<(ui.Image, Uint8List)> _loadImageData(
    ProjectModel projectModel,
    int indexImageFormat,
    CountryModel countrySelected,
    Size screenSize,
    double valueResolution,
    List<double> listPassportDimensionByInch,
    int quality,
  ) async {
    Stopwatch stopwatch = Stopwatch();
    stopwatch.start();

    // is generate pdf -> lay jpg
    int indexImageFormat0 = indexImageFormat;
    if (indexImageFormat == 2) {
      indexImageFormat0 = 0;
    }
    File? resizedFile = await _resizeImage(
      projectModel.croppedFile!,
      indexImageFormat0,
      countrySelected,
      screenSize,
      valueResolution,
      listPassportDimensionByInch,
      quality,
    );
    Uint8List bytes = await resizedFile!.readAsBytes();

    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      completer.complete(img);
    });

    stopwatch.stop();
    ui.Image image = await completer.future;
    return (image, bytes);
  }

  // in ra theo kích cỡ của passport
  // trong đó ảnh sẽ được resize theo dpi
  /// Trả ra {
  ///   "outputFile": ,
  ///   "fileSize": ,
  /// };
  static Future<Map<String, dynamic>> handleGetFileSize({
    required int indexImageFormat,
    required File imageCropped,
    required CountryModel countrySelected,
    required Size screenSize,
    required double valueResolutionDpi,
    required List<double> listPassportDimensionByInch,
    required int quality,
  }) async {
    double dpi = valueResolutionDpi;
    Map<String, dynamic> result = {
      "outputFile": null,
      "fileSize": 0.0,
    };
    try {
      int indexImageFormat0 = indexImageFormat;

      /// Kiểm tra xem đang dùng for
      bool idPdfFormat = indexImageFormat ==
          EXPORT_SEGMENT_COMPRESSION_IMAGE_FORMAT.length - 1;

      /// Tạo path IMAGE cuối cùng để ghi dữ liệu đã generate vào
      final dirPath = (await getExternalStorageDirectory())!.path;
      String extension = LIST_FORMAT_IMAGE[indexImageFormat0].toLowerCase();
      String outImagePath = "$dirPath/$FINISH_IMAGE_NAME.$extension";

      // if (idPdfFormat) {
      //   File? pdfFile;

      //   /// Nếu là ảnh binhf thường
      //   /// -> chuyển đơn vị hiện tại sang đơn vị pixel để so sánh giới hạn
      //   /// Nếu in ấn
      //   /// -> chuyển đơn vị hiện tại sang đơn vị pixel ( KÈM THEO DPI ), công thức với value như sau:
      //   ///
      //   /// input: pixel -> output: value
      //   /// input: point -> output: value / 72 * dpi  ( điểm in )
      //   /// input: cm    -> output: value / 2.54 * dpi
      //   /// input: mm    -> output: value / 2.54 * dpi / 10

      //   /// Giới hạn kích thước mà user muốn in
      //   /// Trả về kích thước với đơn vị pixel để sử dụng cho việc resize ảnh phía sau

      //   double widthInInch, heightInInch;

      //   // 2️⃣ Chuyển inch → pixel theo DPI
      //   Size passportSizeByPixel = Size(
      //     widthInInch * dpi,
      //     heightInInch * dpi,
      //   );

      //   /// Kích thước ảnh (pixel) giành cho

      //   /// Sử dụng ảnh original đã cắt, điều chỉnh chất lượng hình ảnh
      //   /// Giữu nguyên kích thước đã cắt
      //   ///
      //   /// Trong trường hợp user muốn in với ảnh quá to -> giới hạn nó xuống mức giới hạn tuỳ vào cỡ của màn hình (5000 haowjc 9000px)
      //   File? resizedFile = await MyMethodChannel.resizeAndResoluteImage(
      //     inputPath: imageCropped.path,
      //     format: indexImageFormat0,
      //     listWH: [passportSizeByPixel.width, passportSizeByPixel.height],
      //     scaleWH: [1, 1],
      //     outPath: outImagePath,
      //     quality: quality,
      //   );

      //   if (resizedFile != null) {
      //     PassportModel currentPassport = countrySelected.currentPassport;

      //     double passportWidthConverted, passportHeightConverted;
      //     if (currentPassport.unit == PIXEL) {
      //       passportWidthConverted =
      //           currentPassport.width / valueResolutionDpi * 72;
      //       passportHeightConverted =
      //           currentPassport.height / valueResolutionDpi * 72;
      //     } else {
      //       passportWidthConverted = FlutterConvert.convertUnit(
      //           currentPassport.unit, POINT, currentPassport.width);
      //       passportHeightConverted = FlutterConvert.convertUnit(
      //           currentPassport.unit, POINT, currentPassport.height);
      //     }
      //     consolelog("valueResolutionDpi = $valueResolutionDpi");
      //     pdfFile = await GeneratePdfHelpers().generateSingleImagePdf(
      //       Size(passportWidthConverted, passportHeightConverted),
      //       [resizedFile],
      //     );
      //     // single pdf: image data length: 927866 - pdf data length: 928820
      //     consolelog(
      //         "single pdf: image data length: ${resizedFile.readAsBytesSync().length} - pdf data length: ${pdfFile!.readAsBytesSync().length}");
      //   }
      //   if (pdfFile != null) {
      //     double fileSize = await getFileSize(pdfFile);
      //     result['outputFile'] = pdfFile;
      //     result['fileSize'] = fileSize;
      //   }
      // } else {
      var currentPassport = countrySelected.currentPassport;
      double passportWidthByPixel, passportHeightByPixel;
      if (currentPassport.unit == PIXEL) {
        passportWidthByPixel = currentPassport.width;
        passportHeightByPixel = currentPassport.height;
      } else {
        /// 
        /// inch=⎩
⎨
⎧​pixel/DPIpt/72cm/2.54mm/25.4inch​neˆˊu đơn vị laˋ pixelneˆˊu đơn vị laˋ pointneˆˊu đơn vị laˋ cmneˆˊu đơn vị laˋ mminchthıˋgiữnguye^n​
      }

      File? resizedFile = await MyMethodChannel.resizeAndResoluteImage(
        inputPath: imageCropped.path,
        format: indexImageFormat0,
        listWH: [passportWidthByPixel, passportHeightByPixel],
        scaleWH: [1, 1],
        outPath: outImagePath,
        quality: quality,
      );
      if (resizedFile != null) {
        double fileSize = await getFileSize(resizedFile);

        result['outputFile'] = resizedFile;
        result['fileSize'] = fileSize;
      }
      // }
    } catch (e) {
      consolelog("handleGetFileSize error: $e");
    }
    consolelog("result from handleGetFileSize: $result");
    return result;
  }

  static Future<File?> _resizeImage(
    File imageCropped,
    int indexImageFormat,
    CountryModel countrySelected,
    Size size,
    double valueResolution,
    List<double> listPassportDimensionByInch,
    int quality,
  ) async {
    final dirPath = (await getExternalStorageDirectory())!.path;
    String extension = LIST_FORMAT_IMAGE[indexImageFormat].toLowerCase();
    String outPath = "$dirPath/$FINISH_IMAGE_NAME.$extension";

    // Size abc = handleLimitDPI(
    //     countrySelected, size, valueResolution, listPassportDimensionByInch);

    final resizedFile = await MyMethodChannel.resizeAndResoluteImage(
      inputPath: imageCropped.path,
      format: indexImageFormat,
      // [abc.width, abc.height],
      // [1, 1],
      outPath: outPath,
      quality: quality,
    );
    return resizedFile;
  }

  static Future<Uint8List?> createPdfFromImageFile(String imagePath) async {
    final imageFile = File(imagePath);

    if (!imageFile.existsSync()) {
      print("File does not exist: $imagePath");
      return null;
    }

    final image = img.decodeImage(imageFile.readAsBytesSync());

    if (image == null) {
      print("Unable to decode image");
      return null;
    }

    final pdf = pw.Document();
    final imageProvider = pw.MemoryImage(
      imageFile.readAsBytesSync(),
    );

    // Tạo trang PDF với kích thước bằng với ảnh
    pdf.addPage(
      pw.Page(
        pageFormat:
            PdfPageFormat(image.width.toDouble(), image.height.toDouble()),
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(imageProvider),
          );
        },
      ),
    );

    final outputDir = await getExternalStorageDirectory();
    final outputFile = File("${outputDir!.path}/output.pdf");
    var data = await pdf.save();
    await outputFile.writeAsBytes(data);

    return data;
  }

  /// Trả về kích thước by pixel
  ///
  ///
  /// *[countrySelected] - > Dùng để lấy kích thước của passport
  ///
  /// *[screenSize] -> Dùng để xác định độ phân giải lớn nhất mà thiết bị cho phép compress
  ///
  /// *[valueResolution] -> Chỉ số DPI đích
  ///
  /// *[listPassportDimensionByInch] -> Kích thước của passport  by inch
  ///
  static Size handleLimitDPI(
    CountryModel countrySelected,
    Size screenSize,
    double dpi,
    Size passportSizeByPixelWithDpi,
    bool idPdfFormat, {
    bool isNotLimit = false,
  }) {
    double targetWidth;
    double targetHeight;
    var currentPassport = countrySelected.currentPassport;
    double widthInInch = FlutterConvert.convertUnitToInchWithDPI(
      currentPassport.unit,
      currentPassport.width,
      dpi,
      idPdfFormat,
    );
    double heightInInch = FlutterConvert.convertUnitToInchWithDPI(
      currentPassport.unit,
      currentPassport.height,
      dpi,
      idPdfFormat,
    );

    // 2️⃣ Chuyển inch → pixel theo DPI
    Size passportSizeByPixelWithDpi = Size(
      widthInInch * dpi,
      heightInInch * dpi,
    );

    /// Đổi kích thước passport sang đơn vị pixel
    double ratioWH;
    consolelog(
        "handleLimitDPI passportSizeByPixelWithDpi = $passportSizeByPixelWithDpi");
    targetWidth = passportSizeByPixelWithDpi.width;
    targetHeight = passportSizeByPixelWithDpi.height;
    if (targetHeight <= 0) {
      targetHeight = 0.1;
    }
    if (targetWidth <= 0) {
      targetWidth = 0.1;
    }
    ratioWH = targetWidth / targetHeight;
    if (screenSize.width > MIN_SIZE.width) {
      if (targetHeight > MAX_SIZE_EXPORT_IMAGE_NORMAL ||
          targetWidth > MAX_SIZE_EXPORT_IMAGE_NORMAL) {
        if (ratioWH > 1) {
          targetWidth = MAX_SIZE_EXPORT_IMAGE_NORMAL;
          targetHeight = targetWidth * (1 / ratioWH);
        } else if (ratioWH < 1) {
          targetHeight = MAX_SIZE_EXPORT_IMAGE_NORMAL;
          targetWidth = targetHeight * ratioWH;
        } else {
          targetWidth = targetHeight = MAX_SIZE_EXPORT_IMAGE_NORMAL;
        }
      }
    } else {
      if (targetWidth >= MAX_SIZE_EXPORT_IMAGE_WEAK ||
          targetHeight >= MAX_SIZE_EXPORT_IMAGE_WEAK) {
        if (ratioWH > 1) {
          targetWidth = MAX_SIZE_EXPORT_IMAGE_WEAK;
          targetHeight = targetWidth * (1 / ratioWH);
        } else if (ratioWH < 1) {
          targetHeight = MAX_SIZE_EXPORT_IMAGE_WEAK;
          targetWidth = targetHeight * ratioWH;
        } else {
          targetWidth = targetHeight = MAX_SIZE_EXPORT_IMAGE_WEAK;
        }
      }
    }

    return Size(targetWidth, targetHeight);
  }

  static String handlePreviewFileSize(
    double? fileSizeByKB,
    CountryModel countrySelected,
    Size size,
    double valueResolution,
    List<double> listPassportDimensionByInch,
  ) {
    if (fileSizeByKB == null) return "--KB";

    // Size abc = ExportHelpers.handleLimitDPI(
    //     countrySelected, size, valueResolution, listPassportDimensionByInch);
    // if (size.width > MIN_SIZE.width) {
    //   if (abc.width > MAX_SIZE_EXPORT_IMAGE_NORMAL ||
    //       abc.height > MAX_SIZE_EXPORT_IMAGE_NORMAL) {
    //     return "---";
    //   }
    // } else {
    //   if (abc.width > MAX_SIZE_EXPORT_IMAGE_WEAK ||
    //       abc.height > MAX_SIZE_EXPORT_IMAGE_WEAK) {
    //     return "---";
    //   }
    // }

    if (fileSizeByKB > MB_TO_KB) {
      return "${(fileSizeByKB / MB_TO_KB).roundWithUnit(fractionDigits: 2)}MB";
    } else {
      return "${fileSizeByKB.roundWithUnit(fractionDigits: 2)}KB";
    }
  }

  static String getPreviewSize(ExportSizeModel sizeModel) {
    if (sizeModel.title != LIST_EXPORT_SIZE.last.title) {
      return sizeModel.title;
    } else {
      return "${sizeModel.size.width.roundWithUnit(fractionDigits: 0)}x${sizeModel.size.height.roundWithUnit(fractionDigits: 0)}${sizeModel.unit.title}";
    }
  }

  static void onChangeCopyCount({
    required BuildContext context,
    required GlobalKey keyCopy,
    required void Function(int count) onChangeCopyCount,
    required void Function() onTapOutside,
  }) {
    double heightDialog = MediaQuery.sizeOf(context).height * 0.45;
    double itemHeight = 44.0;
    RenderBox renderBox =
        keyCopy.currentContext?.findRenderObject() as RenderBox;
    Offset offset = renderBox.localToGlobal(const Offset(0, 0)
        .translate(-5, -heightDialog - (renderBox.size.height) - 35));
    showCustomDialogWithOffset(
      context: context,
      newScreen: BodyDialogCustom(
        offset: offset,
        dialogWidget: WExports.buildDialogBody(
          context: context,
          listValue: List.generate(100, (index) => "${index + 1}").toList(),
          onSelected: (value) {
            onChangeCopyCount(int.parse(value));
            popNavigator(context);
          },
          itemHeight: itemHeight,
          textAlignCenter: true,
          maxHeight: heightDialog,
        ),
        scaleAlignment: Alignment.bottomCenter,
        onTapBackground: () {
          onTapOutside();
          popNavigator(context);
        },
      ),
    );
  }

  static void onChangeSize({
    required BuildContext context,
    required GlobalKey keySize,
    required void Function(ExportSizeModel size) onChangeSize,
    required ExportSizeModel currentExportSize,
    required void Function() onTapOutside,
  }) {
    double itemHeight = 44.0;
    RenderBox renderBox =
        keySize.currentContext?.findRenderObject() as RenderBox;
    double heightOfDialog = (itemHeight) * LIST_EXPORT_SIZE.length;
    Offset offset = renderBox.localToGlobal(const Offset(0, 0)).translate(
          -5,
          -heightOfDialog - (renderBox.size.height - 10),
        );

    showCustomDialogWithOffset(
      context: context,
      newScreen: BodyDialogCustom(
        offset: offset,
        dialogWidget: WExports.buildDialogBody(
          context: context,
          listValue: LIST_EXPORT_SIZE.map((e) => e.title).toList(),
          onSelected: (value) {
            ExportSizeModel? sizeModel = LIST_EXPORT_SIZE
                .where((element) => element.title == value)
                .toList()
                .firstOrNull;
            if (value == LIST_EXPORT_SIZE.last.title) {
              sizeModel = currentExportSize.copyWith(
                title: LIST_EXPORT_SIZE.last.title,
              );
              popNavigator(context);
              ExportHelpers.showDialogCustomSize(
                context,
                sizeModel,
                () {
                  onTapOutside();
                },
                (width, height) {
                  // check value before apply
                  if (width > 0 && height > 0) {
                    if (width > 5000 || height > 5000) {
                      onChangeSize(sizeModel!);
                      return;
                    }
                    onChangeSize(
                      sizeModel!.copyWith(
                        size: Size(width, height),
                      ),
                    );
                  }
                },
              );
            } else {
              if (sizeModel != null) {
                onChangeSize(sizeModel);
                popNavigator(context);
              }
            }
          },
          maxHeight: heightOfDialog,
        ),
        scaleAlignment: Alignment.bottomCenter,
        onTapBackground: () {
          onTapOutside();
          popNavigator(context);
        },
      ),
    );
  }

  static void onChangeCompression({
    required BuildContext context,
    required GlobalKey key,
    required int currentCompression,
    required int currentIndexImageFormat,
    required void Function(int percent) onChangeCompression,
    required void Function(int prev, int index) onChangeImageFormat,
    required void Function() onTapOutside,
    required void Function(int percent) onCompressionEnd,
  }) {
    RenderBox renderBox = key.currentContext?.findRenderObject() as RenderBox;

    Offset offset = renderBox
        .localToGlobal(
          const Offset(0, 0),
        )
        .translate(
          0,
          -172 - (renderBox.size.height - 15),
        );

    showCustomDialogWithOffset(
      context: context,
      newScreen: BodyDialogCustom(
        offset: offset,
        dialogWidget: WExportCompression(
          onChangeCompression: onChangeCompression,
          onChangeImageFormat: onChangeImageFormat,
          currentCompression: currentCompression,
          currentIndexImageFormat: currentIndexImageFormat,
          onCompressionEnd: onCompressionEnd,
        ),
        scaleAlignment: Alignment.bottomLeft,
        onTapBackground: () {
          onTapOutside();
          popNavigator(context);
        },
      ),
    );
  }

  static void onChangeDPI({
    required BuildContext context,
    required GlobalKey key,
    required double currentDpiResolution,
    required int currentIndexDpiFormat,
    required int indexImageFormat,
    required Map<int, String> dataSegmentResolution,
    required List<double> listMinMaxDpi,
    required int indexSegmentMain,
    required void Function(double dpi) onChangeDpiResolution,
    required void Function(double dpi) onChangeDPIResolutionEnd,
    required void Function(int index) onChangeDpiFormat,
    required void Function() onTapOutside,
    // required void Function() onCaculateFileSize,
  }) {
    RenderBox renderBox = key.currentContext?.findRenderObject() as RenderBox;

    Offset offset = renderBox.localToGlobal(const Offset(0, 0)).translate(
          -328 + renderBox.size.width,
          -172 - (renderBox.size.height - 10),
        );

    showCustomDialogWithOffset(
      context: context,
      newScreen: BodyDialogCustom(
        offset: offset,
        dialogWidget: WExportDpiDialog(
          currentDpiResolution: currentDpiResolution,
          currentIndexDpiFormat: currentIndexDpiFormat,
          onChangeDpiResolution: onChangeDpiResolution,
          onChangeDpiFormat: onChangeDpiFormat,
          onChangeDPIResolutionEnd: onChangeDPIResolutionEnd,
          // onCaculateFileSize: onCaculateFileSize,
          dataSegmentResolution: dataSegmentResolution,
          listMinMaxDpi: listMinMaxDpi,
          indexSegmentMain: indexSegmentMain,
          indexImageFormat: indexImageFormat,
        ),
        scaleAlignment: Alignment.bottomRight,
        onTapBackground: () {
          onTapOutside();
          popNavigator(context);
        },
      ),
    );
  }

  static void showDialogCustomSize(
    BuildContext context,
    ExportSizeModel exportSizeModel,
    void Function() onCancelFocus,
    void Function(double width, double height) onComplete,
  ) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return WBodyDialogCustomSize(
          exportSizeModel: exportSizeModel,
          onComplete: (width, height) {
            onComplete(width, height);
          },
        );
      },
      barrierDismissible: true,
    ).whenComplete(() {
      onCancelFocus();
    });
  }

  bool checkOverFlowSize(
    Size screenSize,
    PassportModel currentPassport,
    // double valueResolution,
  ) {
    double widthConverted = FlutterConvert.convertUnit(
        currentPassport.unit, INCH, currentPassport.width);
    double heightConverted = FlutterConvert.convertUnit(
        currentPassport.unit, INCH, currentPassport.height);

    Size expandedSize = Size(widthConverted, heightConverted);

    // Size(
    //   widthConverted * valueResolution,
    //   heightConverted * valueResolution,
    // );
    double maxDimension = max(expandedSize.width, expandedSize.height);
    consolelog("maxDimension ${screenSize}");
    if (screenSize.width > MIN_SIZE.width) {
      if (maxDimension >= MAX_SIZE_EXPORT_IMAGE_NORMAL) {
        return true;
      } else {
        return false;
      }
    } else {
      if (maxDimension >= MAX_SIZE_EXPORT_IMAGE_WEAK) {
        return true;
      } else {
        return false;
      }
    }
  }

  void showWarningExport(BuildContext context) {
    showCustomAboutDialog(
      context,
      360,
      "Image too large",
      "Unable to export this image.",
      titleColor: red,
    );
  }
}
