import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:passport_photo_2/helpers/native_bridge/method_channel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';
import 'package:passport_photo_2/commons/constants.dart';
import 'package:passport_photo_2/helpers/convert.dart';
import 'package:passport_photo_2/helpers/log_custom.dart';
import 'package:passport_photo_2/models/country_passport_model.dart';
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
    final currentPassport = countrySelected.currentPassport;
    Unit imageUnit = currentPassport.unit;

    double widthPassport =
        FlutterConvert.convertUnit(imageUnit, POINT, currentPassport.width);
    double heightPassport =
        FlutterConvert.convertUnit(imageUnit, POINT, currentPassport.height);
    double marginLeft = max(1 / 2.54 * 72, format.marginLeft);
    double marginRight = max(1 / 2.54 * 72, format.marginRight);
    double marginTop = max(1 / 2.54 * 72, format.marginTop);
    double marginBottom = max(1 / 2.54 * 72, format.marginBottom);

    Size mainSizePassport = Size(widthPassport, heightPassport);

    Size imageSize = mainSizePassport;

    final soAnhTrong1Dong =
        (format.width - marginLeft - marginRight) ~/ imageSize.width;
    // 100 anh ->
    final maxRows =
        (format.height - marginTop - marginBottom) ~/ imageSize.height;
    final soAnhTrong1Trang = maxRows * soAnhTrong1Dong;
    int numberPage = numberImage ~/ soAnhTrong1Trang;
    if (numberImage % soAnhTrong1Trang > 0) {
      numberPage = numberPage + 1;
    }

    String outPath =
        "${(await getExternalStorageDirectory())!.path}/resize_before_print.jpg";
    File? convertedFile = await MyMethodChannel.resizeAndResoluteImage(
      inputPath: croppedFile.path,
      format: 0,
      listWH: [imagePreviewSize.width, imagePreviewSize.height],
      scaleWH: [1, 1],
      outPath: outPath,
    );

    Uint8List byteData = convertedFile!.readAsBytesSync();

    pw.Image imageMemory = pw.Image(pw.MemoryImage(byteData));
    double khoangKhongBaoQuanhGiuaCacAnh = 1 / 10 / 2.54 * 72 / 2; // 0.5 mm
    // draw pdf page
    for (int i = 0; i < numberPage; i++) {
      int numberImageOnPage = 0;
      int soAnhConLai = numberImage - (i) * soAnhTrong1Trang;
      if (soAnhConLai >= soAnhTrong1Trang) {
        numberImageOnPage = soAnhTrong1Trang;
      } else {
        numberImageOnPage = soAnhConLai;
        if (soAnhConLai < soAnhTrong1Dong) {
          // vẽ thừa 1 số ảnh còn lại để căn trái list
          numberImageOnPage = soAnhTrong1Dong;
        }
      }

      consolelog(
          "gen pdf true: $imageSize - ${Size(format.width, format.height)} ");
      pdf.addPage(
        pw.Page(
          pageFormat: format,
          build: (context) {
            return pw.Container(
                padding: pw.EdgeInsets.fromLTRB(
                    marginLeft, marginTop, marginRight, marginBottom),
                alignment: pw.Alignment.topCenter,
                child: pw.Wrap(
                  alignment: pw.WrapAlignment.start,
                  crossAxisAlignment: pw.WrapCrossAlignment.start,
                  children: List.generate(numberImageOnPage, (index) => index)
                      .map((e) {
                    // vẽ thừa 1 số ảnh còn lại để căn trái list
                    if ((e + 1) + i * soAnhTrong1Trang > numberImage) {
                      return pw.Container(
                        margin:
                            pw.EdgeInsets.all(khoangKhongBaoQuanhGiuaCacAnh),
                        height: imageSize.height,
                        width: imageSize.width,
                      );
                    }
                    return pw.Container(
                      margin: pw.EdgeInsets.all(khoangKhongBaoQuanhGiuaCacAnh),
                      height: imageSize.height,
                      width: imageSize.width,
                      alignment: pw.Alignment.center,
                      child: imageMemory,
                    );
                  }).toList(),
                ));
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
    final pdf = pw.Document(
      pageMode: PdfPageMode.fullscreen,
      version: PdfVersion.pdf_1_5,
    );
    consolelog(
        "generatePaperPdf format: $format, passportSizeDrawByPoint = $passportSizeDrawByPoint, copyNumber = $numberImage");

    Size imageSize = passportSizeDrawByPoint;
    consolelog("format.width = ${format.width}");
    final soAnhTrong1Dong =
        (format.width - format.marginLeft - format.marginRight) ~/
            imageSize.width;

    final soDongTrong1Trang =
        (format.height - format.marginTop - format.marginBottom) ~/
            imageSize.height;
    final soAnhTrong1Trang = soDongTrong1Trang * soAnhTrong1Dong;
    int soTrangCanIn = (numberImage / soAnhTrong1Trang).ceil();

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
    consolelog("soAnhTrong1Trang = $soAnhTrong1Trang");
    // draw pdf page
    for (int i = 0; i < soTrangCanIn; i++) {
      int soAnh = soAnhTrong1Trang;
      if (i >= soTrangCanIn - 1) {
        soAnh = numberImage - soAnhTrong1Trang * (soTrangCanIn - 1);
      }

      // int numberImageOnPage = 0;
      // int soAnhConLai = numberImage - (i) * soAnhTrong1Trang;
      // if (soAnhConLai >= soAnhTrong1Trang) {
      //   numberImageOnPage = soAnhTrong1Trang;
      // } else {
      //   numberImageOnPage = soAnhConLai;
      //   if (soAnhConLai < soAnhTrong1Dong) {
      //     // vẽ thừa 1 số ảnh còn lại để căn trái list
      //     numberImageOnPage = soAnhTrong1Dong;
      //   }
      // }
      consolelog("soAnh: $soAnh");
      pdf.addPage(
        pw.Page(
          pageFormat: format,
          build: (context) {
            return pw.Container(
              alignment: pw.Alignment.topCenter,
              child: pw.Wrap(
                spacing: listSpaceHV[0],
                runSpacing: listSpaceHV[1],
                alignment: pw.WrapAlignment.start,
                crossAxisAlignment: pw.WrapCrossAlignment.start,
                children: List.generate(soAnh, (index) => index).map(
                  (e) {
                    // vẽ thừa 1 số ảnh còn lại để căn trái list
                    if ((e + 1) + i * soAnhTrong1Trang > numberImage) {
                      return pw.Container(
                        height: imageSize.height,
                        width: imageSize.width,
                      );
                    }
                    return pw.Container(
                      height: imageSize.height,
                      width: imageSize.width,
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
