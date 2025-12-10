import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:pass1_/commons/extension.dart';
import 'package:pass1_/helpers/native_bridge/method_channel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/helpers/convert.dart';
import 'package:pass1_/helpers/log_custom.dart';
import 'package:pass1_/models/country_passport_model.dart';
import 'package:pdf/pdf.dart';

class PrintHelper {
  Future<Uint8List> generatePdf({
    required PdfPageFormat format,
    required String title,
    required File croppedFile,
    required int numberImage,
    required CountryModel countrySelected,
    required Size passportSizeByPrintPoint,
  }) async {
    final pdf = pw.Document(
      pageMode: PdfPageMode.fullscreen,
      version: PdfVersion.pdf_1_5,
    );

    double marginLeft = max(1 / 2.54 * 72, format.marginLeft); // Min là 1 cm
    double marginRight = max(1 / 2.54 * 72, format.marginRight); // Min là 1 cm
    double marginTop = max(1 / 2.54 * 72, format.marginTop); // Min là 1 cm
    double marginBottom = max(
      1 / 2.54 * 72,
      format.marginBottom,
    ); // Min là 1 cm
    final double availableWidth = format.width - marginLeft - marginRight;
    final double availableHeight = format.height - marginTop - marginBottom;

    final currentPassport = countrySelected.currentPassport;
    Unit imageUnit = currentPassport.unit;
    double widthPassportByPoint, heightPassportByPoint;
    if (currentPassport.unit == PIXEL) {
      widthPassportByPoint = currentPassport.width / PRINT_DEFAULT_DPI * 72;
      heightPassportByPoint = currentPassport.height / PRINT_DEFAULT_DPI * 72;
    } else {
      widthPassportByPoint = FlutterConvert.convertUnit(
        imageUnit,
        POINT,
        currentPassport.width,
      );
      heightPassportByPoint = FlutterConvert.convertUnit(
        imageUnit,
        POINT,
        currentPassport.height,
      );
    }

    Size mainSizePassportByPoint = Size(
      widthPassportByPoint,
      heightPassportByPoint,
    ).limitToInner(Size(availableWidth, availableHeight));

    consolelog(
      "widthPassportByPoint = $widthPassportByPoint, heightPassportByPoint = $heightPassportByPoint, mainSizePassportByPoint = $mainSizePassportByPoint",
    );

    double spacingHorizontalAroundImageByPoint =
        PRINT_MARGIN_AROUND_IMAGE_BY_POINT; // 0.5 mm
    double spacingVerticalAroundImageByPoint =
        PRINT_MARGIN_AROUND_IMAGE_BY_POINT; // 0.5 mm

    Size imageSizeByPoint = Size(
      mainSizePassportByPoint.width + spacingHorizontalAroundImageByPoint * 2,
      mainSizePassportByPoint.height + spacingVerticalAroundImageByPoint * 2,
    );

    final countImageIn1Row = availableWidth ~/ imageSizeByPoint.width;

    final maxRows = (availableHeight) ~/ imageSizeByPoint.height;
    final countImageIn1Page = maxRows * countImageIn1Row;
    int numberPage = numberImage ~/ countImageIn1Page;
    if (numberImage % countImageIn1Page > 0) {
      numberPage = numberPage + 1;
    }

    File? convertedFile = File(croppedFile.path);
    Uint8List byteData = convertedFile.readAsBytesSync();

    pw.Image imageMemory = pw.Image(pw.MemoryImage(byteData));

    for (int i = 0; i < numberPage; i++) {
      consolelog(
        "gen pdf true: $imageSizeByPoint - ${Size(format.width, format.height)}",
      );

      /// Nếu 1 ảnh -> center
      /// Phần còn lại nếu lẻ 1 ảnh thì căn trái
      pdf.addPage(
        pw.Page(
          pageFormat: format,
          build: (context) {
            return pw.Container(
              padding: pw.EdgeInsets.fromLTRB(
                marginLeft,
                marginTop,
                marginRight,
                marginBottom,
              ),
              alignment: pw.Alignment.topCenter,
              child: pw.Wrap(
                alignment: pw.WrapAlignment.start,
                crossAxisAlignment: pw.WrapCrossAlignment.start,
                children: List.generate(countImageIn1Page, (index) => index)
                    .map((e) {
                      // vẽ thừa 1 số ảnh còn lại để căn trái list
                      if ((e + 1) + i * countImageIn1Page > numberImage) {
                        return pw.Container(
                          margin: pw.EdgeInsets.symmetric(
                            horizontal: spacingHorizontalAroundImageByPoint,
                            vertical: spacingVerticalAroundImageByPoint,
                          ),
                          height: mainSizePassportByPoint.height,
                          width: mainSizePassportByPoint.width,
                        );
                      }
                      return pw.Container(
                        margin: pw.EdgeInsets.symmetric(
                          horizontal: spacingHorizontalAroundImageByPoint,
                          vertical: spacingVerticalAroundImageByPoint,
                        ),
                        height: mainSizePassportByPoint.height,
                        width: mainSizePassportByPoint.width,
                        alignment: pw.Alignment.center,
                        child: imageMemory,
                      );
                    })
                    .toList(),
              ),
            );
          },
        ),
      );
    }
    final result = await pdf.save();
    return result;
  }

  Future<Uint8List> generatePaperPdf(
    PdfPageFormat format,
    Size passportSizeDrawByPoint,
    String title,
    File originalCroppedImage,
    ui.Image uiImageCropped,
    int numberImage,
    int quality,
    List<double> listSpaceHV,
  ) async {
    // change quality of file
    final dirPath = (await getExternalStorageDirectory())!.path;
    String extension = "jpg";
    String outPath = "$dirPath/resize_before_pdf.$extension";
    consolelog("originalCroppedImage.path: ${originalCroppedImage.path}");
    final resizedFile = await MyMethodChannel.resizeAndResoluteImage(
      inputPath: originalCroppedImage.path,
      format: 0,
      // listWH: [passportSizeDrawByPoint.width, passportSizeDrawByPoint.height],
      // scaleWH: [1, 1],
      outPath: outPath,
      quality: quality,
    );
    Uint8List byteData = resizedFile!.readAsBytesSync();
    pw.Image imageMemory = pw.Image(
      pw.MemoryImage(byteData),
      fit: pw.BoxFit.cover,
    );
    consolelog("imageMemory = ${imageMemory.width}, ${imageMemory.height}");

    final pdf = pw.Document(
      pageMode: PdfPageMode.fullscreen,
      version: PdfVersion.pdf_1_5,
    );

    double spacingHorizontalByPoint =
        listSpaceHV[0]; // mặc định spacing là 0,5mm, 1 bên
    double spacingVerticalByPoint =
        listSpaceHV[1]; // mặc định spacing là 0,5mm, 1 bên

    Size imageSize = Size(
      passportSizeDrawByPoint.width + spacingHorizontalByPoint * 2,
      passportSizeDrawByPoint.height + spacingVerticalByPoint * 2,
    );

    final soAnhTrong1Dong =
        (format.width - format.marginLeft - format.marginRight) ~/
        (imageSize.width);

    final soDongTrong1Trang =
        (format.height - format.marginTop - format.marginBottom) ~/
        imageSize.height;
    final soAnhTrong1Trang = soDongTrong1Trang * soAnhTrong1Dong;
    int soTrangCanIn = (numberImage / soAnhTrong1Trang).ceil();

    // draw pdf page
    for (int i = 0; i < soTrangCanIn; i++) {
      pdf.addPage(
        pw.Page(
          pageFormat: format,
          build: (context) {
            return pw.Container(
              alignment: pw.Alignment.topCenter,
              child: pw.Wrap(
                alignment: pw.WrapAlignment.start,
                crossAxisAlignment: pw.WrapCrossAlignment.start,
                children: List.generate(soAnhTrong1Trang, (index) => index).map(
                  (e) {
                    bool isOver = (e + 1) + i * soAnhTrong1Trang > numberImage;
                    if (isOver) {
                      return pw.Container(
                        margin: pw.EdgeInsets.symmetric(
                          vertical: spacingVerticalByPoint,
                          horizontal: spacingHorizontalByPoint,
                        ),
                        height: passportSizeDrawByPoint.height,
                        width: passportSizeDrawByPoint.width,
                      );
                    }
                    return pw.Container(
                      color: PdfColors.grey500,
                      margin: pw.EdgeInsets.symmetric(
                        vertical: spacingVerticalByPoint,
                        horizontal: spacingHorizontalByPoint,
                      ),
                      height: passportSizeDrawByPoint.height,
                      width: passportSizeDrawByPoint.width,
                      alignment: pw.Alignment.center,
                      child: imageMemory,
                    );
                  },
                ).toList(),
              ),
            );
          },
        ),
      );
    }
    consolelog("before return pdf.save()");
    final result = await pdf.save();

    return result;
  }
}
