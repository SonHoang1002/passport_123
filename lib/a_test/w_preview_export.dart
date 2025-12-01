import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gpu_filters_interface/flutter_gpu_filters_interface.dart';
import 'package:pass1_/a_test/w_export_childs.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/helpers/convert.dart';
import 'package:pass1_/helpers/fill_image_on_pdf.dart';
import 'package:pass1_/helpers/log_custom.dart';
import 'package:pass1_/models/export_size_model.dart';
import 'package:pass1_/models/project_model.dart';

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
        ExportSizeModel exportModel = widget.exportSize;

        EdgeInsets margin = exportModel.marginModel.toEdgeInsetsBy();

        double left = FlutterConvert.convertUnit(POINT, POINT, margin.left);
        double top = FlutterConvert.convertUnit(POINT, POINT, margin.top);
        double right = FlutterConvert.convertUnit(POINT, POINT, margin.right);
        double bottom = FlutterConvert.convertUnit(POINT, POINT, margin.bottom);

        margin = EdgeInsets.fromLTRB(left, top, right, bottom);

        double spacingHorizontal = FlutterConvert.convertUnit(
          POINT,
          POINT,
          exportModel.spacingHorizontal,
        );
        double spacingVertical = FlutterConvert.convertUnit(
          POINT,
          POINT,
          exportModel.spacingVertical,
        );

        // chuyển đơn vị của paper
        double paperWidthByPoint = FlutterConvert.convertUnit(
          exportModel.unit,
          POINT,
          exportModel.size.width,
        );
        double paperHeightByPoint = FlutterConvert.convertUnit(
          exportModel.unit,
          POINT,
          exportModel.size.height,
        );
        Size paperSizeByPoint = Size(paperWidthByPoint, paperHeightByPoint);

        // chuyển đơn vị của passport
        double passportWidthByPoint, passportHeightByPoint;

        if (currentPassport.unit == PIXEL) {
          passportWidthByPoint =
              currentPassport.width / widget.valueResolutionDpi * 72;
          passportHeightByPoint =
              currentPassport.height / widget.valueResolutionDpi * 72;
        } else {
          passportWidthByPoint = FlutterConvert.convertUnit(
            currentPassport.unit,
            POINT,
            currentPassport.width,
          );
          passportHeightByPoint = FlutterConvert.convertUnit(
            currentPassport.unit,
            POINT,
            currentPassport.height,
          );
        }

        Size passportSizeByPoint = Size(
          passportWidthByPoint,
          passportHeightByPoint,
        );

        Size aroundSizeByPoint = paperSizeByPoint.copyWith(
          width:
              paperSizeByPoint.width -
              exportModel.marginModel.mLeft -
              exportModel.marginModel.mRight,
          height:
              paperSizeByPoint.height -
              exportModel.marginModel.mTop -
              exportModel.marginModel.mBottom,
        );
        // zoom nho lai khi passport > paper
        Size passportSizeLimited = getLimitImageInPaper(
          aroundSizeByPoint,
          passportSizeByPoint,
          isKeepSizeWhenSmall: true,
        );

        // Chuyển paper sang kich thước hiển thị
        Size paperSizeLimitedByPoint = getLimitImageInPaper(
          maxSize,
          paperSizeByPoint,
          isKeepSizeWhenSmall: false,
        );
        double ratioConvertToOriginalWidth =
            paperSizeLimitedByPoint.width / paperSizeByPoint.width;
        double ratioConvertToOriginalHeight =
            paperSizeLimitedByPoint.height / paperSizeByPoint.height;

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

        consolelog(
          "WPreviewExport exportModel: $exportModel, spacingHorizontal = $spacingHorizontal",
        );

        return Container(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.1),
                offset: Offset(0, 0),
                blurRadius: 40,
                spreadRadius: -30,
              ),
            ],
          ),
          width: maxSize.width,
          height: maxSize.height,
          child: _buildScrollPreview(
            paperSizeLimitedByPoint,
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
    Size passportSizeLimitedByPoint,
    EdgeInsets margin,
    double spacingVertical,
    double spacingHorizontal,
  ) {
    double availableWidth = paperSize.width - margin.left - margin.right;
    double availableHeight = paperSize.height - margin.left - margin.right;
    int countImageIn1Row = max(
      1,
      availableWidth ~/ passportSizeLimitedByPoint.width,
    );

    int countRowIn1Page = max(
      1,
      availableHeight ~/ passportSizeLimitedByPoint.height,
    );

    int countImageIn1Page = (countImageIn1Row * countRowIn1Page);

    int countPage = (widget.copyNumber / countImageIn1Page).ceil();
    return Container(
      width: paperSize.width,
      height: paperSize.height,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(countPage, (indexPage) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: Container(
                  color: white,
                  width: paperSize.width,
                  height: paperSize.height,
                  padding: margin,
                  alignment: Alignment.topCenter,
                  child: Container(
                    color: red,
                    child: Wrap(
                      spacing: spacingHorizontal,
                      runSpacing: spacingVertical,
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: List.generate(countImageIn1Page, (
                        indexImageInPage,
                      ) {
                        if ((indexImageInPage + 1) +
                                indexPage * countImageIn1Page >
                            widget.copyNumber) {
                          return Container(
                            width: passportSizeLimitedByPoint.width,
                            height: passportSizeLimitedByPoint.height,
                            color: transparent,
                          );
                        }

                        return Container(
                          color: transparent,
                          width: passportSizeLimitedByPoint.width,
                          height: passportSizeLimitedByPoint.height,
                          alignment: Alignment.center,
                          child: imageData,
                        );

                        // Image.memory(
                        //   widget.projectModel.croppedFile!.readAsBytesSync(),
                        // width: passportSizePreview.width,
                        // height: passportSizePreview.height,
                        //   fit: BoxFit.cover,
                        // );
                      }),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
