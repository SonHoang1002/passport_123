import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:pass1_/helpers/print_helper.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';
import 'package:flutter_gpu_filters_interface/flutter_gpu_filters_interface.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/helpers/convert.dart';
import 'package:pass1_/helpers/fill_image_on_pdf.dart';
import 'package:pass1_/helpers/log_custom.dart';
import 'package:pass1_/models/country_passport_model.dart';
import 'package:pass1_/models/export_size_model.dart';
import 'package:pass1_/models/project_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';

class GeneratePdfHelpers {
  Future<Map<String, dynamic>> drawPdfImageV1(
    ProjectModel projectModel,
    ExportSizeModel exportSize,
    int copyNumber,
    double dpi,
    ui.Image image,
  ) async {
    double paperWidthByPixelPoint =
        FlutterConvert.convertUnit(
          exportSize.unit,
          INCH,
          exportSize.size.width,
        ) *
        dpi;

    double paperHeightByPixelPoint =
        FlutterConvert.convertUnit(
          exportSize.unit,
          INCH,
          exportSize.size.height,
        ) *
        dpi;

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
          dpi;
      marginTopByPixelPoint =
          FlutterConvert.convertUnit(exportUnit, INCH, marginByExportUnit.top) *
          dpi;
      marginRightByPixelPoint =
          FlutterConvert.convertUnit(
            exportUnit,
            INCH,
            marginByExportUnit.right,
          ) *
          dpi;
      marginBottomByPixelPoint =
          FlutterConvert.convertUnit(
            exportUnit,
            INCH,
            marginByExportUnit.bottom,
          ) *
          dpi;
      spacingHorizontalByPixelPoint =
          FlutterConvert.convertUnit(
            exportUnit,
            INCH,
            exportSize.spacingHorizontal,
          ) *
          dpi;
      spacingVerticalByPixelPoint =
          FlutterConvert.convertUnit(
            exportUnit,
            INCH,
            exportSize.spacingVertical,
          ) *
          dpi;
    }

    var marginByPixelPoint = EdgeInsets.fromLTRB(
      marginLeftByPixelPoint,
      marginTopByPixelPoint,
      marginRightByPixelPoint,
      marginBottomByPixelPoint,
    );

    PassportModel? currentPassport = projectModel.countryModel?.currentPassport;
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
          dpi;
      passportHeightByPixelPoint =
          FlutterConvert.convertUnit(
            currentPassportUnit,
            INCH,
            currentPassport.height,
          ) *
          dpi;
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

    Size mainpassportSizeByPixelLimited = Size(
      passportSizeByPixelLimited.width + spacingHorizontalByPixelPoint * 2,
      passportSizeByPixelLimited.height + spacingVerticalByPixelPoint,
    );

    int countColumnIn1Page = max(
      1,
      (aroundAvailableSizeByPixelPoint.width) ~/
          mainpassportSizeByPixelLimited.width,
    );

    int countRowIn1Page = max(
      1,
      (aroundAvailableSizeByPixelPoint.height) ~/
          mainpassportSizeByPixelLimited.height,
    );

    int countImageOn1Page = countRowIn1Page * countColumnIn1Page;

    int countPage = (copyNumber / countImageOn1Page).ceil();
    consolelog(
      "passportSizeLimitedByPixel:  $passportSizeByPixelLimited, margin = $marginByPixelPoint, countColumnIn1Page = $countColumnIn1Page, countRowIn1Page = $countRowIn1Page, countPage = $countPage",
    );

    List<ui.Image> listResult = [];
    for (var indexPage = 0; indexPage < countPage; indexPage++) {
      ui.Image result = _generateSinglePdfImage(
        imageData: image,
        paperSizeByPixel: paperSizeByPixelPointLimited,
        passportSizeByPixel: passportSizeByPixelLimited,
        countImageNeedDraw: copyNumber,
        indexPage: indexPage,
        countColumnIn1Page: countColumnIn1Page,
        countRowIn1Page: countRowIn1Page,
        spacingHorizontalByPixel: spacingHorizontalByPixelPoint,
        spacingVerticalByPixel: spacingVerticalByPixelPoint,
        margin: marginByPixelPoint,
      );
      listResult.add(result);
    }
    return {
      "listUiPdfImage": listResult,
      // "paperSizeByPixel": paperSizeByPixel,
      // "passportSizeByPixel": passportSizeLimitedByPixel,
      // "spacingHorizontalByPixel": spacingHorizontalByPixel,
      // "spacingVerticalByPixel": spacingVerticalByPixel,
      // "marginByPixel": margin,
    };
  }

  Map<String, dynamic> caculateDimensionsInPrintPointForPdf(
    ProjectModel projectModel,
    ExportSizeModel exportSize,
    int copyNumber,
    // ui.Image imageData,
    double dpi,
  ) {
    /// Tờ giấy đổi sang pixel, có sử dụng dpi kèm theo
    double paperWidthByPoint, paperHeightByPoint;

    EdgeInsets marginByCurrentUnit = exportSize.marginModel
        .toEdgeInsetsByCurrentUnit();

    double leftByPoint, topByPoint, rightByPoint, bottomByPoint;
    double spacingHorizontalByPoint, spacingVerticalByPoint;

    var exportUnit = exportSize.unit;
    if (exportUnit == PIXEL) {
      paperWidthByPoint = exportSize.width / dpi * 72;
      paperHeightByPoint = exportSize.height / dpi * 72;

      leftByPoint = marginByCurrentUnit.left / dpi * 72;
      rightByPoint = marginByCurrentUnit.right / dpi * 72;
      topByPoint = marginByCurrentUnit.top / dpi * 72;
      bottomByPoint = marginByCurrentUnit.bottom / dpi * 72;

      spacingHorizontalByPoint = exportSize.spacingHorizontal / dpi * 72;
      spacingVerticalByPoint = exportSize.spacingVertical / dpi * 72;
    } else {
      paperWidthByPoint = FlutterConvert.convertUnit(
        exportUnit,
        POINT,
        exportSize.width,
      );

      paperHeightByPoint = FlutterConvert.convertUnit(
        exportUnit,
        POINT,
        exportSize.height,
      );

      leftByPoint = FlutterConvert.convertUnit(
        exportUnit,
        POINT,
        marginByCurrentUnit.left,
      );
      topByPoint = FlutterConvert.convertUnit(
        exportUnit,
        POINT,
        marginByCurrentUnit.top,
      );
      rightByPoint = FlutterConvert.convertUnit(
        exportUnit,
        POINT,
        marginByCurrentUnit.right,
      );
      bottomByPoint = FlutterConvert.convertUnit(
        exportUnit,
        POINT,
        marginByCurrentUnit.bottom,
      );

      spacingHorizontalByPoint = FlutterConvert.convertUnit(
        exportUnit,
        POINT,
        exportSize.spacingHorizontal,
      );

      spacingVerticalByPoint = FlutterConvert.convertUnit(
        exportUnit,
        POINT,
        exportSize.spacingVertical,
      );
    }

    Size paperSizeByPoint = Size(paperWidthByPoint, paperHeightByPoint);

    EdgeInsets marginByPoint = EdgeInsets.fromLTRB(
      leftByPoint,
      topByPoint,
      rightByPoint,
      bottomByPoint,
    );
    //

    Size passportSizeByPoint;
    var currentPassport = projectModel.countryModel?.currentPassport;
    if (currentPassport == null) {
      throw Exception("Current Passport is null, please check!!");
    }
    var currentPassportUnit = currentPassport.unit;
    if (currentPassportUnit == PIXEL) {
      passportSizeByPoint = Size(
        currentPassport.width / dpi * 72,
        currentPassport.height / dpi * 72,
      );
    } else {
      passportSizeByPoint = Size(
        FlutterConvert.convertUnit(
          currentPassportUnit,
          POINT,
          currentPassport.width,
        ),
        FlutterConvert.convertUnit(
          currentPassportUnit,
          POINT,
          currentPassport.height,
        ),
      );
    }
    consolelog("passportSizeByPointpassportSizeByPoint = $passportSizeByPoint");

    // giới hạn kích thước passportWidthByPoint ảnh
    Size aroundAvailableSizeByPoint = paperSizeByPoint.copyWith(
      width: paperSizeByPoint.width - marginByPoint.left - marginByPoint.right,
      height:
          paperSizeByPoint.height - marginByPoint.top - marginByPoint.bottom,
    );

    Size passportSizeLimitedByPoint = getLimitImageInPaper(
      aroundAvailableSizeByPoint,
      passportSizeByPoint,
      isKeepSizeWhenSmall: true,
    );

    int countImageOn1Row = max(
      1,
      (aroundAvailableSizeByPoint.width) ~/ passportSizeLimitedByPoint.width,
    );

    int countRowOn1Page = max(
      1,
      (aroundAvailableSizeByPoint.height) ~/ passportSizeLimitedByPoint.height,
    );
    consolelog(
      "passportSizeLimitedByPoint: $passportSizeLimitedByPoint, countImageOn1Row = $countImageOn1Row, countRowOn1Page = $countRowOn1Page, marginByPoint = $marginByPoint",
    );

    int countImageMaxOn1Page = countRowOn1Page * countImageOn1Row;

    int countPage = (copyNumber / countImageMaxOn1Page).ceil();
    consolelog(
      "passportSizeLimitedByPoint:  $passportSizeLimitedByPoint, marginByPoint = $marginByPoint, countImageOn1Row = $countImageOn1Row, countRowOn1Page = $countRowOn1Page, countImageMaxOn1Page = $countImageMaxOn1Page, countPage = $countPage",
    );

    return {
      "paperSizeByPoint": paperSizeByPoint,
      "passportSizeByPoint": passportSizeLimitedByPoint,
      "spacingHorizontalByPoint": spacingHorizontalByPoint,
      "spacingVerticalByPoint": spacingVerticalByPoint,
      "marginByPoint": marginByPoint,
    };
  }

  /// Dùng canvas để vẽ ra ảnh dạng paper, ném ảnh vào và sắp xếp bên trong tờ giấy ấy
  ui.Image _generateSinglePdfImage({
    required ui.Image imageData,
    required Size paperSizeByPixel,
    required Size passportSizeByPixel,
    required int indexPage,
    required int countImageNeedDraw,
    required int countRowIn1Page,
    required int countColumnIn1Page,
    required double
    spacingHorizontalByPixel, // Đổi tên cho rõ nghĩa: spacing GIỮA các ảnh
    required double spacingVerticalByPixel, // spacing GIỮA các hàng
    required EdgeInsets margin,
  }) {
    consolelog(
      "_generateSinglePdfImage param:"
      " paperSizeByPixel = $paperSizeByPixel,"
      " passportSizeByPixel = $passportSizeByPixel,"
      " countRowIn1Page = $countRowIn1Page,"
      " countColumnIn1Page = $countColumnIn1Page,"
      " indexPage = $indexPage,"
      " spacingHorizontalByPixel = $spacingHorizontalByPixel,"
      " spacingVerticalByPixel = $spacingVerticalByPixel,"
      " margin: $margin",
    );

    ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    Canvas canvas = Canvas(pictureRecorder);

    // Vẽ nền trắng cho trang
    canvas.drawRect(
      Rect.fromLTWH(0, 0, paperSizeByPixel.width, paperSizeByPixel.height),
      Paint()..color = white,
    );

    // Tính toán căn giữa theo chiều ngang
    // Tổng chiều rộng cần vẽ = n * imageWidth + (n-1) * spacing
    final totalWidthNeeded =
        countColumnIn1Page * passportSizeByPixel.width +
        (countColumnIn1Page - 1) * spacingHorizontalByPixel;

    // Khoảng cách cần thêm vào 2 bên để căn giữa
    final deltaWidthToAlignCenter = max(
      0,
      (paperSizeByPixel.width - margin.left - margin.right - totalWidthNeeded) /
          2,
    );

    // Tính toán tương tự cho chiều dọc
    final totalHeightNeeded =
        countRowIn1Page * passportSizeByPixel.height +
        (countRowIn1Page - 1) * spacingVerticalByPixel;

    final deltaHeightToAlignCenter = max(
      0,
      (paperSizeByPixel.height -
              margin.top -
              margin.bottom -
              totalHeightNeeded) /
          2,
    );

    consolelog(
      "Total width needed: $totalWidthNeeded, Delta width: $deltaWidthToAlignCenter",
    );
    consolelog(
      "Total height needed: $totalHeightNeeded, Delta height: $deltaHeightToAlignCenter",
    );

    for (var indexRow = 0; indexRow < countRowIn1Page; indexRow++) {
      for (
        var indexColumn = 0;
        indexColumn < countColumnIn1Page;
        indexColumn++
      ) {
        // Tính toán vị trí với spacing GIỮA các ảnh
        // Công thức: margin + căn_giữa + column * (imageWidth + spacing)
        double left =
            margin.left +
            deltaWidthToAlignCenter +
            indexColumn *
                (passportSizeByPixel.width + spacingHorizontalByPixel * 2);

        double top =
            margin.top +
            // deltaHeightToAlignCenter +
            indexRow *
                (passportSizeByPixel.height + spacingVerticalByPixel * 2);

        // Tính số thứ tự ảnh hiện tại
        int currentImageIndex =
            indexPage * countRowIn1Page * countColumnIn1Page +
            indexRow * countColumnIn1Page +
            indexColumn;

        bool isOverCountImageNeedDraw = currentImageIndex >= countImageNeedDraw;

        if (isOverCountImageNeedDraw) {
          // Vẽ container trống (trong suốt)
          canvas.drawRect(
            Rect.fromLTWH(
              left,
              top,
              passportSizeByPixel.width,
              passportSizeByPixel.height,
            ),
            Paint()..color = transparent,
          );
        } else {
          // Vẽ ảnh thật
          canvas.drawImageRect(
            imageData,
            Rect.fromLTWH(
              0,
              0,
              imageData.width.toDouble(),
              imageData.height.toDouble(),
            ),
            Rect.fromLTWH(
              left,
              top,
              passportSizeByPixel.width,
              passportSizeByPixel.height,
            ),
            Paint(),
          );

          // Vẽ border xung quanh ảnh (tùy chọn, để debug)
          canvas.drawRect(
            Rect.fromLTWH(
              left,
              top,
              passportSizeByPixel.width,
              passportSizeByPixel.height,
            ),
            Paint()
              ..color =
                  const Color.fromARGB(50, 128, 128, 128) // Màu xám trong suốt
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.5,
          );
        }
      }
    }

    var data = pictureRecorder.endRecording().toImageSync(
      paperSizeByPixel.width.toInt(),
      paperSizeByPixel.height.toInt(),
    );
    return data;
  }

  Future<File> generateSingleImagePdf(
    Size passportSize,
    List<File> listFile,
  ) async {
    consolelog(
      "generateSingleImagePdf: ${passportSize}, listFile = ${listFile}",
    );
    try {
      final pdf = pw.Document(
        pageMode: PdfPageMode.fullscreen,
        version: PdfVersion.pdf_1_5,
      );

      PdfPageFormat? pageFormat = PdfPageFormat(
        passportSize.width,
        passportSize.height,
      );

      for (var i = 0; i < listFile.length; i++) {
        var item = listFile[i];
        Uint8List bytes = await item.readAsBytes();
        pw.MemoryImage image = pw.MemoryImage(bytes);

        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            build: (context) {
              return pw.Container(
                width: pageFormat.width,
                height: pageFormat.height,
                child: pw.Image(image),
              );
            },
          ),
        );
      }

      final uInt8List = await pdf.save();
      var path = (await getExternalStorageDirectory())!.path;
      File result = await File(
        "$path/passport_gen_1.pdf",
      ).writeAsBytes(uInt8List);
      return result;
    } catch (e) {
      consolelog("generatePdf error: ${e}");
      rethrow;
    }
  }

  Future<File> generatePaperPdf(
    ProjectModel projectModel,
    Size paperSizeDrawByPoint,
    Size passportSizeDrawByPoint,
    int copyNumber,
    double valueResolutionDpi,
    List<double> listSpaceHV,
    EdgeInsets marginByPoint,
    int quality,
  ) async {
    consolelog(
      "generatePaperPdf param: paperSizeDrawByPoint: $paperSizeDrawByPoint, passportSizeDraw = $passportSizeDrawByPoint, marginByPoint = $marginByPoint",
    );
    PdfPageFormat format = PdfPageFormat(
      paperSizeDrawByPoint.width,
      paperSizeDrawByPoint.height,
      marginBottom: marginByPoint.bottom,
      marginLeft: marginByPoint.left,
      marginTop: marginByPoint.top,
      marginRight: marginByPoint.right,
    );

    var bytes = await PrintHelper().generatePaperPdf(
      format,
      passportSizeDrawByPoint,
      "Document",
      projectModel.croppedFile!,
      projectModel.uiImageCropped!,
      copyNumber,
      quality,
      listSpaceHV,
    );
    var extenalPath = (await getExternalStorageDirectory())!.path;
    return await File("$extenalPath/passport_gen_2.pdf").writeAsBytes(bytes);
  }
}
