// import 'dart:io';
// import 'dart:ui' as ui;
// import 'package:auto_size_text/auto_size_text.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_file_dialog/flutter_file_dialog.dart';
// import 'package:media_scanner/media_scanner.dart';
// import 'package:pass1_/commons/colors.dart';
// import 'package:pass1_/commons/constants.dart';
// import 'package:pass1_/helpers/caculate_file_size.dart';
// import 'package:pass1_/helpers/convert.dart';
// import 'package:pass1_/helpers/method_channel.dart';
// import 'package:pass1_/helpers/random_number.dart';
// import 'package:pass1_/models/country_passport_model.dart';
// import 'package:pass1_/models/project_model.dart';
// import 'package:pass1_/providers/blocs/device_platform_bloc.dart';
// import 'package:pass1_/providers/blocs/theme_bloc.dart';
// import 'package:pass1_/screens/module_home/helpers/export_helpers.dart';
// import 'package:pass1_/widgets/w_button.dart';
// import 'package:pass1_/widgets/w_custom_about_dialog.dart';
// import 'package:pass1_/widgets/w_segment_custom.dart';
// import 'package:pass1_/widgets/w_slider.dart';
// import 'package:pass1_/widgets/w_spacer.dart';
// import 'package:pass1_/widgets/w_text.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';

// class WExportBody extends StatefulWidget {
//   final ProjectModel projectModel;
//   final double height;
//   final CountryModel countrySelected;
//   final File imageCropped;
//   final Function(ProjectModel projectModel) onUpdateModel;
//   const WExportBody({
//     super.key,
//     required this.projectModel,
//     required this.height,
//     required this.countrySelected,
//     required this.imageCropped,
//     required this.onUpdateModel,
//   });

//   @override
//   State<WExportBody> createState() => _WExportBodyState();
// }

// class _WExportBodyState extends State<WExportBody> {
//   int _indexSelectedFormat = 0;
//   int _indexSelectedResolution = 0;
//   late double _valueResolution;
//   late double _valueSlider;

//   double? _fileSize;
//   File? _fileConverted;
//   late List<double> _listPassportDimensionByInch;
//   late Size _size;

//   @override
//   void initState() {
//     super.initState();
//     _valueResolution = _valueSlider = 300;
//     _handleConvertCurrentUnitToINCH();
//     WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
//       await _handleGenerateSinglePhotoMedia();
//     });
//   }

//   void _handleConvertCurrentUnitToINCH() {
//     final currentPassport = widget.countrySelected
//         .listPassportModel[widget.countrySelected.indexSelectedPassport];
//     final currentUnit = currentPassport.unit;
//     final Size currentSize =
//         Size(currentPassport.width, currentPassport.height);
//     final ratioWidth =
//         FlutterConvert.convertUnit(currentUnit, INCH, currentSize.width);
//     final ratioHeight =
//         FlutterConvert.convertUnit(currentUnit, INCH, currentSize.height);
//     _listPassportDimensionByInch = [ratioWidth, ratioHeight];
//   }

//   String _handleGetTitlePassportFormat() {
//     final selectedPassport = widget.countrySelected
//         .listPassportModel[widget.countrySelected.indexSelectedPassport];
//     return "${(selectedPassport.width).toStringAsFixed(0)}x${(selectedPassport.height).toStringAsFixed(0)}${selectedPassport.unit.title}";
//   }

//   Future<void> _onFormatChange(int value) async {
//     if (_indexSelectedFormat == value) return;
//     _indexSelectedFormat = value;
//     _handleResetFiles(forceReset: true);
//     setState(() {});
//     await _handleGenerateSinglePhotoMedia();
//   }

//   Future<double> _handleGenerateSinglePhotoMedia({
//     double? fileHeight,
//     double? fileWidth,
//   }) async {
//     try {
//       if (_fileSize != null && _fileConverted != null) return 0.0;
//       final dirPath = (await getExternalStorageDirectory())!.path;
//       String extension = (_indexSelectedFormat == 0 ? JPG : PNG).toLowerCase();
//       String outPath = "$dirPath/$FINISH_IMAGE_NAME.$extension";
//       Size abc = ExportHelpers.handleLimitDPI(
//         widget.countrySelected,
//         _size,
//         _valueResolution,
//         _listPassportDimensionByInch,
//       );
//       final resizedFile = await MyMethodChannel.resizeAndResoluteImage(
//         widget.imageCropped.path,
//         _indexSelectedFormat,
//         [
//           fileWidth ?? abc.width,
//           fileHeight ?? abc.height,
//         ],
//         [1, 1],
//         outPath: outPath,
//       );
//       if (resizedFile != null) {
//         final fileSize = await getFileSize(resizedFile);
//         _fileConverted = resizedFile;
//         _fileSize = fileSize;
//         setState(() {});
//         return fileSize;
//       }
//       return 0.0;
//     } catch (e) {
//       return 0.0;
//     }
//   }

//   Future<void> _onResolutionChange(int value) async {
//     if (_indexSelectedResolution == value) return;
//     _handleResetFiles(forceReset: true);
//     _indexSelectedResolution = value;
//     switch (value) {
//       case 0:
//         _valueResolution = 600;
//         break;
//       case 1:
//         _valueResolution = 1200;
//         break;
//       case 2:
//         _valueResolution = _valueSlider;
//         break;
//       default:
//     }
//     setState(() {});
//     await _handleGenerateSinglePhotoMedia();
//   }

//   Future<bool> _onSaveTo(File? file, String fileName) async {
//     if (file != null) {
//       //  xxxxxx
//       final pickedDirectory = await FlutterFileDialog.pickDirectory();
//       if (pickedDirectory != null) {
//         await FlutterFileDialog.saveFileToDirectory(
//           directory: pickedDirectory,
//           data: file.readAsBytesSync(),
//           mimeType: "image/*",
//           fileName: fileName,
//           replace: true,
//         );
//         return true;
//       } else {
//         return false;
//       }
//     } else {
//       showCustomAboutDialog(
//         context,
//         360,
//         "Error",
//         "Cannot save your photo.",
//         titleColor: red,
//       );
//       return false;
//     }
//   }

//   Future<void> _onSaveToLibrary(File? file) async {
//     // truong hop file size bi null khi dpi vuot qua nguong cho phep
//     if (file != null) {
//       final outputFile = file;
//       // final outputFile = await saveToLibrary(
//       //   inputFile: file,
//       //   isPdfFormat: isPdfFormat,
//       //   fileName: fileName,
//       // );
//       await MediaScanner.loadMedia(path: outputFile.path);
//       double dialogWidth = 360;
//       String content = "Your photo is saved successfully.";
//       String title = "Saved";
//       // ignore: use_build_context_synchronously
//       showCustomAboutDialog(
//         context,
//         dialogWidth,
//         title,
//         content,
//       );
//     } else {
//       showCustomAboutDialog(
//         context,
//         360,
//         "Error",
//         "Cannot save your photo.",
//         titleColor: red,
//       );
//     }
//   }

//   String _handleRenderPreviewText() {
//     Size abc = ExportHelpers.handleLimitDPI(
//         widget.countrySelected, _size, _valueResolution, _listPassportDimensionByInch);
//     return "${abc.width.toStringAsFixed(0)}x${abc.height.toStringAsFixed(0)}px";
//   }

//   Color? _handleRenderPreviewTextColor() {
//     Size abc = ExportHelpers.handleLimitDPI(
//         widget.countrySelected, _size, _valueResolution, _listPassportDimensionByInch);
//     if (_size.width > MIN_SIZE.width) {
//       if (abc.height > MAX_SIZE_EXPORT_IMAGE_NORMAL ||
//           abc.width > MAX_SIZE_EXPORT_IMAGE_NORMAL) {
//         return red;
//       }
//     } else {
//       if (abc.height > MAX_SIZE_EXPORT_IMAGE_WEAK ||
//           abc.width > MAX_SIZE_EXPORT_IMAGE_WEAK) {
//         return red;
//       }
//     }
//     return null;
//   }

//   void _handleResetFiles({bool forceReset = false}) {
//     PassportModel currentPassport = widget.countrySelected.currentPassport;
//     bool isReset;
//     if (currentPassport.unit.id != LIST_UNIT.length - 1) {
//       double targetWidth = _valueResolution * _listPassportDimensionByInch[0];
//       double targetHeight = _valueResolution * _listPassportDimensionByInch[1];
//       if (_size.width > MIN_SIZE.width) {
//         if (targetWidth > MAX_SIZE_EXPORT_IMAGE_NORMAL ||
//             targetHeight > MAX_SIZE_EXPORT_IMAGE_NORMAL) {
//           isReset = false;
//         } else {
//           isReset = true;
//         }
//       } else {
//         if (targetWidth > MAX_SIZE_EXPORT_IMAGE_WEAK ||
//             targetHeight > MAX_SIZE_EXPORT_IMAGE_WEAK) {
//           isReset = false;
//         } else {
//           isReset = true;
//         }
//       }
//     } else {
//       isReset = false;
//     }
//     if (forceReset || isReset) {
//       _fileConverted = null;
//       _fileSize = null;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     _size = MediaQuery.sizeOf(context);
//     final isDarkMode =
//         BlocProvider.of<ThemeBloc>(context, listen: false).isDarkMode;
//     bool isPhone = BlocProvider.of<DevicePlatformCubit>(context).isPhone;

//     return Stack(
//       children: [
//         // blur bg
//         SizedBox(
//           height: widget.height,
//           child: ClipRRect(
//             child: BackdropFilter(
//               filter: ui.ImageFilter.blur(
//                 sigmaX: 20,
//                 sigmaY: 20,
//               ),
//               child: Container(
//                 color: transparent,
//               ),
//             ),
//           ),
//         ),
//         // export photo title
//         // title previews
//         // format
//         // resolution
//         // custom resolution
//         // button ( save to , save to library)
//         Container(
//           padding: EdgeInsets.only(
//             bottom: MediaQuery.of(context).padding.bottom + 20,
//             top: 10,
//             right: 15,
//             left: 15,
//           ),
//           height: _size.height * 0.6,
//           decoration: BoxDecoration(
//               color: isDarkMode ? blurDark : blurLight,
//               borderRadius:
//                   const BorderRadius.vertical(top: Radius.circular(20))),
//           child: Column(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   children: [
//                     // export photo title
//                     Container(
//                       margin: const EdgeInsets.only(top: 25, left: 10),
//                       alignment: Alignment.centerLeft,
//                       child: WTextContent(
//                         value: "Export Photo",
//                         textSize: 24,
//                         textLineHeight: 20,
//                       ),
//                     ),
//                     WSpacer(height: 20),
//                     // title previews
//                     Container(
//                       height: 46,
//                       decoration: BoxDecoration(
//                           color: Theme.of(context).badgeTheme.backgroundColor!,
//                           borderRadius: BorderRadius.circular(12)),
//                       padding: const EdgeInsets.symmetric(
//                           vertical: 10, horizontal: 10),
//                       child: Row(
//                         // direction: Axis.horizontal,
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           _buildPreviewExport(
//                               isDarkMode, _handleGetTitlePassportFormat()),
//                           _buildLinePreviewExport(),
//                           _buildPreviewExport(
//                             isDarkMode,
//                             _handleRenderPreviewText(),
//                             textColor: _handleRenderPreviewTextColor(),
//                           ),
//                           _buildLinePreviewExport(),
//                           _buildPreviewExport(isDarkMode,
//                               LIST_FORMAT_IMAGE[_indexSelectedFormat]),
//                           _buildLinePreviewExport(),
//                           _buildPreviewExport(
//                             isDarkMode,
//                             ExportHelpers.handlePreviewFileSize(
//                               _fileSize,
//                               widget.countrySelected,
//                               _size,
//                               _valueResolution,
//                               _listPassportDimensionByInch,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     WSpacer(height: 20),
//                     //format
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         SizedBox(
//                           width: 100,
//                           child: WTextContent(
//                             value: "Format",
//                             textSize: 14,
//                             textLineHeight: 20,
//                             textFontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         Flexible(
//                           child: SizedBox(
//                             width: isPhone ? 300 : null,
//                             height: 36,
//                             child: buildSegmentControl(
//                                 context: context,
//                                 groupValue: _indexSelectedFormat,
//                                 listSegment: {0: "JPG", 1: "PNG"},
//                                 onValueChanged: (value) {
//                                   _onFormatChange(value!);
//                                 },
//                                 unactiveTextColor: Theme.of(context)
//                                     .textTheme
//                                     .displayMedium!
//                                     .color,
//                                 borderRadius: 12),
//                           ),
//                         )
//                       ],
//                     ),
//                     WSpacer(height: 20),
//                     // resolution
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         SizedBox(
//                           width: 100,
//                           child: WTextContent(
//                             value: "Resolution",
//                             textSize: 14,
//                             textLineHeight: 20,
//                             textFontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         Flexible(
//                           child: SizedBox(
//                             width: isPhone ? 300 : null,
//                             height: 36,
//                             child: buildSegmentControl(
//                                 context: context,
//                                 groupValue: _indexSelectedResolution,
//                                 listSegment: {
//                                   0: "600dpi",
//                                   1: "1200dpi",
//                                   2: "Custom"
//                                 },
//                                 onValueChanged: (value) {
//                                   _onResolutionChange(value!);
//                                 },
//                                 unactiveTextColor: Theme.of(context)
//                                     .textTheme
//                                     .displayMedium!
//                                     .color,
//                                 borderRadius: 12),
//                           ),
//                         )
//                       ],
//                     ),
//                     WSpacer(height: 10),
//                     // custom resolution
//                     if (_indexSelectedResolution == 2)
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           const SizedBox(width: 100),
//                           Flexible(
//                             child: Container(
//                               width: isPhone ? 300 : null,
//                               height: 36,
//                               decoration: BoxDecoration(
//                                   color: Theme.of(context)
//                                       .badgeTheme
//                                       .backgroundColor!,
//                                   borderRadius: BorderRadius.circular(12)),
//                               child: Row(children: [
//                                 Flexible(
//                                     flex: 2,
//                                     child: Container(
//                                       padding: const EdgeInsets.only(left: 16),
//                                       child: CustomSlider(
//                                         value: _valueSlider,
//                                         onChanged: (value) {
//                                           setState(() {
//                                             _valueSlider =
//                                                 _valueResolution = value;
//                                           });
//                                         },
//                                         onChangeEnd: (value) async {
//                                           _valueSlider =
//                                               _valueResolution = value;
//                                           _handleResetFiles();
//                                           setState(() {});
//                                           await _handleGenerateSinglePhotoMedia();
//                                         },
//                                         min: 300,
//                                         max: 1200,
//                                         thumbColor: Theme.of(context)
//                                             .textTheme
//                                             .bodySmall!
//                                             .color,
//                                         activeColor: Theme.of(context)
//                                             .textTheme
//                                             .bodySmall!
//                                             .color,
//                                       ),
//                                     )),
//                                 Flexible(
//                                   flex: 1,
//                                   child: Container(
//                                     alignment: Alignment.center,
//                                     child: FittedBox(
//                                       child: AutoSizeText(
//                                         "${_valueSlider.toStringAsFixed(0)}dpi",
//                                         maxLines: 1,
//                                         style: TextStyle(
//                                           color: Theme.of(context)
//                                               .textTheme
//                                               .bodySmall!
//                                               .color,
//                                           height: 13 / 20,
//                                           fontWeight: FontWeight.w600,
//                                           fontFamily: FONT_GOOGLESANS,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 )
//                               ]),
//                             ),
//                           )
//                         ],
//                       ),
//                   ],
//                 ),
//                 // button ( save to , save to library)
//                 Flex(
//                   direction: Axis.horizontal,
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     Flexible(
//                       child: WButtonFilled(
//                         height: 54,
//                         message: "Save to...",
//                         backgroundColor:
//                             isDarkMode ? primaryDark1 : primaryLight1,
//                         onPressed: () async {
//                           await _onSaveTo(_fileConverted,
//                               "passport_${randomInt()}.${LIST_FORMAT_IMAGE[_indexSelectedFormat].toLowerCase()}");
//                         },
//                       ),
//                     ),
//                     WSpacer(width: 10),
//                     Flexible(
//                       child: WButtonFilled(
//                         height: 54,
//                         message: "Save to Library",
//                         backgroundColor: isDarkMode ? white : black,
//                         textColor: isDarkMode ? black : white,
//                         onPressed: () async {
//                           bool isAllowed = false;
//                           PermissionStatus storageStatus;
//                           int sdkVersion =
//                               (await DeviceInfoPlugin().androidInfo)
//                                   .version
//                                   .sdkInt;

//                           if (sdkVersion >= 33) {
//                             isAllowed = true;
//                           } else {
//                             storageStatus = await Permission.storage.status;
//                             if (storageStatus.isGranted ||
//                                 storageStatus.isLimited) {
//                               isAllowed = true;
//                             } else {
//                               PermissionStatus requestPermission;
//                               requestPermission =
//                                   await Permission.storage.request();
//                               if (requestPermission.isGranted) {
//                                 isAllowed = true;
//                               }
//                             }
//                           }
//                           if (isAllowed) {
//                             await _onSaveToLibrary(
//                               _fileConverted,
//                             );
//                           }
//                         },
//                       ),
//                     ),
//                   ],
//                 )
//               ]),
//         ),
//       ],
//     );
//   }

//   Widget _buildPreviewExport(
//     bool isDarkMode,
//     String title, {
//     Color? textColor,
//   }) {
//     return Container(
//         alignment: Alignment.center,
//         child: AutoSizeText(
//           title,
//           maxLines: 1,
//           minFontSize: 10,
//           maxFontSize: 13,
//           style: TextStyle(
//             color: textColor ?? (isDarkMode ? white07 : black07),
//             height: 13 / 18.2,
//             fontWeight: FontWeight.w600,
//             fontFamily: FONT_GOOGLESANS,
//           ),
//         ));
//   }

//   Widget _buildLinePreviewExport() {
//     return Container(
//       height: 20,
//       color: grey.withValues(alpha:0.5),
//       width: 1,
//       // margin: const EdgeInsets.symmetric(horizontal: 10),
//     );
//   }
// }
