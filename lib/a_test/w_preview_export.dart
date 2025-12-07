import 'dart:math';
// import 'package:color_picker_android/widgets/w_text_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/helpers/convert.dart';
import 'package:pass1_/helpers/fill_image_on_pdf.dart';
import 'package:pass1_/helpers/log_custom.dart';
import 'package:pass1_/models/export_size_model.dart';
import 'package:pass1_/models/project_model.dart';

class WPreviewExport extends StatelessWidget {
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

  double get dpi => valueResolutionDpi;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cons) {
        /// Kích thước hiển thị trên màn hình
        var maxSize = Size(cons.maxWidth * 0.95, cons.maxHeight * 0.95);
        var currentPassport = projectModel.countryModel!.currentPassport;
        ExportSizeModel exportModel = exportSize;

        /// Phần padding bên trong tờ giấy ( viền tờ giấy ) tại đơn vị mà user chỉ định
        EdgeInsets marginCurrentUnit = exportModel.marginModel
            .toEdgeInsetsByCurrentUnit();

        double leftByPixelPoint;
        double topByPixelPoint;
        double rightByPixelPoint;
        double bottomByPixelPoint;

        double spacingHorizontalByPixelPoint;
        double spacingVerticalByPixelPoint;

        double paperWidthByPixelPoint;
        double paperHeightByPixelPoint;

        var exportUnit = exportModel.unit;

        /// Nếu là PIXEL thì giữ nguyên kích thước vẽ
        /// Còn lại: đổi sang inch x dpi => điểm vẽ
        if (exportUnit == PIXEL) {
          leftByPixelPoint = marginCurrentUnit.left;
          topByPixelPoint = marginCurrentUnit.top;
          rightByPixelPoint = marginCurrentUnit.right;
          bottomByPixelPoint = marginCurrentUnit.bottom;

          spacingHorizontalByPixelPoint = exportModel.spacingHorizontal;
          spacingVerticalByPixelPoint = exportModel.spacingVertical;

          paperWidthByPixelPoint = exportModel.width;
          paperHeightByPixelPoint = exportModel.height;
        } else {
          leftByPixelPoint =
              FlutterConvert.convertUnit(
                exportUnit,
                INCH,
                marginCurrentUnit.left,
              ) *
              dpi;
          topByPixelPoint =
              FlutterConvert.convertUnit(
                exportUnit,
                INCH,
                marginCurrentUnit.top,
              ) *
              dpi;
          rightByPixelPoint =
              FlutterConvert.convertUnit(
                exportUnit,
                INCH,
                marginCurrentUnit.right,
              ) *
              dpi;
          bottomByPixelPoint =
              FlutterConvert.convertUnit(
                exportUnit,
                INCH,
                marginCurrentUnit.bottom,
              ) *
              dpi;
          spacingHorizontalByPixelPoint =
              FlutterConvert.convertUnit(
                exportUnit,
                INCH,
                exportModel.spacingHorizontal,
              ) *
              dpi;
          spacingVerticalByPixelPoint =
              FlutterConvert.convertUnit(
                exportUnit,
                INCH,
                exportModel.spacingVertical,
              ) *
              dpi;
          paperWidthByPixelPoint =
              FlutterConvert.convertUnit(exportUnit, INCH, exportModel.width) *
              dpi;
          paperHeightByPixelPoint =
              FlutterConvert.convertUnit(
                exportUnit,
                INCH,
                exportModel.size.height,
              ) *
              dpi;
        }

        EdgeInsets marginByPixelPoint = EdgeInsets.fromLTRB(
          leftByPixelPoint,
          topByPixelPoint,
          rightByPixelPoint,
          bottomByPixelPoint,
        );

        // chuyển đơn vị của passport sang điểm vẽ
        double passportWidthByPixelPoint, passportHeightByPixelPoint;

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

        /// Không gian sẵn sàng để vẽ theo pixel
        Size aroundSizeByPixelPoint = Size(
          paperWidthByPixelPoint -
              exportModel.marginModel.mLeft -
              exportModel.marginModel.mRight,
          paperHeightByPixelPoint -
              exportModel.marginModel.mTop -
              exportModel.marginModel.mBottom,
        );

        /// Giới hạn kích thước ảnh bên trong khu vực sẵn sàng để vẽ
        Size passportSizeByPixelPoint = Size(
          passportWidthByPixelPoint,
          passportHeightByPixelPoint,
        );
        Size passportSizeByPixelPointLimited = getLimitImageInPaper(
          aroundSizeByPixelPoint,
          passportSizeByPixelPoint,
          isKeepSizeWhenSmall: true,
        );

        /// Chuyển paper sang kich thước hiển thị
        Size paperSizeByPixelPoint = Size(
          paperWidthByPixelPoint,
          paperHeightByPixelPoint,
        );
        Size paperSizePreviewByPixelPointLimited = getLimitImageInPaper(
          maxSize,
          paperSizeByPixelPoint,
          isKeepSizeWhenSmall: false,
        );

        /// Tinhs scale từ kích thước paper in thật vs kích thước hiển thị trên giấy ( cùng đơn vị PIXEL )
        double ratioConvertToOriginalWidth =
            paperSizePreviewByPixelPointLimited.width / paperWidthByPixelPoint;
        double ratioConvertToOriginalHeight =
            paperSizePreviewByPixelPointLimited.height /
            paperHeightByPixelPoint;

        /// Scale những thuộc tính vệ tinh khác theo paper
        double passportWidthByPixelPointLimitedScaled =
            passportSizeByPixelPointLimited.width * ratioConvertToOriginalWidth;
        double passportHeightByPixelPointLimitedScaled =
            passportSizeByPixelPointLimited.height *
            ratioConvertToOriginalHeight;

        EdgeInsets marginByPixelPointScaled = EdgeInsets.fromLTRB(
          marginByPixelPoint.left * ratioConvertToOriginalWidth,
          marginByPixelPoint.top * ratioConvertToOriginalHeight,
          marginByPixelPoint.right * ratioConvertToOriginalWidth,
          marginByPixelPoint.bottom * ratioConvertToOriginalHeight,
        );

        double spacingHorizontalByPixelPointScaled =
            spacingHorizontalByPixelPoint * ratioConvertToOriginalWidth;
        double spacingVerticalByPixelPointScaled =
            spacingVerticalByPixelPoint * ratioConvertToOriginalWidth;

        Size passportSizeByPixelPointLimitedScaled = Size(
          passportWidthByPixelPointLimitedScaled,
          passportHeightByPixelPointLimitedScaled,
        );
        consolelog(
          "WPreviewExport passportSizeByPixelPoint 111: = $passportSizeByPixelPoint, passportSizeByPixelPointLimited = $passportSizeByPixelPointLimited, passportSizeByPixelPointLimitedScaled = $passportSizeByPixelPointLimitedScaled",
        );

        consolelog(
          "WPreviewExport paperSizeByPixelPoint 123: = $paperSizeByPixelPoint, paperSizePreviewByPixelPointLimited = $paperSizePreviewByPixelPointLimited",
        );
        consolelog(
          "WPreviewExport marginByPixelPoint = $marginByPixelPoint, marginByPixelPointScaled = $marginByPixelPointScaled",
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
            paperSizeByPixel: paperSizePreviewByPixelPointLimited,
            passportSizeByPixel: passportSizeByPixelPointLimitedScaled,
            margin: marginByPixelPointScaled,
            spacingVertical: spacingVerticalByPixelPointScaled,
            spacingHorizontal: spacingHorizontalByPixelPointScaled,
          ),
        );
      },
    );
  }

  Widget _buildScrollPreview({
    required Size paperSizeByPixel,
    required Size passportSizeByPixel,
    required EdgeInsets margin,
    required double spacingVertical,
    required double spacingHorizontal,
  }) {
    double availableWidth = paperSizeByPixel.width - margin.left - margin.right;
    double availableHeight =
        paperSizeByPixel.height - margin.left - margin.right;
    int countColumn = max(1, availableWidth ~/ passportSizeByPixel.width);

    int countRow = max(1, availableHeight ~/ passportSizeByPixel.height);

    int countImageIn1Page = (countColumn * countRow);

    int countPage = (copyNumber / countImageIn1Page).ceil();
    consolelog(
      "marginmargin: paperSizeByPixel = $paperSizeByPixel, passportSizeByPixel = $passportSizeByPixel",
    );
    return Container(
      width: paperSizeByPixel.width,
      height: paperSizeByPixel.height,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(countPage, (indexPage) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: Stack(
                  children: [
                    Container(
                      color: white,
                      width: paperSizeByPixel.width,
                      height: paperSizeByPixel.height,
                      padding: margin,
                      alignment: Alignment.topCenter,
                      child: Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(color: transparent),
                        child: Wrap(
                          clipBehavior: Clip.hardEdge,
                          spacing: spacingHorizontal,
                          runSpacing: spacingVertical,
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: List.generate(countImageIn1Page, (
                            indexImageInPage,
                          ) {
                            if ((indexImageInPage + 1) +
                                    indexPage * countImageIn1Page >
                                copyNumber) {
                              return Container(
                                width: passportSizeByPixel.width,
                                height: passportSizeByPixel.height,
                                color: transparent,
                              );
                            }

                            return Container(
                              // color: black,
                              width: passportSizeByPixel.width,
                              height: passportSizeByPixel.height,
                              alignment: Alignment.topCenter,
                              child: _buildImage(passportSizeByPixel),
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
                    // Positioned(
                    //   left: 10,
                    //   bottom: 10,
                    //   child: Stack(
                    //     alignment: Alignment.center,
                    //     children: [
                    //       Container(
                    //         width: 20,
                    //         height: 20,
                    //         decoration: BoxDecoration(
                    //           borderRadius: BorderRadius.circular(999),
                    //         ),
                    //       ),
                    //       Container(
                    //         width: 18,
                    //         height: 18,
                    //         decoration: BoxDecoration(
                    //           color: white,
                    //           borderRadius: BorderRadius.circular(999),
                    //         ),
                    //         child: Center(
                    //           child: WTextContent(
                    //             value: "${indexPage + 1}",
                    //             textColor: black,
                    //             textSize: 8,
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(Size passportSizeByPixel) {
    if (projectModel.scaledCroppedImage != null) {
      return RawImage(
        image: projectModel.scaledCroppedImage!,
        // width: passportSizeByPixel.width,
        // height: passportSizeByPixel.height,
        // fit: BoxFit.cover,
      );
    } else {
      if (projectModel.croppedFile != null) {
        return Image.memory(
          projectModel.croppedFile!.readAsBytesSync(),
          // width: passportSizeByPixel.width,
          // height: passportSizeByPixel.height,
          // fit: BoxFit.cover,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            return child;
          },
        );
      } else {
        return RawImage(
          image: projectModel.uiImageAdjusted!,
          // width: passportSizeByPixel.width,
          // height: passportSizeByPixel.height,
          // fit: BoxFit.cover,
        );
      }
    }
  }
}
