import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/helpers/native_bridge/method_channel.dart';
import 'package:pass1_/models/project_model.dart';
import 'package:pass1_/models/step_model.dart';
import 'package:pass1_/screens/module_home/widgets/w_footer.dart';
import 'package:pass1_/widgets/bottom_sheet/show_bottom_sheet.dart';
import 'package:pass1_/providers/blocs/theme_bloc.dart';
import 'package:pass1_/screens/module_instruction/instruction.dart';
import 'package:pass1_/widgets/w_text.dart';

class BodyImportTablet extends StatefulWidget {
  final StepModel currentStep;
  final ProjectModel projectModel;
  final Function(File? file) onUpdateImage;
  final Function() onUpdateStep;
  final Function(bool value) onUpdateLoadingStatus;
  const BodyImportTablet({
    super.key,
    required this.currentStep,
    required this.projectModel,
    required this.onUpdateImage,
    required this.onUpdateStep,
    required this.onUpdateLoadingStatus,
  });

  @override
  State<BodyImportTablet> createState() => _BodyImportTabletState();
}

class _BodyImportTabletState extends State<BodyImportTablet>
    with TickerProviderStateMixin {
  late Size _size;
  late bool _isDarkMode;
  late Animation<double> _opacityAnimation;
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _animatedOpacity();
    List<String> list = [
      "/storage/emulated/0/Download/imgonline-com-ua-exifedit92iePbx2OqxT.jpg",
      "/storage/emulated/0/Download/20240617_220342.jpg",
    ];
    for (var element in list) {
      MediaScanner.loadMedia(path: element);
    }
  }

  _animatedOpacity() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.sizeOf(context);
    _isDarkMode = BlocProvider.of<ThemeBloc>(context, listen: false).isDarkMode;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // instruction
              // title
              // preview image
              // image options
              // instruction
              GestureDetector(
                onTap: () {
                  showCustomBottomSheetWithClose(
                    context: context,
                    child: const Instructions(),
                    height: _size.height * 0.94,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  margin: const EdgeInsets.only(top: 20, bottom: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Theme.of(context).badgeTheme.backgroundColor,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      WTextContent(
                        value: "Instructions",
                        textSize: 14,
                        textLineHeight: 16,
                        textFontWeight: FontWeight.w600,
                        textColor: Theme.of(
                          context,
                        ).textTheme.displayMedium!.color,
                      ),
                      Container(
                        height: 20,
                        width: 20,
                        margin: const EdgeInsets.only(left: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Image.asset(
                          PATH_PREFIX_ICON +
                              (_isDarkMode
                                  ? "icon_instruction_question_dark.png"
                                  : "icon_instruction_question_light.png"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // title
                  WTextContent(
                    value: "Import Photo",
                    textSize: 24,
                    textLineHeight: 28.64,
                  ),
                  // preview image
                  AnimatedBuilder(
                    animation: _opacityAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _opacityAnimation.value,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // have selected image
                            Visibility(
                              visible: widget.projectModel.selectedFile != null,
                              maintainSize: true,
                              maintainState: true,
                              maintainAnimation: true,
                              child: Container(
                                constraints: _size.height <= MIN_SIZE.height
                                    ? const BoxConstraints(
                                        minHeight: 100,
                                        minWidth: 100,
                                        maxHeight: 170,
                                        maxWidth: 170,
                                      )
                                    : const BoxConstraints(
                                        minHeight: 120,
                                        minWidth: 120,
                                        maxHeight: 270,
                                        maxWidth: 270,
                                      ),
                                // height: 270,
                                // width: 270,
                                margin: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _buildImagePreview(),
                                ),
                              ),
                            ),
                            // don't have selected image
                            Visibility(
                              maintainSize: true,
                              maintainState: true,
                              maintainAnimation: true,
                              visible: widget.projectModel.selectedFile == null,
                              child: Container(
                                constraints: _size.height <= MIN_SIZE.height
                                    ? const BoxConstraints(
                                        minHeight: 100,
                                        minWidth: 100,
                                        maxHeight: 170,
                                        maxWidth: 170,
                                      )
                                    : null,
                                height: 270,
                                width: 270,
                                margin: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: _isDarkMode ? white003 : black003,
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).badgeTheme.backgroundColor!,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: SizedBox(
                                    height: 48,
                                    width: 48,
                                    child: Image.asset(
                                      PATH_PREFIX_ICON +
                                          (_isDarkMode
                                              ? "icon_image_preview_dark.png"
                                              : "icon_image_preview_light.png"),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  // picker options
                  AnimatedBuilder(
                    animation: _opacityAnimation,
                    builder: (context, child) {
                      return SizedBox(
                        height: 110,
                        child: Center(
                          child: Opacity(
                            opacity: _opacityAnimation.value,
                            child: Container(
                              margin: const EdgeInsets.only(top: 10),
                              child: (widget.projectModel.selectedFile != null)
                                  ? _buildClearPhotoWidget()
                                  : _buildImportOptions(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(),
            ],
          ),
        ),
        WFooter(
          projectModel: widget.projectModel,
          currentStep: widget.currentStep,
          isDarkMode: _isDarkMode,
          onNext: () async {
            widget.onUpdateLoadingStatus(true);
            await widget.onUpdateStep();
            widget.onUpdateLoadingStatus(false);
          },
          isHaveSettingButton: false,
          footerHeight: 166,
        ),
      ],
    );
  }

  Widget _buildClearPhotoWidget() {
    return InkWell(
      onTap: () {
        _animatedOpacity();
        widget.onUpdateImage(null);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Theme.of(context).bottomAppBarTheme.color,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Image.asset(
                "${PATH_PREFIX_ICON}icon_clear.png",
                color: Theme.of(context).textTheme.bodySmall!.color,
              ),
            ),
            WTextContent(
              value: "CLEAR PHOTO",
              textSize: 13,
              textLineHeight: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportOptions() {
    return Container(
      width: 500,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildImportOptionItem(
            mediaSrc: "${PATH_PREFIX_ICON}icon_step_import.png",
            backgroundColor: white,
            iconColor: black,
            title: "GALLERY",
            textColor: black,
            onTap: () async {
              final result = await ImagePicker().pickImage(
                source: ImageSource.gallery,
              );
              if (result != null) {
                widget.onUpdateImage(File(result.path));
              }
            },
          ),
          _buildImportOptionItem(
            mediaSrc: "${PATH_PREFIX_ICON}icon_file.png",
            backgroundColor: _isDarkMode ? primaryDark1 : primaryLight1,
            title: "FILES",
            textColor: white,
            onTap: () async {
              final result = await FilePicker.platform.pickFiles();
              if (result != null && result.files.isNotEmpty) {
                String filePath = result.files[0].path!;
                String extension = filePath.split(".").last;
                bool isSupported = LIST_SUPPORTED_TYPE.contains(
                  extension.toLowerCase(),
                );
                if (isSupported) {
                  widget.onUpdateImage(File(filePath));
                } else {
                  MyMethodChannel.showToast("Not supported file type!!");
                }
              }
            },
          ),
          _buildImportOptionItem(
            mediaSrc: "${PATH_PREFIX_ICON}icon_camera.png",
            iconColor: _isDarkMode ? white : black,
            backgroundColor: Theme.of(context)
                .tabBarTheme
                .unselectedLabelColor!, // _isDarkMode ? white005 : black005,
            title: "CAMERA",
            textColor: _isDarkMode ? white : black,
            onTap: () async {
              final result = await ImagePicker().pickImage(
                source: ImageSource.camera,
              );
              if (result != null) {
                widget.onUpdateImage(File(result.path));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImportOptionItem({
    required String mediaSrc,
    required Color backgroundColor,
    required String title,
    required Function() onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 65,
            width: 65,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(35),
              color: backgroundColor,
            ),
            child: Center(
              child: SizedBox(
                height: 32,
                width: 32,
                child: Image.asset(mediaSrc, color: iconColor),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: backgroundColor,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: WTextContent(
              value: title,
              textSize: 12,
              textLineHeight: 16,
              textColor: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    File? imageFile;
    if (widget.projectModel.scaledSelectedImage != null) {
      return RawImage(image: widget.projectModel.scaledSelectedImage);
    }
    if (widget.projectModel.selectedFile != null ||
        widget.projectModel.scaledSelectedFile != null) {
      imageFile =
          widget.projectModel.scaledSelectedFile ??
          widget.projectModel.selectedFile;
    }

    return imageFile != null
        ? Image.file(
            imageFile,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
          )
        : const SizedBox();
  }
}
