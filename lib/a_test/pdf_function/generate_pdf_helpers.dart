import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
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
  // Map<String, dynamic> draw(
  //   ProjectModel projectModel,
  //   ExportSizeModel exportSize,
  //   int copyNumber,
  //   ui.Image imageData,
  //   double dpi,
  // ) {
  //   /// Tờ giấy
  //   double paperWidthByPoint = FlutterConvert.convertUnit(
  //     exportSize.unit,
  //     POINT,
  //     exportSize.size.width,
  //   );
  //   double paperHeightByPoint = FlutterConvert.convertUnit(
  //     exportSize.unit,
  //     POINT,
  //     exportSize.size.height,
  //   );

  //   Size paperSizeByPoint = Size(paperWidthByPoint, paperHeightByPoint);

  //   EdgeInsets margin = exportSize.marginModel.toEdgeInsets();

  //   double left = FlutterConvert.convertUnit(POINT, POINT, margin.left);
  //   double top = FlutterConvert.convertUnit(POINT, POINT, margin.top);
  //   double right = FlutterConvert.convertUnit(POINT, POINT, margin.right);
  //   double bottom = FlutterConvert.convertUnit(POINT, POINT, margin.bottom);

  //   margin = EdgeInsets.fromLTRB(left, top, right, bottom);
  //   //
  //   double spacingHorizontalByPoint =
  //       FlutterConvert.convertUnit(POINT, POINT, exportSize.spacingHorizontal);

  //   double spacingVerticalByPoint = FlutterConvert.convertUnit(
  //     POINT,
  //     POINT,
  //     exportSize.spacingVertical,
  //   );
  //   //
  //   PassportModel currentPassport = projectModel.countryModel!.currentPassport;

  //   /// Kích thước ảnh hộ chiếu đổi ra đơn vị point

  //   double passportWidthByPoint, passportHeightByPoint;
  //   if (currentPassport.unit == PIXEL) {
  //     passportWidthByPoint = currentPassport.width / dpi * 72;
  //     passportHeightByPoint = currentPassport.height / dpi * 72;
  //   } else {
  //     passportWidthByPoint = FlutterConvert.convertUnit(
  //       currentPassport.unit,
  //       POINT,
  //       currentPassport.width,
  //     );
  //     passportHeightByPoint = FlutterConvert.convertUnit(
  //       currentPassport.unit,
  //       POINT,
  //       currentPassport.height,
  //     );
  //   }

  //   Size passportSizeByPoint =
  //       Size(passportWidthByPoint, passportHeightByPoint);

  //   // giới hạn kích thước ảnh
  //   Size aroundAvailableSize = paperSizeByPoint.copyWith(
  //     width: paperSizeByPoint.width - margin.left - margin.right,
  //     height: paperSizeByPoint.height - margin.top - margin.bottom,
  //   );

  //   Size passportSizeLimitedByPoint = getLimitImageInPaper(
  //     aroundAvailableSize,
  //     passportSizeByPoint,
  //     isKeepSizeWhenSmall: true,
  //   );

  //   int countImageOn1Row =
  //       max(1, (aroundAvailableSize.width) ~/ passportSizeLimitedByPoint.width);

  //   int countRowOn1Page = max(
  //       1, (aroundAvailableSize.height) ~/ passportSizeLimitedByPoint.height);
  //   consolelog(
  //       "passportSizeLimitedByPoint: $passportSizeLimitedByPoint, countImageOn1Row = $countImageOn1Row, countRowOn1Page = $countRowOn1Page, margin = $margin");

  //   int countImageMaxOn1Page = countRowOn1Page * countImageOn1Row;

  //   int countPage = (copyNumber / countImageMaxOn1Page).ceil();
  //   consolelog(
  //       "passportSizeLimitedByPoint:  $passportSizeLimitedByPoint, margin = $margin, countImageOn1Row = $countImageOn1Row, countRowOn1Page = $countRowOn1Page, countImageMaxOn1Page = $countImageMaxOn1Page, countPage = $countPage");

  //   List<ui.Image> listResult = [];
  //   for (var i = 0; i < countPage; i++) {
  //     int countImageNeedDraw = countImageMaxOn1Page;
  //     if (i >= countPage - 1) {
  //       countImageNeedDraw =
  //           copyNumber - countImageMaxOn1Page * (countPage - 1);
  //     }
  //     ui.Image result = _generateSinglePdfPage(
  //       imageData: imageData,
  //       paperSizeByPoint: paperSizeByPoint,
  //       passportSizeByPoint: passportSizeLimitedByPoint,
  //       countImageNeedDraw: countImageNeedDraw,
  //       countImageOn1Row: countImageOn1Row,
  //       countRow: countRowOn1Page,
  //       spacingHorizontalByPoint: spacingHorizontalByPoint,
  //       spacingVerticalByPoint: spacingVerticalByPoint,
  //       margin: margin,
  //     );
  //     listResult.add(result);
  //   }
  //   return {
  //     "listUiImage": listResult,
  //     "paperSizeByPoint": paperSizeByPoint,
  //     "passportSizeByPoint": passportSizeLimitedByPoint,
  //     "spacingHorizontalByPoint": spacingHorizontalByPoint,
  //     "spacingVerticalByPoint": spacingVerticalByPoint,
  //     "marginByPoint": margin,
  //   };
  // }

  // Map<String, dynamic> drawPdfImage(
  //   ProjectModel projectModel,
  //   ExportSizeModel exportSize,
  //   int copyNumber,
  //   ui.Image imageData,
  //   double dpi,
  // ) {
  //   consolelog("exportSize $exportSize");

  //   /// Tờ giấy đổi sang pixel, có sử dụng dpi kèm theo
  //   double paperWidthByPixel = FlutterConvert.convertUnit(
  //         exportSize.unit,
  //         INCH,
  //         exportSize.size.width,
  //       ) *
  //       dpi;

  //   double paperHeightByPixel = FlutterConvert.convertUnit(
  //         exportSize.unit,
  //         INCH,
  //         exportSize.size.height,
  //       ) *
  //       dpi;

  //   Size paperSizeByPixel = Size(paperWidthByPixel, paperHeightByPixel);

  //   EdgeInsets margin = exportSize.marginModel.toEdgeInsets();

  //   double marginLeftByPixel = FlutterConvert.convertUnit(
  //     POINT,
  //     INCH,
  //     margin.left,
  //   );
  //   double marginTopByPixel =
  //       FlutterConvert.convertUnit(exportSize.unit, INCH, margin.top) * dpi;
  //   double marginRightByPixel =
  //       FlutterConvert.convertUnit(exportSize.unit, INCH, margin.right) * dpi;
  //   double marginBottomByPixel =
  //       FlutterConvert.convertUnit(exportSize.unit, INCH, margin.bottom) * dpi;

  //   margin = EdgeInsets.fromLTRB(
  //     marginLeftByPixel,
  //     marginTopByPixel,
  //     marginRightByPixel,
  //     marginBottomByPixel,
  //   );
  //   //
  //   double spacingHorizontalByPixel = FlutterConvert.convertUnit(
  //         exportSize.unit,
  //         INCH,
  //         exportSize.spacingHorizontal,
  //       ) *
  //       dpi;

  //   double spacingVerticalByPixel = FlutterConvert.convertUnit(
  //         exportSize.unit,
  //         INCH,
  //         exportSize.spacingVertical,
  //       ) *
  //       dpi;
  //   //

  //   /// Kích thước ảnh hộ chiếu đổi ra đơn vị point

  //   Size passportSizeByPixel = Size(
  //     imageData.width.toDouble(),
  //     imageData.height.toDouble(),
  //   );

  //   // giới hạn kích thước passportWidthByPixel ảnh
  //   Size aroundAvailableSize = paperSizeByPixel.copyWith(
  //     width: paperSizeByPixel.width - margin.left - margin.right,
  //     height: paperSizeByPixel.height - margin.top - margin.bottom,
  //   );

  //   Size passportSizeLimitedByPixel = getLimitImageInPaper(
  //     aroundAvailableSize,
  //     passportSizeByPixel,
  //     isKeepSizeWhenSmall: true,
  //   );

  //   int countImageOn1Row = max(
  //     1,
  //     (aroundAvailableSize.width) ~/ passportSizeLimitedByPixel.width,
  //   );

  //   int countRowOn1Page = max(
  //     1,
  //     (aroundAvailableSize.height) ~/ passportSizeLimitedByPixel.height,
  //   );
  //   consolelog(
  //     "passportSizeLimitedByPixel: $passportSizeLimitedByPixel, countImageOn1Row = $countImageOn1Row, countRowOn1Page = $countRowOn1Page, margin = $margin",
  //   );

  //   int countImageMaxOn1Page = countRowOn1Page * countImageOn1Row;

  //   int countPage = (copyNumber / countImageMaxOn1Page).ceil();
  //   consolelog(
  //     "passportSizeLimitedByPixel:  $passportSizeLimitedByPixel, margin = $margin, countImageOn1Row = $countImageOn1Row, countRowOn1Page = $countRowOn1Page, countImageMaxOn1Page = $countImageMaxOn1Page, countPage = $countPage",
  //   );

  //   List<ui.Image> listResult = [];
  //   for (var i = 0; i < countPage; i++) {
  //     int countImageNeedDraw = countImageMaxOn1Page;
  //     if (i >= countPage - 1) {
  //       countImageNeedDraw =
  //           copyNumber - countImageMaxOn1Page * (countPage - 1);
  //     }
  //     ui.Image result = _generateSinglePdfImage(
  //       imageData: imageData,
  //       paperSizeByPixel: paperSizeByPixel,
  //       passportSizeByPixel: passportSizeLimitedByPixel,
  //       countImageNeedDraw: countImageNeedDraw,
  //       countImageOn1Row: countImageOn1Row,
  //       countRow: countRowOn1Page,
  //       spacingHorizontalByPixel: spacingHorizontalByPixel,
  //       spacingVerticalByPixel: spacingVerticalByPixel,
  //       margin: margin,
  //     );
  //     listResult.add(result);
  //   }
  //   return {
  //     "listUiPdfImage": listResult,
  //     "paperSizeByPixel": paperSizeByPixel,
  //     "passportSizeByPixel": passportSizeLimitedByPixel,
  //     "spacingHorizontalByPixel": spacingHorizontalByPixel,
  //     "spacingVerticalByPixel": spacingVerticalByPixel,
  //     "marginByPixel": margin,
  //   };
  // }

  Future<Map<String, dynamic>> drawPdfImageV1(
    ProjectModel projectModel,
    ExportSizeModel exportSize,
    int copyNumber,
    double dpi,
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

    if (exportSize.unit == PIXEL) {
      marginLeftByPixelPoint = exportSize.marginModel.mLeft;
      marginTopByPixelPoint = exportSize.marginModel.mTop;
      marginRightByPixelPoint = exportSize.marginModel.mRight;
      marginBottomByPixelPoint = exportSize.marginModel.mBottom;

      spacingHorizontalByPixelPoint = exportSize.spacingHorizontal;
      spacingVerticalByPixelPoint = exportSize.spacingVertical;
    } else {
      marginLeftByPixelPoint =
          FlutterConvert.convertUnit(
            exportSize.unit,
            INCH,
            marginByExportUnit.left,
          ) *
          dpi;
      marginTopByPixelPoint =
          FlutterConvert.convertUnit(
            exportSize.unit,
            INCH,
            marginByExportUnit.top,
          ) *
          dpi;
      marginRightByPixelPoint =
          FlutterConvert.convertUnit(
            exportSize.unit,
            INCH,
            marginByExportUnit.right,
          ) *
          dpi;
      marginBottomByPixelPoint =
          FlutterConvert.convertUnit(
            exportSize.unit,
            INCH,
            marginByExportUnit.bottom,
          ) *
          dpi;
      spacingHorizontalByPixelPoint =
          FlutterConvert.convertUnit(
            exportSize.unit,
            INCH,
            exportSize.spacingHorizontal,
          ) *
          dpi;
      spacingVerticalByPixelPoint =
          FlutterConvert.convertUnit(
            exportSize.unit,
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

    Size passportSizeByPixelPoint = Size(
      passportWidthByPixelPoint,
      passportHeightByPixelPoint,
    );

    // giới hạn kích thước passportWidthByPixel ảnh
    Size aroundAvailableSize = paperSizeByPixelPointLimited.copyWith(
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
      aroundAvailableSize,
      passportSizeByPixelPoint,
      isKeepSizeWhenSmall: true,
    );

    int countColumnIn1Page = max(
      1,
      (aroundAvailableSize.width) ~/ passportSizeByPixelLimited.width,
    );

    int countRowIn1Page = max(
      1,
      (aroundAvailableSize.height) ~/ passportSizeByPixelLimited.height,
    );
    consolelog(
      "passportSizeLimitedByPixel: $passportSizeByPixelLimited, countColumnIn1Page = $countColumnIn1Page, countRowIn1Page = $countRowIn1Page, margin = $marginByPixelPoint",
    );

    int countImageOn1Page = countRowIn1Page * countColumnIn1Page;

    int countPage = (copyNumber / countImageOn1Page).ceil();
    consolelog(
      "passportSizeLimitedByPixel:  $passportSizeByPixelLimited, margin = $marginByPixelPoint, countColumnIn1Page = $countColumnIn1Page, countRowIn1Page = $countRowIn1Page, countPage = $countPage",
    );

    Uint8List bytes = await projectModel.croppedFile!.readAsBytes();
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      completer.complete(img);
    });
    ui.Image imageData = await completer.future;

    List<ui.Image> listResult = [];
    for (var indexPage = 0; indexPage < countPage; indexPage++) {
      ui.Image result = _generateSinglePdfImage(
        imageData: imageData,
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

  Map<String, dynamic> drawPdfPage(
    ProjectModel projectModel,
    ExportSizeModel exportSize,
    int copyNumber,
    // ui.Image imageData,
    double dpi,
  ) {
    /// Tờ giấy đổi sang pixel, có sử dụng dpi kèm theo
    double paperWidthByPoint = FlutterConvert.convertUnit(
      exportSize.unit,
      POINT,
      exportSize.size.width,
    );

    double paperHeightByPoint = FlutterConvert.convertUnit(
      exportSize.unit,
      POINT,
      exportSize.size.height,
    );

    Size paperSizeByPoint = Size(paperWidthByPoint, paperHeightByPoint);

    EdgeInsets margin = exportSize.marginModel.toEdgeInsetsBy();

    double leftByPoint = FlutterConvert.convertUnit(POINT, POINT, margin.left);
    double topByPoint = FlutterConvert.convertUnit(POINT, POINT, margin.top);
    double rightByPoint = FlutterConvert.convertUnit(
      POINT,
      POINT,
      margin.right,
    );
    double bottomByPoint = FlutterConvert.convertUnit(
      POINT,
      POINT,
      margin.bottom,
    );

    margin = EdgeInsets.fromLTRB(
      leftByPoint,
      topByPoint,
      rightByPoint,
      bottomByPoint,
    );
    //
    double spacingHorizontalByPoint = FlutterConvert.convertUnit(
      POINT,
      POINT,
      exportSize.spacingHorizontal,
    );

    double spacingVerticalByPoint = FlutterConvert.convertUnit(
      POINT,
      POINT,
      exportSize.spacingVertical,
    );
    Size passportSizeByPoint;
    var currentPassport = projectModel.countryModel!.currentPassport;
    if (currentPassport.unit == PIXEL) {
      passportSizeByPoint = Size(
        currentPassport.width / dpi * 72,
        currentPassport.height / dpi * 72,
      );
    } else {
      passportSizeByPoint = Size(
        FlutterConvert.convertUnit(
          currentPassport.unit,
          POINT,
          currentPassport.width,
        ),
        FlutterConvert.convertUnit(
          currentPassport.unit,
          POINT,
          currentPassport.height,
        ),
      );
    }
    consolelog("passportSizeByPointpassportSizeByPoint = $passportSizeByPoint");

    // giới hạn kích thước passportWidthByPoint ảnh
    Size aroundAvailableSize = paperSizeByPoint.copyWith(
      width: paperSizeByPoint.width - margin.left - margin.right,
      height: paperSizeByPoint.height - margin.top - margin.bottom,
    );

    Size passportSizeLimitedByPoint = passportSizeByPoint;

    int countImageOn1Row = max(
      1,
      (aroundAvailableSize.width) ~/ passportSizeLimitedByPoint.width,
    );

    int countRowOn1Page = max(
      1,
      (aroundAvailableSize.height) ~/ passportSizeLimitedByPoint.height,
    );
    consolelog(
      "passportSizeLimitedByPoint: $passportSizeLimitedByPoint, countImageOn1Row = $countImageOn1Row, countRowOn1Page = $countRowOn1Page, margin = $margin",
    );

    int countImageMaxOn1Page = countRowOn1Page * countImageOn1Row;

    int countPage = (copyNumber / countImageMaxOn1Page).ceil();
    consolelog(
      "passportSizeLimitedByPoint:  $passportSizeLimitedByPoint, margin = $margin, countImageOn1Row = $countImageOn1Row, countRowOn1Page = $countRowOn1Page, countImageMaxOn1Page = $countImageMaxOn1Page, countPage = $countPage",
    );

    // List<ui.Image> listResult = [];
    // for (var i = 0; i < countPage; i++) {
    //   int countImageNeedDraw = countImageMaxOn1Page;
    //   if (i >= countPage - 1) {
    //     countImageNeedDraw =
    //         copyNumber - countImageMaxOn1Page * (countPage - 1);
    //   }
    //   ui.Image result = _generateSinglePdfPage(
    //     imageData: imageData,
    //     paperSizeByPoint: paperSizeByPoint,
    //     passportSizeByPoint: passportSizeLimitedByPoint,
    //     countImageNeedDraw: countImageNeedDraw,
    //     countImageOn1Row: countImageOn1Row,
    //     countRow: countRowOn1Page,
    //     spacingHorizontalByPoint: spacingHorizontalByPoint,
    //     spacingVerticalByPoint: spacingVerticalByPoint,
    //     margin: margin,
    //   );
    //   listResult.add(result);
    // }
    return {
      // "listUiPdfImage": listResult,
      "paperSizeByPoint": paperSizeByPoint,
      "passportSizeByPoint": passportSizeLimitedByPoint,
      "spacingHorizontalByPoint": spacingHorizontalByPoint,
      "spacingVerticalByPoint": spacingVerticalByPoint,
      "marginByPoint": margin,
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
    required double spacingHorizontalByPixel,
    required double spacingVerticalByPixel,
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

    canvas.drawRect(
      Rect.fromLTWH(0, 0, paperSizeByPixel.width, paperSizeByPixel.height),
      Paint()..color = white,
    );

    // tinh phan thua de can giua cac passport
    double tong_do_dai_can_ve =
        countColumnIn1Page *
        (spacingHorizontalByPixel + passportSizeByPixel.width);
    double deltaWidthToAlignCenter = max(
      0,
      (paperSizeByPixel.width - margin.left * 2 - tong_do_dai_can_ve) / 2,
    );

    for (var indexRow = 0; indexRow < countRowIn1Page; indexRow++) {
      for (
        var indexColumn = 0;
        indexColumn < countColumnIn1Page;
        indexColumn++
      ) {
        double marginLeft =
            margin.left +
            passportSizeByPixel.width * indexColumn +
            spacingHorizontalByPixel * (indexColumn + 1) +
            deltaWidthToAlignCenter;
        double marginTop =
            margin.top +
            passportSizeByPixel.height * indexRow +
            spacingVerticalByPixel * (indexRow + 1);
        // Nếu là item là item có số thứ tự lớn hơn tổng số ảnh cần vẽ -> vẽ ra những item trong suốt

        bool isOverCountImageNeedDraw =
            indexPage * countColumnIn1Page * countRowIn1Page +
                indexRow * indexColumn +
                (indexColumn + 1) >
            countImageNeedDraw;
        if (isOverCountImageNeedDraw) {
          canvas.drawRect(
            Rect.fromLTWH(
              marginLeft,
              marginTop,
              passportSizeByPixel.width,
              passportSizeByPixel.height,
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
              passportSizeByPixel.width,
              passportSizeByPixel.height,
            ),
            Paint(),
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
      0,
      (paperSizeByPoint.width - margin.left * 2 - tong_do_dai_can_ve) / 2,
    );

    for (var y = 0; y < row; y++) {
      for (var i = 0; i < column; i++) {
        double marginLeft =
            margin.left +
            passportSizeByPoint.width * i +
            spacingHorizontalByPoint * (i + 1) +
            deltaWidthToAlignCenter;
        double marginTop =
            margin.top +
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
