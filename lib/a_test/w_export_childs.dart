import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass1_/a_test/size_helpers.dart';
import 'package:pass1_/a_test/w_preview_export.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/commons/extension.dart';
import 'package:pass1_/helpers/convert.dart';
import 'package:pass1_/helpers/log_custom.dart';
import 'package:pass1_/models/country_passport_model.dart';
import 'package:pass1_/models/export_size_model.dart';
import 'package:pass1_/models/project_model.dart';
import 'package:pass1_/providers/blocs/theme_bloc.dart';
import 'package:pass1_/screens/module_home/helpers/export_helpers.dart';
import 'package:pass1_/widgets/general_dialog/w_body_dialogs.dart';
import 'package:pass1_/widgets/w_button.dart';
import 'package:pass1_/widgets/w_segment_custom.dart';
import 'package:pass1_/widgets/w_spacer.dart';
import 'package:pass1_/widgets/w_text.dart';

class WExports {
  static Widget buildBlurBackground(double height, Color? color) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(color: color ?? red.withValues(alpha: 0.2)),
        ),
      ),
    );
  }

  static Widget buildSegments({
    required BuildContext context,
    required int indexSelectedSegment,
    required void Function(int value, int prev) onSegmentChange,
    required bool isPhone,
  }) {
    return SizedBox(
      width: 300,
      height: 36,
      child: buildSegmentControl(
        context: context,
        groupValue: indexSelectedSegment,
        listSegment: EXPORT_SEGMENT_OBJECT,
        onValueChanged: (value) {
          onSegmentChange(value!, indexSelectedSegment);
        },
        unactiveTextColor: Theme.of(context).textTheme.displayMedium!.color,
        borderRadius: 12,
      ),
    );
  }

  static Widget buildPreview({
    required BuildContext context,
    required int indexSelectedSegment,
    required Size screenSize,
    required ProjectModel projectModel,
    required ExportSizeModel exportSize,
    required int copyNumber,
    required double valueResolutionDpi,
  }) {
    final initFrame = screenSize.height <= MIN_SIZE.height
        ? const Size(220, 220)
        : const Size(280, 280);
    double newWidth = initFrame.width;
    double newHeight = initFrame.height;
    final currentPassport = projectModel.countryModel!.currentPassport;
    double frameWidth = currentPassport.width;
    double frameHeight = currentPassport.height;
    final ratioWH = frameWidth / frameHeight;
    if (frameHeight != 0) {
      if (ratioWH > 1) {
        // w > h
        newHeight = newHeight * (1 / ratioWH);
      } else if (ratioWH < 1) {
        // w < h
        newWidth = newWidth * ratioWH;
      }
    }
    Size frameSize = Size(newWidth, newHeight);
    return Container(
      constraints: const BoxConstraints(minHeight: 100, minWidth: 100),
      width: frameSize.width,
      height: frameSize.height,
      child: indexSelectedSegment == 0
          ? buildImagePreview(projectModel)
          : WPreviewExport(
              projectModel: projectModel,
              exportSize: exportSize,
              copyNumber: copyNumber,
              valueResolutionDpi: valueResolutionDpi,
            ),
    );
  }

  static Widget buildImagePreview(ProjectModel projectModel) {
    if (projectModel.scaledCroppedImage != null) {
      return RawImage(image: projectModel.scaledCroppedImage!);
    } else {
      if (projectModel.croppedFile != null) {
        return Image.memory(
          projectModel.croppedFile!.readAsBytesSync(),
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            return child;
          },
        );
      } else {
        return RawImage(image: projectModel.uiImageAdjusted!);
      }
    }
  }

  static Widget buildFormats({
    required BuildContext context,
    required Size screenSize,
    required int indexSelectedSegment,
    required ProjectModel projectModel,
    required List<GlobalKey> keysFormat,
    required int copyNumber,
    required ExportSizeModel exportSize,
    required int compressionPercent,
    required int indexImageFormat,
    required int indexDpiFormat,
    required double dpiResolution,
    required int? indexFocusingFormat, // check xem dang focus vao item nao
    required Map<int, String> dataSegmentResolution,
    required List<double> listMinMaxDpi,
    required bool isDisableDpiFormat,
    required void Function(int? index) onTapFormat,
    void Function(int value)? onChangeCopy,
    void Function(ExportSizeModel value)? onChangeSizeFormat,
    void Function(int percent)? onChangeCompressionPercent,
    void Function(int index)? onChangeImageFormat, //index segment
    void Function(int percent)? onCompressionEnd,
    void Function(int index)? onChangeDpiFormat, //index segment
    void Function(double dpi)? onChangeDPIResolution,
    void Function(double dpi)? onChangeDPIResolutionEnd,
  }) {
    consolelog("screenSize.width ${screenSize.width}");
    bool isDarkMode = BlocProvider.of<ThemeBloc>(
      context,
      listen: true,
    ).isDarkMode;
    Color bgColor = !isDarkMode ? white05 : black05;
    Color disableColor = isDarkMode ? white05 : black05;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      width: screenSize.width,
      child: Column(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: indexSelectedSegment == 1 ? 1 : 0,
            child: Flex(
              direction: Axis.horizontal,
              children: [
                Flexible(
                  child: _buildFormatItem(
                    key: keysFormat[0],
                    context: context,
                    bgColor: bgColor,
                    title: "Copies: $copyNumber",
                    isFocus: indexFocusingFormat == 0,
                    isDisable: false,
                    onTap: () {
                      if (indexSelectedSegment == 0) return;
                      onTapFormat(0);
                      // change copies
                      ExportHelpers.onChangeCopyCount(
                        context: context,
                        keyCopy: keysFormat[0],
                        copyNumber: copyNumber,
                        onChangeCopyCount: (int count) {
                          if (onChangeCopy != null) {
                            onChangeCopy(count);
                          }
                          onTapFormat(null);
                        },
                        onTapOutside: () {
                          onTapFormat(null);
                        },
                      );
                    },
                  ),
                ),
                WSpacer(width: 10),
                Flexible(
                  child: _buildFormatItem(
                    key: keysFormat[1],
                    context: context,
                    bgColor: bgColor,
                    isFocus: indexFocusingFormat == 1,
                    title: "Size: ${ExportHelpers.getPreviewSize(exportSize)}",
                    isDisable: false,
                    onTap: () {
                      if (indexSelectedSegment == 0) return;
                      onTapFormat(1);
                      ExportHelpers.onChangeSize(
                        context: context,
                        keySize: keysFormat[1],
                        currentExportSize: exportSize,
                        onChangeSize: (size) {
                          if (onChangeSizeFormat != null) {
                            onChangeSizeFormat(size);
                          }
                          // onCaculateFileSize();
                          onTapFormat(null);
                        },
                        onTapOutside: () {
                          onTapFormat(null);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          WSpacer(height: 10),
          Flex(
            direction: Axis.horizontal,
            children: [
              Flexible(
                child: Builder(
                  builder: (context) {
                    String title =
                        "${EXPORT_SEGMENT_COMPRESSION_IMAGE_FORMAT[indexImageFormat]}: ${compressionPercent.toStringAsFixed(0)}%";
                    if (indexImageFormat == 1) {
                      title = "PNG";
                    }
                    return _buildFormatItem(
                      key: keysFormat[2],
                      context: context,
                      bgColor: bgColor,
                      isFocus: indexFocusingFormat == 2,
                      title: title,
                      isDisable: false,
                      onTap: () {
                        onTapFormat(2);
                        // change compression
                        ExportHelpers.onChangeCompression(
                          context: context,
                          key: keysFormat[2],
                          onTapOutside: () {
                            onTapFormat(null);
                          },
                          currentCompression: compressionPercent,
                          currentIndexImageFormat: indexImageFormat,
                          onChangeCompression: (percent) {
                            if (onChangeCompressionPercent != null) {
                              onChangeCompressionPercent(percent);
                            }
                          },
                          onChangeImageFormat: (prevFormat, nextFormat) {
                            if (onChangeImageFormat != null) {
                              onChangeImageFormat(nextFormat);
                            }
                          },
                          onCompressionEnd: (value) {
                            if (onCompressionEnd != null) {
                              onCompressionEnd(value);
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              WSpacer(width: 10),
              Flexible(
                child: _buildFormatItem(
                  key: keysFormat[3],
                  context: context,
                  bgColor: bgColor,
                  isFocus: indexFocusingFormat == 3,
                  title:
                      "DPI: ${dpiResolution.roundWithUnit(fractionDigits: 0)}",
                  isDisable: isDisableDpiFormat,
                  disableColor: disableColor,
                  onTap: () {
                    onTapFormat(3);
                    ExportHelpers.onChangeDPI(
                      context: context,
                      key: keysFormat[3],
                      onTapOutside: () {
                        onTapFormat(null);
                      },
                      indexImageFormat: indexImageFormat,
                      currentDpiResolution: dpiResolution,
                      currentIndexDpiFormat: indexDpiFormat,
                      listMinMaxDpi: listMinMaxDpi,
                      indexSegmentMain: indexSelectedSegment,
                      dataSegmentResolution: dataSegmentResolution,
                      onChangeDpiResolution: (dpi) {
                        if (onChangeDPIResolution != null) {
                          onChangeDPIResolution(dpi);
                        }
                      },
                      onChangeDPIResolutionEnd: (dpi) {
                        if (onChangeDPIResolutionEnd != null) {
                          onChangeDPIResolutionEnd(dpi);
                        }
                      },
                      onChangeDpiFormat: (index) {
                        if (onChangeDpiFormat != null) {
                          onChangeDpiFormat(index);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget buildButtons({
    required BuildContext context,
    required Size screenSize,
    required int indexImageFormat,
    required void Function() onSaveTo,
    required void Function() onSaveToLibrary,
  }) {
    bool isDarkMode = BlocProvider.of<ThemeBloc>(
      context,
      listen: true,
    ).isDarkMode;
    bool isSmallSize = FlutterSizeHelpers.checkSizeIsSmall(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      width: screenSize.width,
      margin: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 20,
      ),
      child: Flex(
        direction: Axis.horizontal,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(
            child: WButtonFilled(
              height: 54,
              message: "Share to...",
              backgroundColor: isDarkMode ? white : black,
              textColor: isDarkMode ? black : white,
              textSize: isSmallSize ? 13 : 15,
              onPressed: () {
                onSaveTo();
              },
            ),
          ),
          WSpacer(width: 15),
          Flexible(
            child: WButtonFilled(
              height: 54,
              message:
                  indexImageFormat ==
                      EXPORT_SEGMENT_COMPRESSION_IMAGE_FORMAT.length - 1
                  ? "Save to File"
                  : "Save to Library",
              backgroundColor: isDarkMode ? primaryDark1 : primaryLight1,
              textColor: white,
              textSize: isSmallSize ? 13 : 15,
              onPressed: () {
                onSaveToLibrary();
              },
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildDialogBody({
    required BuildContext context,
    required List<String> listValue,
    required Function(String value) onSelected,
    required String selectedValue,
    String? currentValue,
    double? width,
    double? height,
    double itemHeight = 44,
    bool textAlignCenter = false,
    double? maxHeight,
  }) {
    return DialogBody(
      listItem: listValue,
      selectedValue: selectedValue,
      selectedTextColor: blue,
      dialogWidth: 188,
      itemHeight: itemHeight,
      onSelected: (value) {
        onSelected(value);
      },
      textAlignCenter: textAlignCenter,
      maxHeight: maxHeight,
    );
  }

  // child
  static Widget _buildFormatItem({
    required GlobalKey key,
    required BuildContext context,
    required Color bgColor,
    required String title,
    void Function()? onTap,
    required bool isFocus,
    required bool isDisable,
    Color? disableColor,
  }) {
    return GestureDetector(
      onTap: () {
        if (isDisable) return;
        onTap?.call();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          key: key,
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(color: bgColor),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: 8),
                      child: WTextContent(
                        value: title,
                        textOverflow: TextOverflow.ellipsis,
                        textMaxLength: 1,
                        textColor: isFocus ? blue : null,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 28,
                    color: Theme.of(context).textTheme.bodySmall!.color,
                  ),
                ],
              ),
              if (isDisable)
                Positioned.fill(
                  child: Container(color: disableColor?.withAlpha(50)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildAnalyzePaperSize(
    BuildContext context,
    CountryModel countrySelected,
    bool isDarkMode,
  ) {
    final selectedPassport = countrySelected
        .listPassportModel[countrySelected.indexSelectedPassport];
    consolelog("selectedPassport.height ${selectedPassport.height}");
    String widthString = (selectedPassport.width).roundWithUnit(
      fractionDigits: 1,
    );
    String heightString = (selectedPassport.height).roundWithUnit(
      fractionDigits: 1,
    );
    String widthDecimalAfterDot = widthString.split(".").last;
    String heightDecimalAfterDot = heightString.split(".").last;
    if (widthDecimalAfterDot == "0") {
      widthString = selectedPassport.width.toInt().toString();
    }
    if (heightDecimalAfterDot == "0") {
      heightString = selectedPassport.height.toInt().toString();
    }
    consolelog("widthString $widthString");
    String message =
        "${widthString}x$heightString${selectedPassport.unit.title}";
    return _buildText(context, isDarkMode, message);
  }

  static Widget buildAnalyzeDimension({
    required BuildContext context,
    required Size screenSize,
    // required ExportSizeModel exportSize,
    required CountryModel countrySelected,
    required double dpi, // dpi
    // required List<double> listPassportDimensionByInch,
    required bool isDarkMode,
    required int indexImageFormat,
    required int indexTab,
  }) {
    String message = "--";

    PassportModel currentPassport = countrySelected.currentPassport;
    bool isOverflowSize = ExportHelpers().checkOverFlowSize(
      screenSize,
      currentPassport,
      dpi,
    );
    consolelog("isOverflowSizeisOverflowSize = $isOverflowSize");

    if (!isOverflowSize) {
      double passportWidthByPixelWithDpi, passportHeightByPixelWithDpi;
      // Size sizeToPreviewByPixel = Size(
      //   FlutterConvert.convertUnit(
      //       currentPassport.unit, PIXEL, currentPassport.width),
      //   FlutterConvert.convertUnit(
      //       currentPassport.unit, PIXEL, currentPassport.height),
      // );
      bool isTabPhoto = indexTab == 0;
      if (isTabPhoto) {
        switch (indexImageFormat) {
          case 0: // JPG
            if (currentPassport.unit == PIXEL) {
              passportWidthByPixelWithDpi = currentPassport.width;
              passportHeightByPixelWithDpi = currentPassport.height;
            } else {
              passportWidthByPixelWithDpi =
                  FlutterConvert.convertUnit(
                    currentPassport.unit,
                    INCH,
                    currentPassport.width,
                  ) *
                  dpi;
              passportHeightByPixelWithDpi =
                  FlutterConvert.convertUnit(
                    currentPassport.unit,
                    INCH,
                    currentPassport.height,
                  ) *
                  dpi;
            }
            break;
          case 1: // PNG
            if (currentPassport.unit == PIXEL) {
              passportWidthByPixelWithDpi = currentPassport.width;
              passportHeightByPixelWithDpi = currentPassport.height;
            } else {
              passportWidthByPixelWithDpi =
                  FlutterConvert.convertUnit(
                    currentPassport.unit,
                    INCH,
                    currentPassport.width,
                  ) *
                  dpi;
              passportHeightByPixelWithDpi =
                  FlutterConvert.convertUnit(
                    currentPassport.unit,
                    INCH,
                    currentPassport.height,
                  ) *
                  dpi;
            }
            break;
          case 2: // JPG
            if (currentPassport.unit == PIXEL) {
              passportWidthByPixelWithDpi = currentPassport.width;
              passportHeightByPixelWithDpi = currentPassport.height;
            } else {
              passportWidthByPixelWithDpi =
                  FlutterConvert.convertUnit(
                    currentPassport.unit,
                    INCH,
                    currentPassport.width,
                  ) *
                  dpi;
              passportHeightByPixelWithDpi =
                  FlutterConvert.convertUnit(
                    currentPassport.unit,
                    INCH,
                    currentPassport.height,
                  ) *
                  dpi;
            }
            break;
          default:
            throw Exception("Khong ho tro");
        }
      } else {
        switch (indexImageFormat) {
          case 0: // JPG
            if (currentPassport.unit == PIXEL) {
              passportWidthByPixelWithDpi = currentPassport.width;
              passportHeightByPixelWithDpi = currentPassport.height;
            } else {
              passportWidthByPixelWithDpi =
                  FlutterConvert.convertUnit(
                    currentPassport.unit,
                    INCH,
                    currentPassport.width,
                  ) *
                  dpi;
              passportHeightByPixelWithDpi =
                  FlutterConvert.convertUnit(
                    currentPassport.unit,
                    INCH,
                    currentPassport.height,
                  ) *
                  dpi;
            }
            break;
          case 1: // PNG
            if (currentPassport.unit == PIXEL) {
              passportWidthByPixelWithDpi = currentPassport.width;
              passportHeightByPixelWithDpi = currentPassport.height;
            } else {
              passportWidthByPixelWithDpi =
                  FlutterConvert.convertUnit(
                    currentPassport.unit,
                    INCH,
                    currentPassport.width,
                  ) *
                  dpi;
              passportHeightByPixelWithDpi =
                  FlutterConvert.convertUnit(
                    currentPassport.unit,
                    INCH,
                    currentPassport.height,
                  ) *
                  dpi;
            }
            break;
          case 2: // JPG
            if (currentPassport.unit == PIXEL) {
              passportWidthByPixelWithDpi = currentPassport.width;
              passportHeightByPixelWithDpi = currentPassport.height;
            } else {
              passportWidthByPixelWithDpi =
                  FlutterConvert.convertUnit(
                    currentPassport.unit,
                    INCH,
                    currentPassport.width,
                  ) *
                  dpi;
              passportHeightByPixelWithDpi =
                  FlutterConvert.convertUnit(
                    currentPassport.unit,
                    INCH,
                    currentPassport.height,
                  ) *
                  dpi;
            }
            break;
          default:
            throw Exception("Khong ho tro");
        }
      }

      message =
          "${passportWidthByPixelWithDpi.roundWithUnit(fractionDigits: 0)}x${passportHeightByPixelWithDpi.roundWithUnit(fractionDigits: 0)}";
    } else {
      /// Ví dụ 500x600inch , dpi 600
      /// -> số print point  = 300000x360000px
      /// -> 6667x8000px -> Ảnh sẽ có kích thước như này

      double aspectRatio = currentPassport.width / currentPassport.height;

      double widthInPixelLimited, heightInPixelLimited;
      if (aspectRatio > 1) {
        widthInPixelLimited = LIMITATION_DIMENSION_BY_PIXEl;
        heightInPixelLimited = widthInPixelLimited / aspectRatio;
      } else if (aspectRatio < 1) {
        heightInPixelLimited = LIMITATION_DIMENSION_BY_PIXEl;
        widthInPixelLimited = heightInPixelLimited * aspectRatio;
      } else {
        widthInPixelLimited = heightInPixelLimited =
            LIMITATION_DIMENSION_BY_PIXEl;
      }
      message = message =
          "${widthInPixelLimited.roundWithUnit(fractionDigits: 0)}x${heightInPixelLimited.roundWithUnit(fractionDigits: 0)}";
    }
    message += "px";

    return _buildText(context, isDarkMode, message);
  }

  static Widget buildAnalyzeOutputFormat(
    BuildContext context,
    bool isDarkMode,
    String title,
  ) {
    return _buildText(context, isDarkMode, title);
  }

  static Widget buildAnalyzeFileSize({
    required BuildContext context,
    required double? fileSize,
    required Size size,
    required CountryModel countrySelected,
    required double valueResolution,
    required List<double> listPassportDimensionByInch,
    required bool isDarkMode,
  }) {
    String message = ExportHelpers.handlePreviewFileSize(
      fileSize,
      countrySelected,
      size,
      valueResolution,
      listPassportDimensionByInch,
    );
    return _buildText(context, isDarkMode, message);
  }

  static Widget buildAnalyzeDot(BuildContext context, bool isDarkMode) {
    return _buildText(context, isDarkMode, " • ");
  }

  static Widget _buildText(
    BuildContext context,
    bool isDarkMode,
    String title, {
    Color? textColor,
  }) {
    bool isSmallSize = FlutterSizeHelpers.checkSizeIsSmall(context);
    return WTextContent(
      value: title,
      textMaxLength: 2,
      textSize: isSmallSize ? 9 : 13,
      textColor: textColor ?? (isDarkMode ? white07 : black07),
      textLineHeight: 18.2,
    );
    // AutoSizeText(
    //   title,
    //   maxLines: 1,
    //   // minFontSize: 7,
    //   // maxFontSize: 13,
    //   style: TextStyle(
    //     color: textColor ?? (isDarkMode ? white07 : black07),
    //     height: 13 / 18.2,
    //     fontWeight: FontWeight.w600,
    //     fontFamily: FONT_GOOGLESANS,
    //     fontSize: isSmallSize ? 7 : 13,
    //   ),
    // );
  }
}
