import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gpu_filters_interface/flutter_gpu_filters_interface.dart';
import 'package:passport_photo_2/a_test/w_export_childs.dart';
import 'package:passport_photo_2/commons/colors.dart';
import 'package:passport_photo_2/commons/constants.dart';
import 'package:passport_photo_2/helpers/convert.dart';
import 'package:passport_photo_2/helpers/fill_image_on_pdf.dart';
import 'package:passport_photo_2/helpers/log_custom.dart';
import 'package:passport_photo_2/models/export_size_model.dart';
import 'package:passport_photo_2/models/project_model.dart';

class WPreviewExport extends StatefulWidget {
  final ProjectModel projectModel;
  final ExportSizeModel exportSize;
  final int copyNumber;
  final double valueResolutionDpi;
  const WPreviewExport({
    super.key,
    required this.projectModel,
    required this.exportSize,
    required this.copyNumber,
    required this.valueResolutionDpi,
  });

  @override
  State<WPreviewExport> createState() => _WPreviewExportState();
}

class _WPreviewExportState extends State<WPreviewExport> {
  late Widget imageData;

  @override
  void initState() {
    imageData = WExports.buildImagePreview(widget.projectModel);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cons) {
        var maxSize = Size(cons.maxWidth * 0.95, cons.maxHeight * 0.95);
        var currentPassport = widget.projectModel.countryModel!.currentPassport;
        var exportModel = widget.exportSize;

        EdgeInsets margin = exportModel.marginModel.toEdgeInsets();

        double left = FlutterConvert.convertUnit(POINT, POINT, margin.left);
        double top = FlutterConvert.convertUnit(POINT, POINT, margin.top);
        double right = FlutterConvert.convertUnit(POINT, POINT, margin.right);
        double bottom = FlutterConvert.convertUnit(POINT, POINT, margin.bottom);

        margin = EdgeInsets.fromLTRB(left, top, right, bottom);

        double spacingHorizontal = FlutterConvert.convertUnit(
            POINT, POINT, exportModel.spacingHorizontal);
        double spacingVertical = FlutterConvert.convertUnit(
            POINT, POINT, exportModel.spacingVertical);

        // chuyển đơn vị của paper
        double paperWidthConverted = FlutterConvert.convertUnit(
            exportModel.unit, POINT, exportModel.size.width);
        double paperHeightConverted = FlutterConvert.convertUnit(
            exportModel.unit, POINT, exportModel.size.height);
        Size paperSizeConverted =
            Size(paperWidthConverted, paperHeightConverted);

        // chuyển đơn vị của passport
        double passportWidthConverted, passportHeightConverted;

        if (currentPassport.unit == PIXEL) {
          passportWidthConverted =
              currentPassport.width / widget.valueResolutionDpi * 72;
          passportHeightConverted =
              currentPassport.height / widget.valueResolutionDpi * 72;
        } else {
          passportWidthConverted = FlutterConvert.convertUnit(
              currentPassport.unit, POINT, currentPassport.width);
          passportHeightConverted = FlutterConvert.convertUnit(
              currentPassport.unit, POINT, currentPassport.height);
        }

        Size passportSizeConverted =
            Size(passportWidthConverted, passportHeightConverted);

        Size aroundSize = paperSizeConverted.copyWith(
          width: paperSizeConverted.width -
              exportModel.marginModel.mLeft -
              exportModel.marginModel.mRight,
          height: paperSizeConverted.height -
              exportModel.marginModel.mTop -
              exportModel.marginModel.mBottom,
        );
        // zoom nho lai khi passport > paper
        Size passportSizeLimited = getLimitImageInPaper(
          aroundSize,
          passportSizeConverted,
          isKeepSizeWhenSmall: true,
        );

        // Chuyển paper sang kich thước hiển thị
        Size paperSizePreview = getLimitImageInPaper(
          maxSize,
          paperSizeConverted,
          isKeepSizeWhenSmall: false,
        );
        double ratioConvertToOriginalWidth =
            paperSizePreview.width / paperSizeConverted.width;
        double ratioConvertToOriginalHeight =
            paperSizePreview.height / paperSizeConverted.height;

        double passportZoomWidth =
            passportSizeLimited.width * ratioConvertToOriginalWidth;
        double passportZoomHeight =
            passportSizeLimited.height * ratioConvertToOriginalHeight;

        margin = EdgeInsets.fromLTRB(
          margin.left * ratioConvertToOriginalWidth,
          margin.top * ratioConvertToOriginalHeight,
          margin.right * ratioConvertToOriginalWidth,
          margin.bottom * ratioConvertToOriginalHeight,
        );

        spacingHorizontal = spacingHorizontal * ratioConvertToOriginalWidth;
        spacingVertical = spacingVertical * ratioConvertToOriginalWidth;

        Size passportSizePreview = Size(passportZoomWidth, passportZoomHeight);

        // consolelog("WPreviewExport margin: $margin");

        consolelog(
            "WPreviewExport Paper: $paperSizeConverted - $paperSizePreview ");

        consolelog(
            "WPreviewExport Passport: $passportSizeConverted - $passportSizePreview");

        return Container(
          decoration: const BoxDecoration(
              // boxShadow: [
              //   BoxShadow(
              //     color: Color.fromRGBO(0, 0, 0, 0.1),
              //     offset: Offset(0, 0),
              //     blurRadius: 40,
              //     spreadRadius: -30,
              //   )
              // ],
              ),
          width: maxSize.width,
          height: maxSize.height,
          child: _buildScrollPreview(
            paperSizePreview,
            passportSizePreview,
            margin,
            spacingVertical,
            spacingHorizontal,
          ),
        );
      },
    );
  }

  Widget _buildScrollPreview(
    Size paperSize,
    Size passportSizePreview,
    EdgeInsets margin,
    double spacingVertical,
    double spacingHorizontal,
  ) {
    int so_anh_trong_1_dong = max(
        1,
        (paperSize.width - margin.left - margin.right) ~/
            passportSizePreview.width);

    int so_dong_trong_1_trang = max(
        1,
        (paperSize.height - margin.top - margin.bottom) ~/
            passportSizePreview.height);

    int so_luong_lon_nhat_anh_moi_trang =
        (so_anh_trong_1_dong * so_dong_trong_1_trang);

    int so_trang = (widget.copyNumber / so_luong_lon_nhat_anh_moi_trang).ceil();

    consolelog(
        "so_trang  $so_anh_trong_1_dong - $so_dong_trong_1_trang - $so_trang");

    return Container(
      width: paperSize.width,
      height: paperSize.height,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(so_trang, (index) {
              int so_luong_anh_moi_to_giay = so_luong_lon_nhat_anh_moi_trang;
              if (index + 1 >= so_trang) {
                so_luong_anh_moi_to_giay = widget.copyNumber -
                    (so_trang - 1) * so_luong_lon_nhat_anh_moi_trang;
              }
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: _buildPaper(
                  paperSize,
                  passportSizePreview,
                  so_luong_anh_moi_to_giay,
                  so_anh_trong_1_dong,
                  margin,
                  spacingVertical,
                  spacingHorizontal,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildPaper(
    Size paperSizePreview,
    Size passportSizePreview,
    int countImage,
    int countImageOn1Row,
    EdgeInsets margin,
    double spacingVertical,
    double spacingHorizontal,
  ) {
    return Container(
      color: white,
      width: paperSizePreview.width,
      height: paperSizePreview.height,
      padding: margin,
      alignment: Alignment.topCenter,
      child: _buildWrapView(
        countImageOn1Row,
        passportSizePreview,
        countImage,
        spacingVertical,
        spacingHorizontal,
      ),
    );
  }

  Widget _buildWrapView(
    int countImageOn1Row,
    Size passportSizePreview,
    int countImageNeedDraw,
    double spacingVertical,
    double spacingHorizontal,
  ) {
    int so_anh_can_ve = max(countImageOn1Row, countImageNeedDraw);

    return Wrap(
      spacing: spacingHorizontal,
      runSpacing: spacingVertical,
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: List.generate(
        so_anh_can_ve,
        (index) {
          if (index > countImageNeedDraw - 1) {
            return Container(
              width: passportSizePreview.width,
              height: passportSizePreview.height,
              color: transparent,
            );
          }

          return Container(
            color: transparent,
            width: passportSizePreview.width,
            height: passportSizePreview.height,
            child: imageData,
          );

          // Image.memory(
          //   widget.projectModel.croppedFile!.readAsBytesSync(),
          // width: passportSizePreview.width,
          // height: passportSizePreview.height,
          //   fit: BoxFit.cover,
          // );
        },
      ),
    );
  }
}
