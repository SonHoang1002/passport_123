import 'dart:math';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/helpers/caculate_text_size.dart';
import 'package:pass1_/helpers/log_custom.dart';
import 'package:pass1_/helpers/navigator_route.dart';
import 'package:pass1_/models/country_passport_model.dart';
import 'package:pass1_/providers/blocs/device_platform_bloc.dart';
import 'package:pass1_/providers/blocs/theme_bloc.dart';
import 'package:pass1_/screens/sub_modules/module_crop/widgets/w_crop_guides/w_crop_guide_phone.dart';
import 'package:pass1_/screens/sub_modules/module_crop/widgets/w_crop_guides/w_crop_guide_tablet.dart';
import 'package:pass1_/widgets/general_dialog/w_body_dialogs.dart';
import 'package:pass1_/widgets/general_dialog/w_general_dialog.dart';
import 'package:pass1_/widgets/general_dialog/w_information_item.dart';
import 'package:pass1_/widgets/w_divider.dart';
import 'package:pass1_/widgets/w_spacer.dart';
import 'package:pass1_/widgets/w_text.dart';

class WDialogCountry extends StatefulWidget {
  final CountryModel countrySelected;
  final List<CountryModel> listCountryModel;
  final Function() onClose;
  final bool isOpen;
  final Function(CountryModel value) onSelect;

  const WDialogCountry({
    super.key,
    required this.countrySelected,
    required this.isOpen,
    required this.onClose,
    required this.onSelect,
    required this.listCountryModel,
  });

  @override
  State<WDialogCountry> createState() => _DialogCountryWidgetState();
}

class _DialogCountryWidgetState extends State<WDialogCountry>
    with SingleTickerProviderStateMixin {
  late Size _size;
  final GlobalKey _keyCountry = GlobalKey(debugLabel: "_keyCountry");
  final GlobalKey _keyPassport = GlobalKey(debugLabel: "_keyPassport");
  late double maxWidthText;
  bool _showButtons = false;

  void _onShowCropGuideBottomSheet() {
    bool isPhone = BlocProvider.of<DevicePlatformCubit>(context).isPhone;
    if (isPhone) {
      pushCustomVerticalMaterialPageRoute(
        context,
        WCustomCropGuidePhone(
          countrySelected: widget.countrySelected,
          onUpdateCountry: (model) {
            widget.onSelect(model);
          },
          screenSize: _size,
        ),
      );
    } else {
      pushCustomVerticalMaterialPageRoute(
        context,
        WCustomCropGuideTablet(
          countrySelected: widget.countrySelected,
          onUpdateCountry: (model) {
            widget.onSelect(model);
          },
          screenSize: _size,
        ),
      );
    }
  }

  void _onSelectCountry() {
    final RenderBox renderBox =
        _keyCountry.currentContext!.findRenderObject() as RenderBox;
    final currentOffset = renderBox.localToGlobal(const Offset(0, 0));
    showCustomDialogWithOffset(
      context: context,
      newScreen: BodyDialogCustom(
        offset: currentOffset,
        dialogWidget: DialogCountryBody(
          listCountryModel: widget.listCountryModel,
          countrySelected: widget.countrySelected,
          onSelected: (value) {
            consolelog("showCustomDialogWithOffset: ${value.getInfor()}");
            widget.onSelect(value);
            popNavigator(context);
          },
          dialogWidth: 200,
        ),
        scaleAlignment: Alignment.topLeft,
      ),
    );
  }

  String _getMaxContentWidth(CountryModel countrySelected) {
    String titleWithMaxLength = "";
    var listPassportModel = countrySelected.listPassportModel;
    for (int i = 0; i < listPassportModel.length; i++) {
      final titleItem = listPassportModel[i].title;
      if (titleItem.length > titleWithMaxLength.length) {
        titleWithMaxLength = titleItem;
      }
    }
    return titleWithMaxLength;
  }

  void _onSelectPassport() {
    final RenderBox renderBox =
        _keyPassport.currentContext!.findRenderObject() as RenderBox;
    Offset currentEndOffset = renderBox.localToGlobal(const Offset(0, 0));
    currentEndOffset = currentEndOffset.translate(renderBox.size.width, 0);
    String contentMaxLength = _getMaxContentWidth(widget.countrySelected);

    final contentWidth = measureTextSize(
      contentMaxLength,
      const TextStyle(fontSize: 12, height: 15, fontWeight: FontWeight.w700),
    ).width;

    double rWidth = contentWidth + 30;
    if (contentMaxLength.length > 42) {
      currentEndOffset = currentEndOffset.translate(
        -rWidth - 10 - 15 - 10,
        0,
      ); // tru padding cua dialog(10), padding ben trong(15)s
    } else {
      currentEndOffset = currentEndOffset.translate(-rWidth - 10 - 15, 0);
    }
    int? textMaxLength;
    // truong hop dialog vuot qua limit ben trai -> chia thanh 2 dong
    if (currentEndOffset.dx < 0) {
      textMaxLength = 2;
    }
    showCustomDialogWithOffset(
      context: context,
      newScreen: BodyDialogCustom(
        offset: currentEndOffset,
        dialogWidget: DialogPassportBody(
          listCountryModel: widget.listCountryModel,
          countrySelected: widget.countrySelected,
          // context,
          onSelected: (value) {
            final indexSelectedPassport = widget
                .countrySelected
                .listPassportModel
                .indexWhere((element) {
                  return element.id == value.id;
                });
            consolelog(
              "showCustomDialogWithOffset - selected passport index: $indexSelectedPassport",
            );
            if (indexSelectedPassport != -1) {
              final newSelectedCountry = widget.countrySelected.copyWith(
                indexSelectedPassport: indexSelectedPassport,
              );
              widget.onSelect(newSelectedCountry);
            }
            popNavigator(context);
          },
          dialogWidth: rWidth,
          textMaxLength: textMaxLength,
        ),
        scaleAlignment: Alignment.topRight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.sizeOf(context);
    double mainWidth = min(_size.width, SIZE_EXAMPLE.width);
    maxWidthText = mainWidth > MIN_SIZE.width ? 170 : 140;
    TextStyle titleStyle = TextStyle(
      decoration: TextDecoration.none,
      fontSize: mainWidth > MIN_SIZE.width ? 13 : 11,
      color: white,
      fontWeight: FontWeight.w600,
      fontFamily: FONT_GOOGLESANS,
      height: 16 / 13,
    );
    if (widget.isOpen) {
      _showButtons = true;
    }
    final isDarkMode = BlocProvider.of<ThemeBloc>(context).isDarkMode;
    String textAll = "", mainText = "";
    if (widget.countrySelected.listPassportModel.isNotEmpty) {
      PassportModel selectedPassport = widget
          .countrySelected
          .listPassportModel[widget.countrySelected.indexSelectedPassport];
      textAll = "${widget.countrySelected.emoji} ${selectedPassport.title}";
    }
    Size textValueSize = measureTextSize(textAll, titleStyle);

    if (textValueSize.width > maxWidthText) {
      Size kichThuocDauBaCham = measureTextSize("...", titleStyle);
      Size kichThuocChuViDu = measureTextSize("a", titleStyle);
      Size kichThuocLaCo = measureTextSize(
        widget.countrySelected.emoji,
        titleStyle,
      );
      int soLuongChuPhaiTruBoThayTheChoLaCo =
          kichThuocLaCo.width ~/ kichThuocChuViDu.width;
      double chieuDaiPhanConLai =
          maxWidthText - kichThuocDauBaCham.width - kichThuocLaCo.width;
      int soLuongChuLonNhat = chieuDaiPhanConLai ~/ kichThuocChuViDu.width;
      int soLuongChuMoiBen = soLuongChuLonNhat ~/ 2;
      mainText =
          "${textAll.substring(0, soLuongChuMoiBen + soLuongChuPhaiTruBoThayTheChoLaCo)}...${textAll.substring(textAll.length - (soLuongChuMoiBen + soLuongChuPhaiTruBoThayTheChoLaCo), textAll.length)}";
    } else {
      mainText = textAll;
    }
    double lengthOfMainText = measureTextSize(mainText, titleStyle).width;

    return LayoutBuilder(
      builder: (context, constraint) {
        return AnimatedContainer(
          curve: CUBIC_CURVE,
          duration: const Duration(milliseconds: 500),
          clipBehavior: Clip.hardEdge,
          height: widget.isOpen ? 150 : 35,
          width: widget.isOpen
              ? mainWidth
              : mainWidth > MIN_SIZE.width
              ? (lengthOfMainText + 65)
              : (lengthOfMainText + 125),
          alignment: Alignment.bottomCenter,
          transformAlignment: Alignment.topCenter,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: black,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isOpen ? 15 : 10,
            vertical: widget.isOpen
                ? 14
                : (mainWidth > MIN_SIZE.width ? 9 : 6.5),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  WTextContent(
                    value: mainText,
                    textFontWeight: titleStyle.fontWeight,
                    textSize: 13,
                    textLineHeight: 16,
                    textColor: titleStyle.color,
                    textAlign: TextAlign.start,
                  ),
                  WSpacer(width: 7),
                  widget
                          .isOpen // _isShowEditButton
                      ? GestureDetector(
                          onTap: () {
                            _onShowCropGuideBottomSheet();
                          },
                          child: Container(
                            height: 36,
                            width: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: isDarkMode ? primaryDark1 : primaryDark1,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                WTextContent(
                                  value: "Edit",
                                  textSize: 15,
                                  textLineHeight: 16,
                                  textColor: white,
                                  textFontWeight: FontWeight.w600,
                                ),
                                Image.asset(
                                  "${PATH_PREFIX_ICON}icon_edit_crop_guide.png",
                                  height: 20,
                                ),
                              ],
                            ),
                          ),
                        )
                      : const Icon(
                          FontAwesomeIcons.caretDown,
                          size: 15,
                          color: white,
                        ),
                ],
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 450),
                opacity: widget.isOpen ? 1 : 0,
                onEnd: () {
                  setState(() {
                    _showButtons = false;
                  });
                },
                child: (_showButtons)
                    ? Container(
                        margin: const EdgeInsets.only(top: 15),
                        child: Flex(
                          direction: Axis.horizontal,
                          children: [
                            _buildButtonWidget(
                              key: _keyCountry,
                              title: widget.countrySelected.title,
                              onTap: () {
                                _onSelectCountry();
                              },
                            ),
                            WSpacer(width: 10),
                            _buildButtonWidget(
                              key: _keyPassport,
                              title:
                                  widget
                                      .countrySelected
                                      .listPassportModel
                                      .isNotEmpty
                                  ? widget.countrySelected.currentPassport.id ==
                                            ID_CUSTOM_COUNTRY_MODEL
                                        ? "Document"
                                        : widget
                                              .countrySelected
                                              .listPassportModel[widget
                                                  .countrySelected
                                                  .indexSelectedPassport]
                                              .title
                                  : "",
                              onTap: () {
                                if (widget
                                    .countrySelected
                                    .listPassportModel
                                    .isEmpty) {
                                  return;
                                }
                                _onSelectPassport();
                              },
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildButtonWidget({
    required Key key,
    required String title,
    required Function() onTap,
  }) {
    return Flexible(
      key: key,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: white01,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              title.length > 12
                  ? Expanded(
                      child: AutoSizeText(
                        title,
                        maxFontSize: 15,
                        minFontSize: 15,
                        maxLines: 1,
                        style: const TextStyle(
                          height: 16 / 15,
                          color: white,
                          overflow: TextOverflow.ellipsis,
                          fontWeight: FontWeight.w600,
                          fontFamily: FONT_GOOGLESANS,
                        ),
                      ),
                    )
                  : AutoSizeText(
                      title,
                      maxFontSize: 15,
                      minFontSize: 12,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 16 / 15,
                        color: white,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: FontWeight.w600,
                        fontFamily: FONT_GOOGLESANS,
                      ),
                    ),
              WSpacer(width: 10),
              const Icon(FontAwesomeIcons.caretDown, size: 15, color: white),
            ],
          ),
        ),
      ),
    );
  }
}

class DialogCountryBody extends StatefulWidget {
  final List<CountryModel> listCountryModel;
  final CountryModel countrySelected;
  final Function(CountryModel value) onSelected;
  final Color? backgroundColor;
  final double? dialogWidth;

  const DialogCountryBody({
    super.key,
    required this.listCountryModel,
    required this.countrySelected,
    required this.onSelected,
    this.backgroundColor,
    this.dialogWidth,
  });

  @override
  State<DialogCountryBody> createState() => _DialogCountryBodyState();
}

class _DialogCountryBodyState extends State<DialogCountryBody> {
  ScrollController controller = ScrollController();
  late Size _size;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (mounted) {
        int indexOfSelectedCountry = widget.listCountryModel.indexWhere(
          (element) => element.id == widget.countrySelected.id,
        );
        if (indexOfSelectedCountry != -1) {
          controller.animateTo(
            indexOfSelectedCountry * 40 +
                indexOfSelectedCountry * dividerHeight,
            duration: const Duration(milliseconds: 400),
            curve: Curves.linear,
          );
        }
        setState(() {});
      }
    });
  }

  double get dividerHeight => 0.5;
  double get dialogHeight => _size.height * 0.4;
  double get dialogItemHeight => 40;

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.sizeOf(context);
    final isDarkMode = BlocProvider.of<ThemeBloc>(
      context,
      listen: false,
    ).isDarkMode;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(color: Theme.of(context).dividerTheme.color),
          ),
          _buildCountryList1(_size, isDarkMode, widget.dialogWidth ?? 200),
        ],
      ),
    );
  }

  Widget _buildCountryList(Size size, bool isDarkMode, double? rWidth) {
    consolelog("rWidthrWidth =  $rWidth");
    return SizedBox(
      height: size.height * 0.4,
      child: SingleChildScrollView(
        controller: controller,
        child: Column(
          children: widget.listCountryModel.indexed.map((e) {
            Color bgColor =
                widget.backgroundColor ??
                Theme.of(context).dialogBackgroundColor;
            Color textColor = isDarkMode ? white : black;
            if (e.$2.id == widget.countrySelected.id) {
              textColor = blue;
            }
            BoxDecoration boxDecoration = BoxDecoration(color: bgColor);
            if (e.$1 == 0) {
              boxDecoration = BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                color: bgColor,
              );
            }
            if (e.$1 == widget.listCountryModel.length - 1) {
              boxDecoration = BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                color: bgColor,
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                buildDialogInformationItem(
                  context,
                  e.$2.title,
                  () => widget.onSelected(e.$2),
                  boxDecoration: boxDecoration,
                  width: rWidth,
                  textColor: textColor,
                  subTitle: e.$2.emoji,
                ),
                if (e.$1 != widget.listCountryModel.length - 1)
                  WDivider(height: 0.5, width: rWidth),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCountryList1(Size size, bool isDarkMode, double? rWidth) {
    consolelog("dialogItemHeight = $rWidth");
    return SizedBox(
      height: dialogHeight,
      width: rWidth,
      child: ListView.builder(
        controller: controller,
        itemCount: widget.listCountryModel.length,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          final e = widget.listCountryModel[index];
          Color bgColor =
              widget.backgroundColor ?? Theme.of(context).dialogBackgroundColor;
          Color textColor = isDarkMode ? white : black;
          if (e.id == widget.countrySelected.id) {
            textColor = blue;
          }

          BoxDecoration boxDecoration = BoxDecoration(color: bgColor);
          if (index == 0) {
            boxDecoration = BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              color: bgColor,
            );
          } else if (index == widget.listCountryModel.length - 1) {
            boxDecoration = BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
              color: bgColor,
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              buildDialogInformationItem(
                context,
                e.title,
                () => widget.onSelected(e),
                boxDecoration: boxDecoration,
                width: rWidth,
                height: dialogItemHeight,
                textColor: textColor,
                subTitle: e.emoji,
              ),
              if (index != widget.listCountryModel.length - 1)
                WDivider(height: dividerHeight, width: rWidth),
            ],
          );
        },
      ),
    );
  }
}

class DialogPassportBody extends StatefulWidget {
  final List<CountryModel> listCountryModel;
  final CountryModel countrySelected;
  final Function(PassportModel value) onSelected;
  final Color? backgroundColor;
  final double? dialogWidth;
  final int? textMaxLength;
  const DialogPassportBody({
    super.key,
    required this.listCountryModel,
    required this.countrySelected,
    required this.onSelected,
    this.backgroundColor,
    this.dialogWidth,
    this.textMaxLength,
  });

  @override
  State<DialogPassportBody> createState() => _DialogPassportBodyState();
}

class _DialogPassportBodyState extends State<DialogPassportBody> {
  ScrollController controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (widget.countrySelected.indexSelectedPassport != -1) {
        controller.animateTo(
          widget.countrySelected.indexSelectedPassport * 40,
          duration: const Duration(milliseconds: 10),
          curve: CUBIC_CURVE,
        );
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final _size = MediaQuery.sizeOf(context);
    final rWidth = widget.dialogWidth;
    final isDarkMode = BlocProvider.of<ThemeBloc>(
      context,
      listen: false,
    ).isDarkMode;

    List<CountryModel> model = widget.listCountryModel.where((element) {
      return widget.countrySelected.id == element.id;
    }).toList();
    List<PassportModel> listPassport = [];
    if (model.isNotEmpty) {
      listPassport = model.first.listPassportModel;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(color: Theme.of(context).dividerTheme.color),
          ),
          LayoutBuilder(
            builder: (context, constraint) {
              double mainHeight = min(
                _size.height * 0.4,
                40 * listPassport.length.toDouble(),
              ); // 40 la height cua moi item
              return SizedBox(
                height: mainHeight,
                child: SingleChildScrollView(
                  controller: controller,
                  child: Column(
                    children: listPassport.indexed.map((e) {
                      final index = e.$1;
                      // thay doi color
                      Color bgColor =
                          widget.backgroundColor ??
                          Theme.of(context).dialogBackgroundColor;
                      Color textColor = isDarkMode ? white : black;
                      if (index ==
                          widget.countrySelected.indexSelectedPassport) {
                        textColor = blue;
                      }

                      // them divider, bo bon cac canh
                      BoxDecoration boxDecoration = BoxDecoration(
                        color: bgColor,
                      );
                      if (index == 0) {
                        boxDecoration = BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          color: bgColor,
                        );
                      }
                      if (index == listPassport.length - 1) {
                        boxDecoration = BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(20),
                          ),
                          color: bgColor,
                        );
                      }
                      return Column(
                        children: [
                          buildDialogInformationItem(
                            context,
                            e.$2.title,
                            () => widget.onSelected(e.$2),
                            boxDecoration: boxDecoration,
                            width: rWidth,
                            height: 40,
                            textColor: textColor,
                            textMaxLength: widget.textMaxLength,
                          ),
                          if (index != listPassport.length - 1)
                            WDivider(height: 0.5, width: rWidth),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
