import 'dart:io';
import 'dart:ui' as ui;
import 'package:passport_photo_2/commons/extension.dart';
import 'package:passport_photo_2/helpers/convert.dart';
import 'package:passport_photo_2/helpers/log_custom.dart';
import 'package:passport_photo_2/helpers/print_helper.dart';
import 'package:passport_photo_2/widgets/w_spacer.dart';
import 'package:pdf/pdf.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:passport_photo_2/commons/colors.dart';
import 'package:passport_photo_2/commons/constants.dart';
import 'package:passport_photo_2/helpers/navigator_route.dart';
import 'package:passport_photo_2/models/country_passport_model.dart';
import 'package:passport_photo_2/providers/blocs/theme_bloc.dart';
import 'package:passport_photo_2/widgets/general_dialog/w_body_dialogs.dart';
import 'package:passport_photo_2/widgets/general_dialog/w_general_dialog.dart';
import 'package:passport_photo_2/widgets/general_dialog/w_information_item.dart';
import 'package:passport_photo_2/widgets/w_button.dart';
import 'package:passport_photo_2/widgets/w_divider.dart';
import 'package:passport_photo_2/widgets/w_text.dart';
import 'package:printing/printing.dart';

class WPrintBody extends StatefulWidget {
  final CountryModel countrySelected;
  final File croppedFile;
  final ui.Image uiImageCropped;
  final double height;
  const WPrintBody({
    super.key,
    required this.countrySelected,
    required this.croppedFile,
    required this.height,
    required this.uiImageCropped,
  });

  @override
  State<WPrintBody> createState() => _WPrintBodyState();
}

class _WPrintBodyState extends State<WPrintBody> {
  late Size _size;
  int _selectionNumberOfCopy = 6;
  final GlobalKey _keyCopyNumber = GlobalKey(debugLabel: "_keyCopyNumber");

  void _onPrint() async {
    await Printing.layoutPdf(
      onLayout: (format) {
        return _generatePdf(
          format,
          "Title",
          widget.uiImageCropped,
          _selectionNumberOfCopy,
          widget.croppedFile,
          widget.countrySelected,
        );
      },
      format: PdfPageFormat.a4,
      usePrinterSettings: true,
    );
  }

  Future<Uint8List> _generatePdf(
    PdfPageFormat pdfPageFormat,
    String title,
    ui.Image uiImageCropped,
    int numberImage,
    File croppedFile,
    CountryModel countrySelected,
  ) async {
    double dpi = 600.0;
    var currentPassport = countrySelected.currentPassport;

    double passportWidthByPrintPoint, passportHeightByPrintPoint;

    if (currentPassport.unit == PIXEL) {
      passportWidthByPrintPoint = currentPassport.width / dpi * 72;
      passportHeightByPrintPoint = currentPassport.height / dpi * 72;
    } else {
      passportWidthByPrintPoint = FlutterConvert.convertUnit(
          currentPassport.unit, POINT, currentPassport.width);
      passportHeightByPrintPoint = FlutterConvert.convertUnit(
          currentPassport.unit, POINT, currentPassport.height);
    }
    // double ratioWH = uiImageCropped.width / uiImageCropped.height;

    Size passportSizeByPrintPoint = Size(
      passportWidthByPrintPoint,
      passportHeightByPrintPoint,
    );
    

    // if (ratioWH > 1) {
    //   if (uiImageCropped.width > widthWithDpi) {
    //     passportSizeByPrintPointLimited = Size(
    //       widthWithDpi,
    //       widthWithDpi / ratioWH,
    //     );
    //   }
    // } else if (ratioWH < 1) {
    //   if (uiImageCropped.height > heightWithDpi) {
    //     imagePreviewSize = Size(
    //       heightWithDpi * ratioWH,
    //       heightWithDpi,
    //     );
    //   }
    // } else {
    //   if (uiImageCropped.height > heightWithDpi) {
    //     imagePreviewSize = Size(
    //       heightWithDpi,
    //       heightWithDpi,
    //     );
    //   }
    // }
    consolelog(
        "passportSizeByPrintPoint ${passportSizeByPrintPoint} -  ${uiImageCropped.width}- ${uiImageCropped.height}");

    return PrintHelper().generatePdf(
   format:    pdfPageFormat,
     title:   title,
     croppedFile:  croppedFile,
   numberImage:    numberImage,
     countrySelected:  countrySelected,
     imagePreviewSize:   passportSizeByPrintPoint,
    );
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.sizeOf(context);
    final isDarkMode =
        BlocProvider.of<ThemeBloc>(context, listen: true).isDarkMode;
    return Stack(
      children: [
        // blur
        // body: title, preview, change number of copy
        // buttons

        // blur
        SizedBox(
          height: widget.height,
          child: ClipRRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: 20,
                sigmaY: 20,
              ),
              child: Container(
                color: transparent,
              ),
            ),
          ),
        ),
        // body + button
        Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              right: 20,
              top: 10,
              left: 20),
          decoration: BoxDecoration(
            color: isDarkMode ? blurDark : blurLight,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  // title
                  WSpacer(height: 10),
                  WTextContent(
                    value: "Prepare to Print",
                    textSize: 18,
                    textLineHeight: 16,
                    textFontWeight: FontWeight.w600,
                  ),
                  // preview
                  Container(
                    height: 46,
                    margin: const EdgeInsets.only(
                      top: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).badgeTheme.backgroundColor!,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      // horizontal: 15,
                      vertical: 10,
                    ),
                    child: Flex(
                      direction: Axis.horizontal,
                      children: [
                        _buildPreviewExport(
                          isDarkMode,
                          widget.countrySelected.currentPassport.id ==
                                  ID_CUSTOM_COUNTRY_MODEL
                              ? "Custom"
                              : "Passport",
                        ),
                        _buildLinePreviewExport(),
                        _buildPreviewExport(
                          isDarkMode,
                          _getTitlePassportFormat(),
                        ),
                        if (widget.countrySelected.emoji != "")
                          _buildLinePreviewExport(),
                        if (widget.countrySelected.emoji != "")
                          _buildPreviewExport(
                              isDarkMode, widget.countrySelected.emoji),
                      ],
                    ),
                  ),
                  // change number of copy
                  Container(
                    height: 46,
                    margin: const EdgeInsets.only(
                      top: 20,
                    ),
                    decoration: BoxDecoration(
                        color: Theme.of(context).badgeTheme.backgroundColor!,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            flex: 1,
                            child: Container(
                              alignment: Alignment.center,
                              child: AutoSizeText(
                                "Number of copy:",
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .color,
                                  height: 14 / 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: FONT_GOOGLESANS,
                                ),
                              ),
                            ),
                          ),
                          Flexible(
                              key: _keyCopyNumber,
                              flex: 1,
                              child: GestureDetector(
                                onTap: () {
                                  _onShowDialog();
                                },
                                child: Container(
                                  margin: const EdgeInsets.all(2),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  decoration: BoxDecoration(
                                      color: white,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          const SizedBox(),
                                          AutoSizeText(
                                            "$_selectionNumberOfCopy Copies",
                                            maxLines: 1,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: black,
                                              height: 14 / 19.6,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: FONT_GOOGLESANS,
                                            ),
                                          ),
                                          const Icon(
                                            FontAwesomeIcons.caretDown,
                                            size: 15,
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ))
                        ]),
                  ),
                ],
              ),
              // button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: WButtonFilled(
                  height: 54,
                  message: "Continue",
                  backgroundColor: isDarkMode ? primaryDark1 : primaryLight1,
                  onPressed: () async {
                    _onPrint();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onShowDialog() {
    final renderBox =
        _keyCopyNumber.currentContext!.findRenderObject() as RenderBox;
    final startOffset = renderBox.localToGlobal(const Offset(0, 0));
    final endOffset =
        startOffset.translate(renderBox.size.width, -renderBox.size.height);
    final targetOffset = endOffset.translate(-200, -_size.height * 0.45);
    showCustomDialogWithOffset(
      context: context,
      newScreen: BodyDialogCustom(
        offset: targetOffset,
        dialogWidget: DialogNumberBody(
          selectionNumberOfCopy: _selectionNumberOfCopy,
          onSelected: (value) {
            setState(() {
              _selectionNumberOfCopy = value;
            });
            popNavigator(context);
          },
          dialogWidth: 200,
        ),
        scaleAlignment: Alignment.bottomCenter,
      ),
    );
  }

  String _getTitlePassportFormat() {
    final PassportModel selectedPassport = widget.countrySelected
        .listPassportModel[widget.countrySelected.indexSelectedPassport];
    consolelog("_getTitlePassportFormat: ${selectedPassport.toString()}");

    return "${(selectedPassport.width).roundWithUnit(fractionDigits: 0)}x${(selectedPassport.height).roundWithUnit(fractionDigits: 0)}${selectedPassport.unit.title}";
  }

  Widget _buildLinePreviewExport() {
    return Container(
      height: 20,
      color: grey.withValues(alpha: 0.5),
      width: 1,
    );
  }

  Widget _buildPreviewExport(bool isDarkMode, String title) {
    return Flexible(
        flex: 1,
        fit: FlexFit.tight,
        child: Container(
          alignment: Alignment.center,
          child: AutoSizeText(
            title,
            maxLines: 1,
            minFontSize: 10,
            maxFontSize: 13,
            style: TextStyle(
              color: isDarkMode
                  ? white05
                  : Theme.of(context).textTheme.bodySmall!.color,
              height: 13 / 18.2,
              fontWeight: FontWeight.w600,
              fontFamily: FONT_GOOGLESANS,
            ),
          ),
        ));
  }
}

class DialogNumberBody extends StatefulWidget {
  final int selectionNumberOfCopy;
  final Function(int value) onSelected;
  final Color? backgroundColor;
  final int? textMaxLength;
  final double? dialogWidth;
  final double? dialogHeight;
  const DialogNumberBody({
    super.key,
    required this.selectionNumberOfCopy,
    required this.onSelected,
    this.dialogWidth,
    this.backgroundColor,
    this.textMaxLength,
    this.dialogHeight,
  });

  @override
  State<DialogNumberBody> createState() => _DialogNumberBodyState();
}

class _DialogNumberBodyState extends State<DialogNumberBody> {
  ScrollController controller = ScrollController();
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (widget.selectionNumberOfCopy != -1) {
        controller.animateTo(
          (widget.selectionNumberOfCopy - 1) * 40,
          duration: const Duration(milliseconds: 10),
          curve: CUBIC_CURVE,
        );
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final rWidth = widget.dialogWidth;
    final isDarkMode =
        BlocProvider.of<ThemeBloc>(context, listen: false).isDarkMode;
    final _size = MediaQuery.sizeOf(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Positioned.fill(
              child: Container(
            color: Theme.of(context).dividerTheme.color,
          )),
          SizedBox(
            height: widget.dialogHeight ?? _size.height * 0.45,
            child: SingleChildScrollView(
              controller: controller,
              child: Column(
                children: LIST_COPY_NUMBER_SELECTION.map((index) {
                  if (index == 0) return const SizedBox();
                  // thay doi color
                  Color bgColor = widget.backgroundColor ??
                      Theme.of(context).dialogBackgroundColor;
                  Color textColor = isDarkMode ? white : black;
                  if (index == widget.selectionNumberOfCopy) {
                    textColor = blue;
                  }
                  // them divider, bo bon cac canh
                  BoxDecoration boxDecoration = BoxDecoration(color: bgColor);
                  if (index == 0) {
                    boxDecoration = BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      color: bgColor,
                    );
                  }
                  if (index == LIST_COPY_NUMBER_SELECTION.length - 1) {
                    boxDecoration = BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(20)),
                      color: bgColor,
                    );
                  }
                  return Column(
                    children: [
                      buildDialogInformationItem(
                        context,
                        index.toString(),
                        () => widget.onSelected(index),
                        boxDecoration: boxDecoration,
                        width: rWidth,
                        textColor: textColor,
                        textMaxLength: widget.textMaxLength,
                      ),
                      if (index != LIST_COPY_NUMBER_SELECTION.length - 1)
                        WDivider(
                          height: 0.5,
                          width: rWidth,
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
