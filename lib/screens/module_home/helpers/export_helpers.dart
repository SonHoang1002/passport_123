import 'dart:math';

import 'package:flutter_gpu_filters_interface/flutter_gpu_filters_interface.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/commons/extension.dart';
import 'package:pass1_/helpers/convert.dart';
import 'package:pass1_/helpers/fill_image_on_pdf.dart';
import 'package:pass1_/widgets/w_custom_about_dialog.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pass1_/a_test/pdf_function/generate_pdf_helpers.dart';
import 'package:pass1_/models/project_model.dart';
import 'package:pdf/pdf.dart';
import 'package:flutter/cupertino.dart';
import 'package:pass1_/a_test/w_dialog_title_body.dart';
import 'package:pass1_/a_test/w_export_childs.dart';
import 'package:pass1_/helpers/caculate_file_size.dart';
import 'package:pass1_/helpers/log_custom.dart';
import 'package:pass1_/helpers/native_bridge/method_channel.dart';
import 'package:pass1_/helpers/navigator_route.dart';
import 'package:pass1_/models/country_passport_model.dart';
import 'package:pass1_/models/export_size_model.dart';
import 'package:pass1_/screens/module_home/widgets/childs/w_export_compression_dialog.dart';
import 'package:pass1_/screens/module_home/widgets/childs/w_export_dpi_dialog.dart';
import 'package:pass1_/widgets/general_dialog/w_body_dialogs.dart';
import 'package:pass1_/widgets/general_dialog/w_general_dialog.dart';
import 'package:path_provider/path_provider.dart';

class ExportHelpers {
  /// Sử dụng để tính toán danh sách file cache ( có thể là file ảnh hoặc pdf, tuỳ vào format mà user muốn )
  ///
  static Future<List<File>> handleGenerateMultiplePaperMedia({
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
    /// Từ kích thuơc của passport -> đổi sang pixel cùng với dpi -> tạo ảnh với kíc thước này
    ///

    switch (indexImageFormat) {
      case 0: // JPG
      case 1: // PNG
        // Lấy extension để gen
        final String extension = EXPORT_SEGMENT_COMPRESSION_IMAGE_FORMAT.values
            .toList()[indexImageFormat]
            .toLowerCase();

        /// Nếu là png format -> lấy luôn ảnh đã crop để vẽ
        /// Nếu là jpg format -> chỉnh quality trc khi đưa vào draw
        File? resizedFile;
        if (indexImageFormat == 0) {
          final dirPath = (await getExternalStorageDirectory())!.path;
          String outPath = "$dirPath/$FINISH_IMAGE_NAME.$extension";

          resizedFile = await MyMethodChannel.resizeAndResoluteImage(
            inputPath: projectModel.croppedFile!.path,
            format: indexImageFormat,
            // listWH: [passportWidthByPixelLimited, passportHeightByPixelLimited],
            // scaleWH: [1, 1],
            outPath: outPath,
            quality: quality,
          );
        } else {
          resizedFile = projectModel.croppedFile!;
        }

        Uint8List bytes = await resizedFile!.readAsBytes();
        final Completer<ui.Image> completer = Completer();
        ui.decodeImageFromList(bytes, (ui.Image img) {
          completer.complete(img);
        });
        ui.Image imageData = await completer.future;

        consolelog(
          "imageDataimageData size: = ${imageData.width}, ${imageData.height}",
        );
        var drawResult = await GeneratePdfHelpers().drawPdfImageV1(
          projectModel,
          exportSize,
          copyNumber,
          valueResolutionDpi,
          imageData,
        );

        List<ui.Image> listPdfImages = drawResult["listUiPdfImage"];
        Stopwatch stopwatch = Stopwatch();
        stopwatch.start();
        List<File> listMainFile = [];

        // Trường hợp
        // số lượng ảnh lớn hơn 2 -> Lấy ra 2 ảnh duy nhất : ảnh đầu tiên và ảnh cuối cùng , vì những ảnh ở giữa đều giống ảnh 1
        // con truong hop images.length == copynumber -> gen 1 anh duy nhat

        if (listPdfImages.length > 2) {
          List<File> listTempFile = [];
          List<ui.Image> collapseList = [
            listPdfImages.first,
            listPdfImages.last,
          ];
          for (var i = 0; i < collapseList.length; i++) {
            var item = collapseList[i];
            Uint8List? bytes = (await item.toByteData(
              format: ui.ImageByteFormat.png,
            ))?.buffer.asUint8List();

            final directory = await getExternalStorageDirectory();
            final String path =
                '${directory!.path}/generated_pdf_image_$i.$extension';

            File file = File(path);
            await file.writeAsBytes(bytes!);
            listTempFile.add(file);
          }
          for (var i = 0; i < listPdfImages.length; i++) {
            if (i < listPdfImages.length - 1) {
              listMainFile.add(listTempFile[0]);
            } else {
              listMainFile.add(listTempFile[1]);
            }
          }
        } else {
          for (var i = 0; i < listPdfImages.length; i++) {
            var item = listPdfImages[i];
            Uint8List? bytes = (await item.toByteData(
              format: ui.ImageByteFormat.png,
            ))?.buffer.asUint8List();
            final directory = await getExternalStorageDirectory();

            final String path =
                '${directory!.path}/generated_pdf_image_$i.$extension';
            File file = File(path);
            await file.writeAsBytes(bytes!);
            listMainFile.add(file);
          }
        }
        stopwatch.stop();
        consolelog("stopwatch abc listMainFile ${listMainFile.length}");
        return listMainFile;
      case 2:
        consolelog("exportSize: $exportSize");
        List<File> listMainFile = [];
        // (ui.Image, Uint8List) imageData = await _loadImageDataForPdfFormat(
        //   projectModel,
        //   indexImageFormat,
        //   countrySelected,
        //   screenSize,
        //   valueResolutionDpi,
        //   listPassportDimensionByInch,
        //   quality,
        // );

        Map<String, dynamic> drawResult = GeneratePdfHelpers()
            .caculateDimensionsInPrintPointForPdf(
              projectModel,
              exportSize,
              copyNumber,
              // imageData.$1,
              valueResolutionDpi,
            );
        Size paperSizeByPoint = drawResult["paperSizeByPoint"];
        Size passportSizeByPoint = drawResult["passportSizeByPoint"];
        double spacingHorizontalByPoint =
            drawResult["spacingHorizontalByPoint"];
        double spacingVerticalByPoint = drawResult["spacingVerticalByPoint"];
        EdgeInsets marginByPoint = drawResult["marginByPoint"];

        File result = await GeneratePdfHelpers().generatePaperPdf(
          projectModel,
          paperSizeByPoint,
          passportSizeByPoint,
          copyNumber,
          valueResolutionDpi,
          [spacingHorizontalByPoint, spacingVerticalByPoint],
          marginByPoint,
          quality,
        );

        listMainFile = [result];

        return listMainFile;
      default:
        return [];
    }
  }

  /// Sử dụng native để tính toán như hàm [handleGenerateMultiplePaperMedia], nhưng truyền data cho native xử lý
  static Future<List<File>> handleGenerateMultiplePaperMediaV1({
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
    /// Từ kích thuơc của passport -> đổi sang pixel cùng với dpi -> tạo ảnh với kíc thước này
    ///

    switch (indexImageFormat) {
      case 0: // JPG
      case 1: // PNG
        final String extension = EXPORT_SEGMENT_COMPRESSION_IMAGE_FORMAT.values
            .toList()[indexImageFormat]
            .toLowerCase();
        double paperWidthByPixelPoint =
            FlutterConvert.convertUnit(
              exportSize.unit,
              INCH,
              exportSize.size.width,
            ) *
            valueResolutionDpi;

        double paperHeightByPixelPoint =
            FlutterConvert.convertUnit(
              exportSize.unit,
              INCH,
              exportSize.size.height,
            ) *
            valueResolutionDpi;

        double paperWidthByPixelPointLimited;
        double paperHeightByPixelPointLimited;

        if (max(paperWidthByPixelPoint, paperHeightByPixelPoint) >
            LIMITATION_DIMENSION_BY_PIXEl) {
          double aspectRatio = paperWidthByPixelPoint / paperHeightByPixelPoint;

          if (aspectRatio > 1) {
            paperWidthByPixelPointLimited = LIMITATION_DIMENSION_BY_PIXEl;
            paperHeightByPixelPointLimited =
                paperWidthByPixelPointLimited / aspectRatio;
          } else if (aspectRatio < 1) {
            paperHeightByPixelPointLimited = LIMITATION_DIMENSION_BY_PIXEl;
            paperWidthByPixelPointLimited =
                paperHeightByPixelPointLimited * aspectRatio;
          } else {
            paperWidthByPixelPointLimited = paperHeightByPixelPointLimited =
                LIMITATION_DIMENSION_BY_PIXEl;
          }
        } else {
          paperWidthByPixelPointLimited = paperWidthByPixelPoint;
          paperHeightByPixelPointLimited = paperHeightByPixelPoint;
        }

        Size paperSizeByPixelPointLimited = Size(
          paperWidthByPixelPointLimited,
          paperHeightByPixelPoint,
        );

        EdgeInsets marginByExportUnit = exportSize.marginModel
            .toEdgeInsetsByCurrentUnit();

        double marginLeftByPixelPoint;
        double marginTopByPixelPoint;
        double marginRightByPixelPoint;
        double marginBottomByPixelPoint;

        double spacingHorizontalByPixelPoint, spacingVerticalByPixelPoint;
        var exportUnit = exportSize.unit;
        if (exportUnit == PIXEL) {
          marginLeftByPixelPoint = exportSize.marginModel.mLeft;
          marginTopByPixelPoint = exportSize.marginModel.mTop;
          marginRightByPixelPoint = exportSize.marginModel.mRight;
          marginBottomByPixelPoint = exportSize.marginModel.mBottom;

          spacingHorizontalByPixelPoint = exportSize.spacingHorizontal;
          spacingVerticalByPixelPoint = exportSize.spacingVertical;
        } else {
          marginLeftByPixelPoint =
              FlutterConvert.convertUnit(
                exportUnit,
                INCH,
                marginByExportUnit.left,
              ) *
              valueResolutionDpi;
          marginTopByPixelPoint =
              FlutterConvert.convertUnit(
                exportUnit,
                INCH,
                marginByExportUnit.top,
              ) *
              valueResolutionDpi;
          marginRightByPixelPoint =
              FlutterConvert.convertUnit(
                exportUnit,
                INCH,
                marginByExportUnit.right,
              ) *
              valueResolutionDpi;
          marginBottomByPixelPoint =
              FlutterConvert.convertUnit(
                exportUnit,
                INCH,
                marginByExportUnit.bottom,
              ) *
              valueResolutionDpi;
          spacingHorizontalByPixelPoint =
              FlutterConvert.convertUnit(
                exportUnit,
                INCH,
                exportSize.spacingHorizontal,
              ) *
              valueResolutionDpi;
          spacingVerticalByPixelPoint =
              FlutterConvert.convertUnit(
                exportUnit,
                INCH,
                exportSize.spacingVertical,
              ) *
              valueResolutionDpi;
        }

        var marginByPixelPoint = EdgeInsets.fromLTRB(
          marginLeftByPixelPoint,
          marginTopByPixelPoint,
          marginRightByPixelPoint,
          marginBottomByPixelPoint,
        );

        PassportModel? currentPassport =
            projectModel.countryModel?.currentPassport;
        if (currentPassport == null) {
          throw Exception("Current Passport khong the null");
        }
        double passportWidthByPixelPoint;
        double passportHeightByPixelPoint;
        var currentPassportUnit = currentPassport.unit;
        if (currentPassportUnit == PIXEL) {
          passportWidthByPixelPoint = currentPassport.width;
          passportHeightByPixelPoint = currentPassport.height;
        } else {
          passportWidthByPixelPoint =
              FlutterConvert.convertUnit(
                currentPassportUnit,
                INCH,
                currentPassport.width,
              ) *
              valueResolutionDpi;
          passportHeightByPixelPoint =
              FlutterConvert.convertUnit(
                currentPassportUnit,
                INCH,
                currentPassport.height,
              ) *
              valueResolutionDpi;
        }

        Size passportSizeByPixelPoint = Size(
          passportWidthByPixelPoint,
          passportHeightByPixelPoint,
        );

        // giới hạn kích thước passportWidthByPixel ảnh
        Size aroundAvailableSizeByPixelPoint = paperSizeByPixelPointLimited
            .copyWith(
              width:
                  paperSizeByPixelPointLimited.width -
                  marginByPixelPoint.left -
                  marginByPixelPoint.right,
              height:
                  paperSizeByPixelPointLimited.height -
                  marginByPixelPoint.top -
                  marginByPixelPoint.bottom,
            );

        Size passportSizeByPixelLimited = getLimitImageInPaper(
          aroundAvailableSizeByPixelPoint,
          passportSizeByPixelPoint,
          isKeepSizeWhenSmall: true,
        );

        int countColumnIn1Page = max(
          1,
          (aroundAvailableSizeByPixelPoint.width) ~/
              passportSizeByPixelLimited.width,
        );

        int countRowIn1Page = max(
          1,
          (aroundAvailableSizeByPixelPoint.height) ~/
              passportSizeByPixelLimited.height,
        );

        int countImageOn1Page = countRowIn1Page * countColumnIn1Page;

        int countPage = (copyNumber / countImageOn1Page).ceil();

        final result =
            await MyMethodChannel.handleGenerateMultiplePaperMediaToImage(
              imageCroppedPath: projectModel.croppedFile!.path,
              indexImageFormat: indexImageFormat,
              extension: extension,
              quality: quality,
              copyNumber: copyNumber,
              countPage: countPage,
              paperSizeByPixelPointLimited: paperSizeByPixelPointLimited,
              passportSizeByPixelLimited: passportSizeByPixelLimited,
              countColumnIn1Page: countColumnIn1Page,
              countRowIn1Page: countRowIn1Page,
              spacingHorizontalByPixelPoint: spacingHorizontalByPixelPoint,
              spacingVerticalByPixelPoint: spacingVerticalByPixelPoint,
              marginByPixelPoint: marginByPixelPoint,
            );
        consolelog("resultresultresult: $result");
        return result.$1.map((item) => File(item)).toList();
      case 2:
        consolelog("exportSize: $exportSize");
        List<File> listMainFile = [];

        Map<String, dynamic> drawResult = GeneratePdfHelpers()
            .caculateDimensionsInPrintPointForPdf(
              projectModel,
              exportSize,
              copyNumber,
              // imageData.$1,
              valueResolutionDpi,
            );
        Size paperSizeByPoint = drawResult["paperSizeByPoint"];
        Size passportSizeByPoint = drawResult["passportSizeByPoint"];
        double spacingHorizontalByPoint =
            drawResult["spacingHorizontalByPoint"];
        double spacingVerticalByPoint = drawResult["spacingVerticalByPoint"];
        EdgeInsets marginByPoint = drawResult["marginByPoint"];

        File result = await GeneratePdfHelpers().generatePaperPdf(
          projectModel,
          paperSizeByPoint,
          passportSizeByPoint,
          copyNumber,
          valueResolutionDpi,
          [spacingHorizontalByPoint, spacingVerticalByPoint],
          marginByPoint,
          quality,
        );

        listMainFile = [result];

        return listMainFile;
      default:
        return [];
    }
  }

  // in ra theo kích cỡ của passport
  // trong đó ảnh sẽ được resize theo dpi
  /// Trả ra (
  ///   outputFile ,
  ///   fileSizeToKB
  /// );
  static Future<(File, double)> handleGenerateSinglePhotoMedia({
    required int indexImageFormat,
    required File imageCropped,
    required CountryModel countrySelected,
    // required Size screenSize,
    required double valueResolutionDpi,
    // required List<double> listPassportDimensionByInch,
    required int quality,
  }) async {
    double dpi = valueResolutionDpi;
    (File, double) result;
    try {
      /// Kiểm tra xem đang dùng for
      bool idPdfFormat =
          indexImageFormat ==
          EXPORT_SEGMENT_COMPRESSION_IMAGE_FORMAT.length - 1;
      final dirPath = (await getExternalStorageDirectory())!.path;
      PassportModel currentPassport = countrySelected.currentPassport;
      if (idPdfFormat) {
        String extension = JPG.toLowerCase();
        String outImagePath = "$dirPath/$FINISH_IMAGE_NAME.$extension";

        double passportWidthByPixelPoint, passportHeightByPixelPoint;
        if (currentPassport.unit == PIXEL) {
          passportWidthByPixelPoint = currentPassport.width;
          passportHeightByPixelPoint = currentPassport.height;
        } else {
          passportWidthByPixelPoint =
              FlutterConvert.convertUnit(
                currentPassport.unit,
                INCH,
                currentPassport.width,
              ) *
              dpi;
          passportHeightByPixelPoint =
              FlutterConvert.convertUnit(
                currentPassport.unit,
                INCH,
                currentPassport.height,
              ) *
              dpi;
        }
        double passportWidthByPixelPointLimited = passportWidthByPixelPoint;
        double passportHeightByPixelPointLimited = passportHeightByPixelPoint;
        if (max(passportWidthByPixelPoint, passportHeightByPixelPoint) >
            LIMITATION_DIMENSION_BY_PIXEl) {
          double aspectRatio =
              passportWidthByPixelPoint / passportHeightByPixelPoint;
          if (aspectRatio > 1) {
            passportWidthByPixelPointLimited = LIMITATION_DIMENSION_BY_PIXEl;
            passportHeightByPixelPointLimited =
                passportWidthByPixelPointLimited / aspectRatio;
          } else if (aspectRatio < 1) {
            passportHeightByPixelPointLimited = LIMITATION_DIMENSION_BY_PIXEl;
            passportWidthByPixelPointLimited =
                passportHeightByPixelPointLimited * aspectRatio;
          } else {
            passportWidthByPixelPointLimited =
                passportHeightByPixelPointLimited =
                    LIMITATION_DIMENSION_BY_PIXEl;
          }
        }

        consolelog(
          "111 passportWidthByPixelPoint: $passportWidthByPixelPoint, passportHeightByPixelPoint = $passportHeightByPixelPoint, passportWidthByPixelPointLimited = $passportWidthByPixelPointLimited,  passportHeightByPixelPointLimited = $passportHeightByPixelPointLimited",
        );

        File? resizedFile = await MyMethodChannel.resizeAndResoluteImage(
          inputPath: imageCropped.path,
          format: 0, // JPG format
          listWH: [
            passportWidthByPixelPointLimited,
            passportHeightByPixelPointLimited,
          ],
          scaleWH: [1, 1],
          outPath: outImagePath,
          quality: quality,
        );
        File? pdfFile;
        if (resizedFile != null) {
          double scaleWidth, scaleHeight;
          if (currentPassport.unit == PIXEL) {
            double passportWidthByPixel, passportHeightByPixel;
            if ((max(currentPassport.width, currentPassport.height)) >
                LIMITATION_DIMENSION_BY_PIXEl) {
              double aspectRatio = currentPassport.size.aspectRatio;
              if (aspectRatio > 1) {
                passportWidthByPixel = LIMITATION_DIMENSION_BY_PIXEl;
                passportHeightByPixel = passportWidthByPixel / aspectRatio;
              } else if (aspectRatio < 1) {
                passportHeightByPixel = LIMITATION_DIMENSION_BY_PIXEl;
                passportWidthByPixel = passportHeightByPixel * aspectRatio;
              } else {
                passportWidthByPixel = passportHeightByPixel =
                    LIMITATION_DIMENSION_BY_PIXEl;
              }
              scaleWidth = passportWidthByPixel / currentPassport.width;
              scaleHeight = passportHeightByPixel / currentPassport.height;
            } else {
              scaleWidth = 1.0;
              scaleHeight = 1.0;
            }
          } else {
            /// đổi đưn vị sang điểm vẽ
            double passportWidthConvertedByPixel =
                FlutterConvert.convertUnit(
                  currentPassport.unit,
                  INCH,
                  currentPassport.width,
                ) *
                dpi;
            double passportHeightConvertedByPixel =
                FlutterConvert.convertUnit(
                  currentPassport.unit,
                  INCH,
                  currentPassport.height,
                ) *
                dpi;

            if ((max(
                  passportWidthConvertedByPixel,
                  passportHeightConvertedByPixel,
                )) >
                LIMITATION_DIMENSION_BY_PIXEl) {
              double aspectRatio =
                  passportWidthConvertedByPixel /
                  passportHeightConvertedByPixel;
              double newPassportWidthConvertedByPixel,
                  newPassportHeightConvertedByPixel;
              if (aspectRatio > 1) {
                newPassportWidthConvertedByPixel =
                    LIMITATION_DIMENSION_BY_PIXEl;
                newPassportHeightConvertedByPixel =
                    newPassportWidthConvertedByPixel / aspectRatio;
              } else if (aspectRatio < 1) {
                newPassportHeightConvertedByPixel =
                    LIMITATION_DIMENSION_BY_PIXEl;
                newPassportWidthConvertedByPixel =
                    newPassportHeightConvertedByPixel * aspectRatio;
              } else {
                newPassportWidthConvertedByPixel =
                    newPassportHeightConvertedByPixel =
                        LIMITATION_DIMENSION_BY_PIXEl;
              }
              scaleWidth =
                  newPassportWidthConvertedByPixel /
                  passportWidthConvertedByPixel;
              scaleHeight =
                  newPassportHeightConvertedByPixel /
                  passportHeightConvertedByPixel;
            } else {
              scaleWidth = 1.0;
              scaleHeight = 1.0;
            }
          }
          double passportWidthByPrintPointLimited,
              passportHeightByPrintPointLimited;
          if (currentPassport.unit == PIXEL) {
            passportWidthByPrintPointLimited =
                currentPassport.width * scaleWidth / valueResolutionDpi * 72;
            passportHeightByPrintPointLimited =
                currentPassport.height * scaleHeight / valueResolutionDpi * 72;
          } else {
            passportWidthByPrintPointLimited = FlutterConvert.convertUnit(
              currentPassport.unit,
              POINT,
              currentPassport.width * scaleWidth,
            );
            passportHeightByPrintPointLimited = FlutterConvert.convertUnit(
              currentPassport.unit,
              POINT,
              currentPassport.height * scaleHeight,
            );
          }

          Size passportSizeByPrintPoint = Size(
            passportWidthByPrintPointLimited,
            passportHeightByPrintPointLimited,
          );
          consolelog(
            " 123123 passportSizeByPrintPoint = $passportSizeByPrintPoint, scaleWidth = $scaleWidth, scaleHeight = $scaleHeight",
          );
          pdfFile = await GeneratePdfHelpers().generateSingleImagePdf(
            passportSizeByPrintPoint,
            [resizedFile],
          );
          double fileSize = await getFileSize(pdfFile);
          result = (pdfFile, fileSize);

          consolelog(
            "single pdf: image data length: ${resizedFile.readAsBytesSync().length} - pdf data length: ${pdfFile!.readAsBytesSync().length}",
          );
        } else {
          throw Exception(
            "handleGenerateSinglePhotoMedia error: resizedFile is null, check result of resizeAndResoluteImage function",
          );
        }
      } else {
        final dirPath = (await getExternalStorageDirectory())!.path;
        String extension = LIST_FORMAT_IMAGE[indexImageFormat]
            .toLowerCase(); // JPG or PNG
        String outImagePath = "$dirPath/$FINISH_IMAGE_NAME.$extension";

        double passportWidthByPixelPoint, passportHeightByPixelPoint;

        if (currentPassport.unit == PIXEL) {
          passportWidthByPixelPoint = currentPassport.width;
          passportHeightByPixelPoint = currentPassport.height;
        } else {
          passportWidthByPixelPoint =
              FlutterConvert.convertUnit(
                currentPassport.unit,
                INCH,
                currentPassport.width,
              ) *
              dpi;
          passportHeightByPixelPoint =
              FlutterConvert.convertUnit(
                currentPassport.unit,
                INCH,
                currentPassport.height,
              ) *
              dpi;
        }

        /// Limit
        double passportWidthByPixelPointLimited = passportWidthByPixelPoint;
        double passportHeightByPixelPointLimited = passportHeightByPixelPoint;
        if (max(passportWidthByPixelPoint, passportHeightByPixelPoint) >
            LIMITATION_DIMENSION_BY_PIXEl) {
          double aspectRatio =
              passportWidthByPixelPoint / passportHeightByPixelPoint;
          if (aspectRatio > 1) {
            passportWidthByPixelPointLimited = LIMITATION_DIMENSION_BY_PIXEl;
            passportHeightByPixelPointLimited =
                passportWidthByPixelPointLimited / aspectRatio;
          } else if (aspectRatio < 1) {
            passportHeightByPixelPointLimited = LIMITATION_DIMENSION_BY_PIXEl;
            passportWidthByPixelPointLimited =
                passportHeightByPixelPointLimited * aspectRatio;
          } else {
            passportWidthByPixelPointLimited =
                passportHeightByPixelPointLimited =
                    LIMITATION_DIMENSION_BY_PIXEl;
          }
        }
        consolelog(
          "passportWidthByPixelPoint: $passportWidthByPixelPoint, passportHeightByPixelPoint = $passportHeightByPixelPoint, passportWidthByPixelPointLimited = $passportWidthByPixelPointLimited,  passportHeightByPixelPointLimited = $passportHeightByPixelPointLimited",
        );
        File? resizedFile = await MyMethodChannel.resizeAndResoluteImage(
          inputPath: imageCropped.path,
          format: indexImageFormat,
          listWH: [
            passportWidthByPixelPointLimited,
            passportHeightByPixelPointLimited,
          ],
          scaleWH: [1, 1],
          outPath: outImagePath,
          quality: quality,
        );
        if (resizedFile != null) {
          double fileSize = await getFileSize(resizedFile);
          result = (resizedFile, fileSize);
        } else {
          throw Exception(
            "handleGenerateSinglePhotoMedia error: resizedFile is null, check result of resizeAndResoluteImage function",
          );
        }
      }
    } catch (e) {
      consolelog("handleGenerateSinglePhotoMedia error: $e");
      rethrow;
    }
    return result;
  }

  // in ra theo kích cỡ của passport
  // trong đó ảnh sẽ được resize theo dpi
  /// Trả ra (
  ///    outputFile,
  ///    fileSize,
  /// );
  static Future<(File, double)> handleGenerateSinglePhotoMediaV1({
    required int indexImageFormat,
    required File imageCropped,
    required CountryModel countrySelected,
    required double valueResolutionDpi,
    required int quality,
  }) async {
    double dpi = valueResolutionDpi;
    (File, double) result;
    try {
      bool idPdfFormat =
          indexImageFormat ==
          EXPORT_SEGMENT_COMPRESSION_IMAGE_FORMAT.length - 1;
      final dirPath = (await getExternalStorageDirectory())!.path;
      PassportModel currentPassport = countrySelected.currentPassport;
      if (idPdfFormat) {
        String extension = JPG.toLowerCase();
        String outImagePath = "$dirPath/$FINISH_IMAGE_NAME.$extension";

        double passportWidthByPixelPoint, passportHeightByPixelPoint;
        if (currentPassport.unit == PIXEL) {
          passportWidthByPixelPoint = currentPassport.width;
          passportHeightByPixelPoint = currentPassport.height;
        } else {
          passportWidthByPixelPoint =
              FlutterConvert.convertUnit(
                currentPassport.unit,
                INCH,
                currentPassport.width,
              ) *
              dpi;
          passportHeightByPixelPoint =
              FlutterConvert.convertUnit(
                currentPassport.unit,
                INCH,
                currentPassport.height,
              ) *
              dpi;
        }
        double passportWidthByPixelPointLimited = passportWidthByPixelPoint;
        double passportHeightByPixelPointLimited = passportHeightByPixelPoint;
        if (max(passportWidthByPixelPoint, passportHeightByPixelPoint) >
            LIMITATION_DIMENSION_BY_PIXEl) {
          double aspectRatio =
              passportWidthByPixelPoint / passportHeightByPixelPoint;
          if (aspectRatio > 1) {
            passportWidthByPixelPointLimited = LIMITATION_DIMENSION_BY_PIXEl;
            passportHeightByPixelPointLimited =
                passportWidthByPixelPointLimited / aspectRatio;
          } else if (aspectRatio < 1) {
            passportHeightByPixelPointLimited = LIMITATION_DIMENSION_BY_PIXEl;
            passportWidthByPixelPointLimited =
                passportHeightByPixelPointLimited * aspectRatio;
          } else {
            passportWidthByPixelPointLimited =
                passportHeightByPixelPointLimited =
                    LIMITATION_DIMENSION_BY_PIXEl;
          }
        }
        File? resizedFile = await MyMethodChannel.resizeAndResoluteImage(
          inputPath: imageCropped.path,
          format: 0, // JPG format
          listWH: [
            passportWidthByPixelPointLimited,
            passportHeightByPixelPointLimited,
          ],
          scaleWH: [1, 1],
          outPath: outImagePath,
          quality: quality,
        );
        File? pdfFile;
        if (resizedFile != null) {
          double scaleWidth, scaleHeight;
          if (currentPassport.unit == PIXEL) {
            double passportWidthByPixel, passportHeightByPixel;
            if ((max(currentPassport.width, currentPassport.height)) >
                LIMITATION_DIMENSION_BY_PIXEl) {
              double aspectRatio = currentPassport.size.aspectRatio;
              if (aspectRatio > 1) {
                passportWidthByPixel = LIMITATION_DIMENSION_BY_PIXEl;
                passportHeightByPixel = passportWidthByPixel / aspectRatio;
              } else if (aspectRatio < 1) {
                passportHeightByPixel = LIMITATION_DIMENSION_BY_PIXEl;
                passportWidthByPixel = passportHeightByPixel * aspectRatio;
              } else {
                passportWidthByPixel = passportHeightByPixel =
                    LIMITATION_DIMENSION_BY_PIXEl;
              }
              scaleWidth = passportWidthByPixel / currentPassport.width;
              scaleHeight = passportHeightByPixel / currentPassport.height;
            } else {
              scaleWidth = 1.0;
              scaleHeight = 1.0;
            }
          } else {
            /// đổi đưn vị sang điểm vẽ
            double passportWidthConvertedByPixel =
                FlutterConvert.convertUnit(
                  currentPassport.unit,
                  INCH,
                  currentPassport.width,
                ) *
                dpi;
            double passportHeightConvertedByPixel =
                FlutterConvert.convertUnit(
                  currentPassport.unit,
                  INCH,
                  currentPassport.height,
                ) *
                dpi;

            if ((max(
                  passportWidthConvertedByPixel,
                  passportHeightConvertedByPixel,
                )) >
                LIMITATION_DIMENSION_BY_PIXEl) {
              double aspectRatio =
                  passportWidthConvertedByPixel /
                  passportHeightConvertedByPixel;
              double newPassportWidthConvertedByPixel,
                  newPassportHeightConvertedByPixel;
              if (aspectRatio > 1) {
                newPassportWidthConvertedByPixel =
                    LIMITATION_DIMENSION_BY_PIXEl;
                newPassportHeightConvertedByPixel =
                    newPassportWidthConvertedByPixel / aspectRatio;
              } else if (aspectRatio < 1) {
                newPassportHeightConvertedByPixel =
                    LIMITATION_DIMENSION_BY_PIXEl;
                newPassportWidthConvertedByPixel =
                    newPassportHeightConvertedByPixel * aspectRatio;
              } else {
                newPassportWidthConvertedByPixel =
                    newPassportHeightConvertedByPixel =
                        LIMITATION_DIMENSION_BY_PIXEl;
              }
              scaleWidth =
                  newPassportWidthConvertedByPixel /
                  passportWidthConvertedByPixel;
              scaleHeight =
                  newPassportHeightConvertedByPixel /
                  passportHeightConvertedByPixel;
            } else {
              scaleWidth = 1.0;
              scaleHeight = 1.0;
            }
          }
          double passportWidthByPrintPointLimited,
              passportHeightByPrintPointLimited;
          if (currentPassport.unit == PIXEL) {
            passportWidthByPrintPointLimited =
                currentPassport.width * scaleWidth / valueResolutionDpi * 72;
            passportHeightByPrintPointLimited =
                currentPassport.height * scaleHeight / valueResolutionDpi * 72;
          } else {
            passportWidthByPrintPointLimited = FlutterConvert.convertUnit(
              currentPassport.unit,
              POINT,
              currentPassport.width * scaleWidth,
            );
            passportHeightByPrintPointLimited = FlutterConvert.convertUnit(
              currentPassport.unit,
              POINT,
              currentPassport.height * scaleHeight,
            );
          }

          Size passportSizeByPrintPoint = Size(
            passportWidthByPrintPointLimited,
            passportHeightByPrintPointLimited,
          );
          consolelog(
            " 123123 passportSizeByPrintPoint = $passportSizeByPrintPoint, scaleWidth = $scaleWidth, scaleHeight = $scaleHeight",
          );

          var path = (await getExternalStorageDirectory())!.path;
          String pdfOutPath = "$path/passport_gen_1.pdf";

          final resultFromNative = await MyMethodChannel.generateSingleImagePdf(
            passportSizeByPrintPoint: passportSizeByPrintPoint,
            pdfOutPath: pdfOutPath,
            listFilePath: [resizedFile.path],
          );

          File outputFile = File(resultFromNative.$1);
          double fileSizeInKB = resultFromNative.$2 / MB_TO_KB;
          result = (outputFile, fileSizeInKB);
        } else {
          throw Exception(
            "handleGenerateSinglePhotoMedia error: resizedFile is null, check result of resizeAndResoluteImage function",
          );
        }
      } else {
        final dirPath = (await getExternalStorageDirectory())!.path;
        String extension = LIST_FORMAT_IMAGE[indexImageFormat]
            .toLowerCase(); // JPG or PNG
        String outImagePath = "$dirPath/$FINISH_IMAGE_NAME.$extension";

        double passportWidthByPixelPoint, passportHeightByPixelPoint;

        if (currentPassport.unit == PIXEL) {
          passportWidthByPixelPoint = currentPassport.width;
          passportHeightByPixelPoint = currentPassport.height;
        } else {
          passportWidthByPixelPoint =
              FlutterConvert.convertUnit(
                currentPassport.unit,
                INCH,
                currentPassport.width,
              ) *
              dpi;
          passportHeightByPixelPoint =
              FlutterConvert.convertUnit(
                currentPassport.unit,
                INCH,
                currentPassport.height,
              ) *
              dpi;
        }

        /// Limit
        double passportWidthByPixelPointLimited = passportWidthByPixelPoint;
        double passportHeightByPixelPointLimited = passportHeightByPixelPoint;
        if (max(passportWidthByPixelPoint, passportHeightByPixelPoint) >
            LIMITATION_DIMENSION_BY_PIXEl) {
          double aspectRatio =
              passportWidthByPixelPoint / passportHeightByPixelPoint;
          if (aspectRatio > 1) {
            passportWidthByPixelPointLimited = LIMITATION_DIMENSION_BY_PIXEl;
            passportHeightByPixelPointLimited =
                passportWidthByPixelPointLimited / aspectRatio;
          } else if (aspectRatio < 1) {
            passportHeightByPixelPointLimited = LIMITATION_DIMENSION_BY_PIXEl;
            passportWidthByPixelPointLimited =
                passportHeightByPixelPointLimited * aspectRatio;
          } else {
            passportWidthByPixelPointLimited =
                passportHeightByPixelPointLimited =
                    LIMITATION_DIMENSION_BY_PIXEl;
          }
        }
        consolelog(
          "passportWidthByPixelPoint: $passportWidthByPixelPoint, passportHeightByPixelPoint = $passportHeightByPixelPoint, passportWidthByPixelPointLimited = $passportWidthByPixelPointLimited,  passportHeightByPixelPointLimited = $passportHeightByPixelPointLimited",
        );
        (String, double) resultFromNative =
            await MyMethodChannel.handleGenerateSinglePhotoMediaToImage(
              imageCroppedPath: imageCropped.path,
              indexImageFormat: indexImageFormat,
              passportWidthByPixelPointLimited:
                  passportWidthByPixelPointLimited,
              passportHeightByPixelPointLimited:
                  passportHeightByPixelPointLimited,
              outPath: outImagePath,
              quality: quality,
            );
        result = (File(resultFromNative.$1), resultFromNative.$2 / MB_TO_KB);
      }
    } catch (e) {
      consolelog("handleGenerateSinglePhotoMedia error: $e");
      rethrow;
    }
    return result;
  }

  static Future<File?> _resizeImage(
    File imageCropped,
    int indexImageFormat,
    CountryModel countrySelected,
    Size size,
    double dpi,
    List<double> listPassportDimensionByInch,
    int quality,
  ) async {
    final dirPath = (await getExternalStorageDirectory())!.path;
    String extension = LIST_FORMAT_IMAGE[indexImageFormat]
        .toLowerCase(); // JPG format
    String outPath = "$dirPath/$FINISH_IMAGE_NAME.$extension";

    var currentPassport = countrySelected.currentPassport;
    double passportWidthByPixel, passportHeightByPixel;

    if (currentPassport.unit == PIXEL) {
      passportWidthByPixel = currentPassport.width;
      passportHeightByPixel = currentPassport.height;
    } else {
      passportWidthByPixel =
          FlutterConvert.convertUnit(
            currentPassport.unit,
            INCH,
            currentPassport.width,
          ) *
          dpi;
      passportHeightByPixel =
          FlutterConvert.convertUnit(
            currentPassport.unit,
            INCH,
            currentPassport.height,
          ) *
          dpi;
    }

    double passportWidthByPixelLimited, passportHeightByPixelLimited;

    if (max(passportWidthByPixel, passportHeightByPixel) >
        LIMITATION_DIMENSION_BY_PIXEl) {
      double aspectRatio = passportWidthByPixel / passportHeightByPixel;
      if (aspectRatio > 1) {
        passportWidthByPixelLimited = LIMITATION_DIMENSION_BY_PIXEl;
        passportHeightByPixelLimited =
            passportWidthByPixelLimited / aspectRatio;
      } else if (aspectRatio < 1) {
        passportHeightByPixelLimited = LIMITATION_DIMENSION_BY_PIXEl;
        passportWidthByPixelLimited =
            passportHeightByPixelLimited * aspectRatio;
      } else {
        passportWidthByPixelLimited = passportHeightByPixelLimited =
            LIMITATION_DIMENSION_BY_PIXEl;
      }
    } else {
      passportWidthByPixelLimited = passportWidthByPixel;
      passportHeightByPixelLimited = passportHeightByPixel;
    }
    consolelog(
      "_resizeImage limit: old = $passportWidthByPixel, $passportHeightByPixel, new = $passportWidthByPixelLimited, $passportHeightByPixelLimited",
    );

    final resizedFile = await MyMethodChannel.resizeAndResoluteImage(
      inputPath: imageCropped.path,
      format: indexImageFormat,
      listWH: [passportWidthByPixelLimited, passportHeightByPixelLimited],
      scaleWH: [1, 1],
      outPath: outPath,
      quality: quality,
    );
    return resizedFile;
  }

  static Future<File?> _resizeImageForPdf(
    File imageCropped,
    int indexImageFormat,
    CountryModel countrySelected,
    Size size,
    double dpi,
    List<double> listPassportDimensionByInch,
    int quality,
  ) async {
    final dirPath = (await getExternalStorageDirectory())!.path;
    String extension = LIST_FORMAT_IMAGE[indexImageFormat]
        .toLowerCase(); // JPG format
    String outPath = "$dirPath/$FINISH_IMAGE_NAME.$extension";

    // Size abc = handleLimitDPI(
    //     countrySelected, size, valueResolution, listPassportDimensionByInch);

    final resizedFile = await MyMethodChannel.resizeAndResoluteImage(
      inputPath: imageCropped.path,
      format: indexImageFormat,
      // listWH: [passportWidthByPixel, passportHeightByPixel],
      // scaleWH: [1, 1],
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
    final imageProvider = pw.MemoryImage(imageFile.readAsBytesSync());

    // Tạo trang PDF với kích thước bằng với ảnh
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          image.width.toDouble(),
          image.height.toDouble(),
        ),
        build: (pw.Context context) {
          return pw.Center(child: pw.Image(imageProvider));
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
      "handleLimitDPI passportSizeByPixelWithDpi = $passportSizeByPixelWithDpi",
    );
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
    required int copyNumber,
    required void Function(int count) onChangeCopyCount,
    required void Function() onTapOutside,
  }) {
    double heightDialog = MediaQuery.sizeOf(context).height * 0.45;
    double itemHeight = 44.0;
    RenderBox renderBox =
        keyCopy.currentContext?.findRenderObject() as RenderBox;
    Offset offset = renderBox.localToGlobal(
      const Offset(
        0,
        0,
      ).translate(-5, -heightDialog - (renderBox.size.height) - 35),
    );
    showCustomDialogWithOffset(
      context: context,
      newScreen: BodyDialogCustom(
        offset: offset,
        dialogWidget: WExports.buildDialogBody(
          context: context,
          selectedValue: copyNumber.toString(),
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
    Offset offset = renderBox
        .localToGlobal(const Offset(0, 0))
        .translate(-5, -heightOfDialog - (renderBox.size.height - 10));
    consolelog("currentExportSizecurrentExportSize = $currentExportSize");
    showCustomDialogWithOffset(
      context: context,
      newScreen: BodyDialogCustom(
        offset: offset,
        dialogWidget: WExports.buildDialogBody(
          context: context,
          selectedValue: currentExportSize.title,
          listValue: LIST_EXPORT_SIZE.map((e) => e.title).toList(),
          onSelected: (value) {
            ExportSizeModel? sizeModel = LIST_EXPORT_SIZE
                .where((element) => element.title == value)
                .toList()
                .firstOrNull;
            bool isCustomSize = value == LIST_EXPORT_SIZE.last.title;
            if (isCustomSize) {
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
                (exportSize) {
                  onChangeSize(exportSize);
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
        .localToGlobal(const Offset(0, 0))
        .translate(0, -172 - (renderBox.size.height - 15));

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

    Offset offset = renderBox
        .localToGlobal(const Offset(0, 0))
        .translate(
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
    void Function(ExportSizeModel exportSizeModel) onComplete,
  ) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return WBodyDialogCustomSize(
          exportSizeModel: exportSizeModel,
          onComplete: (ExportSizeModel exportSizeModel) {
            onComplete(exportSizeModel);
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
    double dpi,
  ) {
    if (currentPassport.unit == PIXEL) {
      return max(currentPassport.width, currentPassport.height) >
          LIMITATION_DIMENSION_BY_PIXEl;
    }
    double widthConvertedByPrintPoint =
        FlutterConvert.convertUnit(
          currentPassport.unit,
          INCH,
          currentPassport.width,
        ) *
        dpi;
    double heightConvertedByPrintPoint =
        FlutterConvert.convertUnit(
          currentPassport.unit,
          INCH,
          currentPassport.height,
        ) *
        dpi;

    return max(widthConvertedByPrintPoint, heightConvertedByPrintPoint) >
        LIMITATION_DIMENSION_BY_PIXEl;
  }

  // bool checkOverFlowSize(
  //   Size screenSize,
  //   PassportModel currentPassport,
  //   double dpi,
  // ) {
  //   double widthConverted = FlutterConvert.convertUnit(
  //     currentPassport.unit,
  //     INCH,
  //     currentPassport.width,
  //   );
  //   double heightConverted = FlutterConvert.convertUnit(
  //     currentPassport.unit,
  //     INCH,
  //     currentPassport.height,
  //   );

  //   Size expandedSize = Size(widthConverted, heightConverted);

  //   // Size(
  //   //   widthConverted * valueResolution,
  //   //   heightConverted * valueResolution,
  //   // );
  //   double maxDimension = max(expandedSize.width, expandedSize.height);
  //   consolelog("maxDimension ${screenSize}");
  //   if (screenSize.width > MIN_SIZE.width) {
  //     if (maxDimension >= MAX_SIZE_EXPORT_IMAGE_NORMAL) {
  //       return true;
  //     } else {
  //       return false;
  //     }
  //   } else {
  //     if (maxDimension >= MAX_SIZE_EXPORT_IMAGE_WEAK) {
  //       return true;
  //     } else {
  //       return false;
  //     }
  //   }
  // }

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
