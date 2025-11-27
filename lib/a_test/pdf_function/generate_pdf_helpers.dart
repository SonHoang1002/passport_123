import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:passport_photo_2/helpers/print_helper.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';
import 'package:flutter_gpu_filters_interface/flutter_gpu_filters_interface.dart';
import 'package:passport_photo_2/commons/colors.dart';
import 'package:passport_photo_2/commons/constants.dart';
import 'package:passport_photo_2/helpers/convert.dart';
import 'package:passport_photo_2/helpers/fill_image_on_pdf.dart';
import 'package:passport_photo_2/helpers/log_custom.dart';
import 'package:passport_photo_2/models/country_passport_model.dart';
import 'package:passport_photo_2/models/export_size_model.dart';
import 'package:passport_photo_2/models/project_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';

class GeneratePdfHelpers {
  Map<String, dynamic> draw(
    ProjectModel projectModel,
    ExportSizeModel exportSize,
    int copyNumber,
    ui.Image imageData,
    double dpi,
  ) {
    /// Tờ giấy
    double paperWidthConvertedByPoint = FlutterConvert.convertUnit(
      exportSize.unit,
      POINT,
      exportSize.size.width,
    );
    double paperHeightConvertedByPoint = FlutterConvert.convertUnit(
      exportSize.unit,
      POINT,
      exportSize.size.height,
    );

    Size paperSizeConvertedByPoint =
        Size(paperWidthConvertedByPoint, paperHeightConvertedByPoint);

    EdgeInsets margin = exportSize.marginModel.toEdgeInsets();

    double left = FlutterConvert.convertUnit(POINT, POINT, margin.left);
    double top = FlutterConvert.convertUnit(POINT, POINT, margin.top);
    double right = FlutterConvert.convertUnit(POINT, POINT, margin.right);
    double bottom = FlutterConvert.convertUnit(POINT, POINT, margin.bottom);

    margin = EdgeInsets.fromLTRB(left, top, right, bottom);
    //
    double spacingHorizontalByPoint =
        FlutterConvert.convertUnit(POINT, POINT, exportSize.spacingHorizontal);

    double spacingVerticalByPoint = FlutterConvert.convertUnit(
      POINT,
      POINT,
      exportSize.spacingVertical,
    );
    //
    PassportModel currentPassport = projectModel.countryModel!.currentPassport;

    /// Kích thước ảnh hộ chiếu đổi ra đơn vị point

    double passportWidthConvertedByPoint, passportHeightConvertedByPoint;
    if (currentPassport.unit == PIXEL) {
      passportWidthConvertedByPoint = currentPassport.width / dpi * 72;
      passportHeightConvertedByPoint = currentPassport.height / dpi * 72;
    } else {
      passportWidthConvertedByPoint = FlutterConvert.convertUnit(
        currentPassport.unit,
        POINT,
        currentPassport.width,
      );
      passportHeightConvertedByPoint = FlutterConvert.convertUnit(
        currentPassport.unit,
        POINT,
        currentPassport.height,
      );
    }

    Size passportSizeConvertedByPoint =
        Size(passportWidthConvertedByPoint, passportHeightConvertedByPoint);

    // giới hạn kích thước ảnh
    Size aroundSize = paperSizeConvertedByPoint.copyWith(
      width: paperSizeConvertedByPoint.width - margin.left - margin.right,
      height: paperSizeConvertedByPoint.height - margin.top - margin.bottom,
    );

    Size passportSizeLimitedByPoint = getLimitImageInPaper(
      aroundSize,
      passportSizeConvertedByPoint,
      isKeepSizeWhenSmall: true,
    );

    int countImageOn1Row =
        max(1, (aroundSize.width) ~/ passportSizeLimitedByPoint.width);

    int countRowOn1Page =
        max(1, (aroundSize.height) ~/ passportSizeLimitedByPoint.height);
    consolelog(
        "passportSizeLimitedByPoint: $passportSizeLimitedByPoint, countImageOn1Row = $countImageOn1Row, countRowOn1Page = $countRowOn1Page, margin = $margin");

    int countImageMaxOn1Page = countRowOn1Page * countImageOn1Row;

    int countPage = (copyNumber / countImageMaxOn1Page).ceil();
    consolelog(
        "passportSizeLimitedByPoint:  $passportSizeLimitedByPoint, margin = $margin, countImageOn1Row = $countImageOn1Row, countRowOn1Page = $countRowOn1Page, countImageMaxOn1Page = $countImageMaxOn1Page, countPage = $countPage");

    List<ui.Image> listResult = [];
    for (var i = 0; i < countPage; i++) {
      int countImageNeedDraw = countImageMaxOn1Page;
      if (i >= countPage - 1) {
        countImageNeedDraw =
            copyNumber - countImageMaxOn1Page * (countPage - 1);
      }
      ui.Image result = _generateSinglePdfPage(
        imageData: imageData,
        paperSizeByPoint: paperSizeConvertedByPoint, // paperSizeConverted
        passportSizeByPoint: passportSizeLimitedByPoint, // passportSizeLimited
        countImageNeedDraw: countImageNeedDraw,
        countImageOn1Row: countImageOn1Row,
        countRow: countRowOn1Page,
        spacingHorizontalByPoint: spacingHorizontalByPoint,
        spacingVerticalByPoint: spacingVerticalByPoint,
        margin: margin,
      );
      listResult.add(result);
    }
    return {
      "listUiImage": listResult,
      "paperSizeConvertedByPoint": paperSizeConvertedByPoint,
      "passportSizeLimitedByPoint": passportSizeLimitedByPoint,
      "spacingHorizontalByPoint": spacingHorizontalByPoint,
      "spacingVerticalByPoint": spacingVerticalByPoint,
      "marginByPoint": margin,
    };
  }

  ui.Image _generateSinglePdfPage({
    required ui.Image imageData,
    required Size paperSizeByPoint,
    required Size passportSizeByPoint,
    required int countImageNeedDraw,
    required int countImageOn1Row,
    required int countRow,
    required double spacingHorizontalByPoint,
    required double spacingVerticalByPoint,
    required EdgeInsets margin,
  }) {
    ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    Canvas canvas = Canvas(pictureRecorder);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, paperSizeByPoint.width, paperSizeByPoint.height),
      Paint()..color = white,
    );

    int column = countImageOn1Row;
    int row = countRow;
    // tinh phan thua de can giua cac passport
    double tong_do_dai_can_ve =
        column * (spacingHorizontalByPoint + passportSizeByPoint.width);
    double deltaWidthToAlignCenter = max(
        0, (paperSizeByPoint.width - margin.left * 2 - tong_do_dai_can_ve) / 2);

    for (var y = 0; y < row; y++) {
      for (var i = 0; i < column; i++) {
        double marginLeft = margin.left +
            passportSizeByPoint.width * i +
            spacingHorizontalByPoint * (i + 1) +
            deltaWidthToAlignCenter;
        double marginTop = margin.top +
            passportSizeByPoint.height * y +
            spacingVerticalByPoint * (y + 1);
        int thu_tu_cua_anh = y * column + (i + 1);
        if (thu_tu_cua_anh > countImageNeedDraw) {
          canvas.drawRect(
            Rect.fromLTWH(
              marginLeft,
              marginTop,
              passportSizeByPoint.width,
              passportSizeByPoint.height,
            ),
            Paint()..color = transparent,
          );
        } else {
          canvas.drawImageRect(
            imageData,
            Rect.fromLTWH(
              0,
              0,
              imageData.width.toDouble(),
              imageData.height.toDouble(),
            ),
            Rect.fromLTWH(
              marginLeft,
              marginTop,
              passportSizeByPoint.width,
              passportSizeByPoint.height,
            ),
            Paint(),
          );
        }
      }
    }
    var data = pictureRecorder.endRecording().toImageSync(
          paperSizeByPoint.width.toInt(),
          paperSizeByPoint.height.toInt(),
        );
    return data;
  }

  Future<File?> generateSingleImagePdf(
    Size passportSize,
    List<File> listFile,
  ) async {
    consolelog(
        "generateSingleImagePdf: ${passportSize}, listFile = ${listFile}");
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
      File result =
          await File("$path/passport_gen_1.pdf").writeAsBytes(uInt8List);
      return result;
    } catch (e) {
      consolelog("generatePdf error: ${e}");
    }
    return null;
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
        "generatePaperPdf data: paperSizeDrawByPoint: $paperSizeDrawByPoint, passportSizeDraw = $passportSizeDrawByPoint");
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
