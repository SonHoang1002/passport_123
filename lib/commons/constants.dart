import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:pass1_/commons/extension.dart';
import 'package:pass1_/helpers/random_number.dart';
import 'package:pass1_/models/adjust_subject_model.dart';
import 'package:pass1_/models/country_passport_model.dart';
import 'package:pass1_/models/export_size_model.dart';
import 'package:pass1_/models/image_item_model.dart';
import 'package:pass1_/models/instruction_model.dart';
import 'package:pass1_/models/step_model.dart';
import 'package:pdf/pdf.dart';

// ignore: constant_identifier_names
const Map<int, String> DATA_SEGMENT_RESOLUTION_1 = {
  0: "600dpi",
  1: "1200dpi",
  2: "Custom",
};
// ignore: constant_identifier_names
const List<double> LIST_MIN_MAX_RESOLUTION_1 = [300, 1800];

// ignore: constant_identifier_names
const Map<int, String> DATA_SEGMENT_RESOLUTION_2 = {
  0: "300dpi",
  1: "600dpi",
  2: "Custom",
};
const List<double> LIST_MIN_MAX_RESOLUTION_2 = [300, 600];

const double MB_TO_KB = 1024;
// ignore: constant_identifier_names
const Size SIZE_DIALOG_TOOLTIP = Size(136, 96);
// ignore: constant_identifier_names
const int ID_CUSTOM_COUNTRY_MODEL = 10000;
// ignore: constant_identifier_names
const String SHARE_APP_LINK =
    "https://play.google.com/store/apps/details?id=com.tapuniverse.passportphoto";
// ignore: constant_identifier_names
const Size MIN_SIZE = Size(360, 720);
// ignore: constant_identifier_names
const String PATH_PREFIX_ICON = "assets/icons/";
// ignore: constant_identifier_names
const String PATH_PREFIX_IMAGE = "assets/images/";
// ignore: constant_identifier_names
const String FONT_GOOGLESANS = "GoogleSans";

// ignore: non_constant_identifier_names
List<ItemImage> LIST_ITEM_IMAGE = [
  ItemImage(
    path: "${PATH_PREFIX_IMAGE}image_example.jpg",
    id: randomInt().toString(),
  ),
  ItemImage(
    path: "${PATH_PREFIX_IMAGE}image_example.jpg",
    id: randomInt().toString(),
  ),
];

// ignore: non_constant_identifier_names
List<InstructionModel> LIST_INSTRUCTION_MODEL = [
  InstructionModel(
    id: randomInt(),
    title: "Remove hat and glasses",
    pathImageOrigin: "${PATH_PREFIX_IMAGE}image_instruction_origin_1.jpg",
    pathImageDone: "${PATH_PREFIX_IMAGE}image_instruction_done_1.jpg",
  ),
  InstructionModel(
    id: randomInt(),
    title: "Photo with clear background is preferred",
    pathImageOrigin: "${PATH_PREFIX_IMAGE}image_instruction_origin_2.jpg",
    pathImageDone: "${PATH_PREFIX_IMAGE}image_instruction_done_2.jpg",
  ),
  InstructionModel(
    id: randomInt(),
    title: "Lighting both sides of the face",
    pathImageOrigin: "${PATH_PREFIX_IMAGE}image_instruction_origin_3.jpg",
    pathImageDone: "${PATH_PREFIX_IMAGE}image_instruction_done_3.jpg",
  ),
];

// ignore: non_constant_identifier_names
List<StepModel> LIST_STEP_SELECTION = [
  StepModel(
    id: 0,
    listMediaSrc: ["${PATH_PREFIX_ICON}icon_step_import.png"],
    title: "Import",
  ),
  StepModel(
    id: 1,
    listMediaSrc: ["${PATH_PREFIX_ICON}icon_step_adjust.png"],
    title: "Adjust",
  ),
  StepModel(
    id: 2,
    listMediaSrc: ["${PATH_PREFIX_ICON}icon_step_crop.png"],
    title: "Crop",
  ),
  StepModel(
    id: 3,
    listMediaSrc: ["${PATH_PREFIX_ICON}icon_step_finish.png"],
    title: "Finish",
  ),
];

// ignore: constant_identifier_names
const SHARE_PREF_KEY_GET_STATED = "key_get_started";
// ignore: constant_identifier_names
const SHARE_PREF_KEY_COUNTRY = "key_selected_country";

// ignore: constant_identifier_names
const double WIDTH_DIALOG = 180;

// ignore: constant_identifier_names
const double HEIGHT_OF_DIALOG_ITEM = 40.0;

const thumbColorSegments = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFFFFFFF),
  darkColor: Color.fromRGBO(255, 255, 255, 1),
);

// ignore: non_constant_identifier_names
List<Color> LIST_BACKGROUND_ADJUST = [
  const Color.fromRGBO(74, 149, 242, 1), // == 4A95F2 (blue)
  const Color.fromRGBO(255, 255, 255, 1), // == FAF9F8 (white),
  const Color.fromRGBO(224, 51, 26, 1), // == E0331A (red),
];

// ignore: non_constant_identifier_names
List<AdjustSubjectModel> LIST_ADJUST_SUBJECT_MODEL = [
  AdjustSubjectModel(
    title: "EXPOSURE",
    id: 0,
    listMediaSrc: [
      "${PATH_PREFIX_ICON}icon_subject_exposure_light.png",
      "${PATH_PREFIX_ICON}icon_subject_exposure_dark.png",
    ],
    rootRatioValue: 0.5,
    dividers: 100,
    currentRatioValue: 0.5,
  ),
  AdjustSubjectModel(
    title: "CONTRAST",
    id: 1,
    listMediaSrc: [
      "${PATH_PREFIX_ICON}icon_subject_contrast_light.png",
      "${PATH_PREFIX_ICON}icon_subject_contrast_dark.png",
    ],
    rootRatioValue: 0.5,
    currentRatioValue: 0.5,
    dividers: 100,
  ),
  AdjustSubjectModel(
    title: "SATURATION",
    id: 2,
    listMediaSrc: [
      "${PATH_PREFIX_ICON}icon_subject_saturation_light.png",
      "${PATH_PREFIX_ICON}icon_subject_saturation_dark.png",
    ],
    rootRatioValue: 0.5,
    currentRatioValue: 0.5,
    dividers: 100,
  ),
  AdjustSubjectModel(
    title: "SHADOW",
    id: 3,
    listMediaSrc: [
      "${PATH_PREFIX_ICON}icon_subject_shadow_light.png",
      "${PATH_PREFIX_ICON}icon_subject_shadow_dark.png",
    ],
    rootRatioValue: 0.0,
    currentRatioValue: 0.0,
    dividers: 100,
  ),
  AdjustSubjectModel(
    title: "HIGHLIGHT",
    id: 4,
    listMediaSrc: [
      "${PATH_PREFIX_ICON}icon_subject_highlight_light.png",
      "${PATH_PREFIX_ICON}icon_subject_highlight_dark.png",
    ],
    rootRatioValue: 1.0,
    currentRatioValue: 1.0,
    dividers: 100,
  ),
  AdjustSubjectModel(
    title: "WARMTH",
    id: 5,
    listMediaSrc: [
      "${PATH_PREFIX_ICON}icon_subject_warmth_light.png",
      "${PATH_PREFIX_ICON}icon_subject_warmth_dark.png",
    ],
    rootRatioValue: 0.5,
    currentRatioValue: 0.5,
    dividers: 100,
  ),
  AdjustSubjectModel(
    title: "SHARPEN",
    id: 6,
    listMediaSrc: [
      "${PATH_PREFIX_ICON}icon_subject_sharpen_light.png",
      "${PATH_PREFIX_ICON}icon_subject_sharpen_dark.png",
    ],
    rootRatioValue: 0.0,
    currentRatioValue: 0.0,
    dividers: 100,
  ),
];

const String titleInch = "inch";
// ignore: non_constant_identifier_names
const String titleCentimet = "cm";
// ignore: non_constant_identifier_names
const String titleMinimet = "mm";
// ignore: non_constant_identifier_names
const String titlePoint = "pt";
// ignore: non_constant_identifier_names
const String titlePixel = "px";

// ignore: non_constant_identifier_names
final Unit INCH = Unit(id: 0, title: titleInch, value: "”");
// ignore: non_constant_identifier_names
final Unit CENTIMET = Unit(id: 1, title: titleCentimet, value: "cm");
// ignore: non_constant_identifier_names
final Unit MINIMET = Unit(id: 2, title: titleMinimet, value: "mm");
// ignore: non_constant_identifier_names
final Unit POINT = Unit(id: 3, title: titlePoint, value: "pt");
// ignore: non_constant_identifier_names
final Unit PIXEL = Unit(id: 4, title: titlePixel, value: "px");

// ignore: non_constant_identifier_names
final List<Unit> LIST_UNIT = [INCH, CENTIMET, MINIMET, POINT, PIXEL];
// ignore: constant_identifier_names
const String JPG = "JPG";
// ignore: constant_identifier_names
const String PNG = "PNG";
// ignore: constant_identifier_names
const String WEBP = "WEBP";
// ignore: constant_identifier_names
const String HEIC = "HEIC";
// ignore: constant_identifier_names
const List<String> LIST_FORMAT_IMAGE = [JPG, PNG, WEBP, HEIC];

// ignore: constant_identifier_names
const List<String> LIST_SUPPORTED_TYPE = ["jpeg", "jpg", "png", "heic"];

// ignore: non_constant_identifier_names
List<int> LIST_COPY_NUMBER_SELECTION = List.generate(101, (index) => index);
// ignore: constant_identifier_names
const List<String> LIST_POSITION_FACE = ["Head", "Eyes", "Chin"];
// ignore: constant_identifier_names
const String ADJUST_PROCESSING_IMAGE_NAME = "bg_removed_image";
// ignore: constant_identifier_names
// const String CROP_PROCESSING_IMAGE_NAME = "adjusted_image";
// ignore: constant_identifier_names
const String CROPPED_PROCESSING_IMAGE_NAME = "cropped_image";
// ignore: constant_identifier_names
const String FINISH_IMAGE_NAME = "finished_image";
// ignore: constant_identifier_names
const String FINISH_IMAGE_NAME_FOR_PDF = "finished_image_for_pdf";

// ignore: constant_identifier_names
const Curve CUBIC_CURVE = Cubic(0.25, 0, 0, 1);

double marginAll = 2.0 * 75 / 2.54;
// ignore: non_constant_identifier_names
PdfPageFormat A2 = PdfPageFormat(1190.74, 1682.79, marginAll: marginAll);
// ignore: non_constant_identifier_names
PdfPageFormat A1 = PdfPageFormat(1682.79, 2383.635, marginAll: marginAll);
// ignore: non_constant_identifier_names
PdfPageFormat A0 = PdfPageFormat(2383.635, 3371.515, marginAll: marginAll);

// ignore: constant_identifier_names
const double MAX_SIZE_EXPORT_IMAGE_NORMAL = 9000;
// ignore: constant_identifier_names
const double MAX_SIZE_EXPORT_IMAGE_WEAK = 7000;

/// Kích thước tối đa mà thiết bị có thể xử lý
// ignore: constant_identifier_names
const double LIMITATION_DIMENSION_BY_PIXEl = 8000;

// ignore: constant_identifier_names
const Size SIZE_EXAMPLE = Size(411.4, 891.4);

// ignore: constant_identifier_names
const EdgeInsets SHADOW_EDGE_INSET_LEFT = EdgeInsets.fromLTRB(-10, 15, 0, 0);
// ignore: constant_identifier_names
const EdgeInsets SHADOW_EDGE_INSET_RIGHT = EdgeInsets.fromLTRB(24, 20, 0, 0);

// ignore: non_constant_identifier_names
Paint PAINT_BLURRED = Paint()
  ..imageFilter = ImageFilter.blur(
    sigmaX: 20.0,
    sigmaY: 20.0,
    tileMode: TileMode.decal,
  );
// ignore: non_constant_identifier_names
Paint PAINT_BLURREDRED_SHADOW_LEFT = Paint()
  ..imageFilter = ImageFilter.blur(
    sigmaX: 15,
    sigmaY: 15,
    tileMode: TileMode.decal,
  )
// ..colorFilter = ColorFilter.mode(red.withValues(alpha:0.15), BlendMode.srcIn)
;
// ignore: non_constant_identifier_names
Paint PAINT_BLURREDRED_SHADOW_RIGHT = Paint()
  ..imageFilter = ImageFilter.blur(
    sigmaX: 30,
    sigmaY: 30,
    tileMode: TileMode.decal,
  )
// ..colorFilter = ColorFilter.mode(red.withValues(alpha:0.1), BlendMode.srcIn)
;

// 0.03 - x - 2x

// ignore: non_constant_identifier_names
List<CountryModel> LIST_COUNTRY_PASSPORT = [
  CountryModel(
    id: 0,
    title: "Afghanistan",
    listPassportModel: [
      PassportModel(
        id: 0,
        title: "Passport",
        width: 4.0,
        height: 4.5,
        ratioHead: 0,
        ratioEyes: 0,
        ratioChin: 0,
        unit: CENTIMET,
      ),
      PassportModel(
        id: 0,
        title: "ID card(e-tazkira)",
        width: 3.0,
        height: 4.0,
        ratioHead: 0,
        ratioEyes: 0,
        ratioChin: 0,
        unit: CENTIMET,
      ),
      PassportModel(
        id: 0,
        title: "Passport",
        width: 5.0,
        height: 5.0,
        ratioHead: 0,
        ratioEyes: 0,
        ratioChin: 0,
        unit: CENTIMET,
      ),
      PassportModel(
        id: 0,
        title: "Visa",
        width: 35.0,
        height: 45.0,
        ratioHead: 0,
        ratioEyes: 0,
        ratioChin: 0,
        unit: MINIMET,
      ),
      PassportModel(
        id: 0,
        title: "ID card(e-tazkira)",
        width: 3.0,
        height: 4.0,
        ratioHead: 0,
        ratioEyes: 0,
        ratioChin: 0,
        unit: CENTIMET,
      ),
    ],
  ),
];

// ignore: constant_identifier_names
const String DEFAULT_PASSPORT_COUNTRY = "United States";

// ignore: constant_identifier_names
const Map<int, String> EXPORT_SEGMENT_OBJECT = {0: "Photo", 1: "Paper"};

// ignore: constant_identifier_names
const Map<int, String> EXPORT_SEGMENT_COMPRESSION_IMAGE_FORMAT = {
  0: "JPG",
  1: "PNG",
  2: "PDF",
};

const double inch = 72.0;
const double cm = inch / 2.54;
const double mm = inch / 25.4;
List<ExportSizeModel> LIST_EXPORT_SIZE = [
  ExportSizeModel(
    uid: randomInt(),
    id: 0,
    title: "A3",
    size: Size(
      double.parse((29.7 * cm).roundWithUnit(fractionDigits: 1)),
      double.parse((42 * cm).roundWithUnit(fractionDigits: 1)),
    ),
    marginModel: MarginModel.marginAll(1.0 * cm), //2
    unit: POINT,
    spacingVertical: 0.5 / 10 * cm,
    spacingHorizontal: 0.5 / 10 * cm,
  ),
  ExportSizeModel(
    uid: randomInt(),
    id: 0,
    title: "A4",
    size: Size(
      double.parse((21.0 * cm).roundWithUnit(fractionDigits: 1)),
      double.parse((29.7 * cm).roundWithUnit(fractionDigits: 1)),
    ),
    marginModel: MarginModel.marginAll(1.0 * cm), //2
    spacingVertical: 0.5 / 10 * cm,
    spacingHorizontal: 0.5 / 10 * cm,
    unit: POINT,
  ),
  ExportSizeModel(
    uid: randomInt(),
    id: 0,
    title: "B5",
    size: const Size(6.9 * inch, 9.8 * inch),
    marginModel: MarginModel.marginAll(1.0 * cm), //2
    spacingVertical: 0.5 / 10 * cm,
    spacingHorizontal: 0.5 / 10 * cm,
    unit: POINT,
  ),
  ExportSizeModel(
    uid: randomInt(),
    id: 0,
    title: "JIS B5",
    size: const Size(7.17 * inch, 10.12 * inch),
    marginModel: MarginModel.marginAll(1.0 * cm), //2
    spacingVertical: 0.5 / 10 * cm,
    spacingHorizontal: 0.5 / 10 * cm,
    unit: POINT,
  ),
  ExportSizeModel(
    uid: randomInt(),
    id: 0,
    title: "Legal",
    size: const Size(8.5 * inch, 14.0 * inch),
    marginModel: MarginModel.marginAll(1.0 * cm), //inch
    spacingVertical: 0.5 / 10 * cm,
    spacingHorizontal: 0.5 / 10 * cm,
    unit: POINT,
  ),
  ExportSizeModel(
    uid: randomInt(),
    id: 0,
    title: "Tabloid",
    size: const Size(11 * inch, 17 * inch),
    marginModel: MarginModel.marginAll(1.0 * cm), //2
    spacingVertical: 0.5 / 10 * cm,
    spacingHorizontal: 0.5 / 10 * cm,
    unit: POINT,
  ),
  ExportSizeModel(
    uid: randomInt(),
    id: 0,
    title: "Letter",
    size: const Size(8.5 * inch, 11.0 * inch),
    marginModel: MarginModel.marginAll(1.0 * cm), //inch
    spacingVertical: 0.5 / 10 * cm,
    spacingHorizontal: 0.5 / 10 * cm,
    unit: POINT,
  ),
  ExportSizeModel(
    uid: randomInt(),
    id: 0,
    title: "Custom Size...",
    size: Size(
      double.parse((21.0 * cm).roundWithUnit(fractionDigits: 1)),
      double.parse((29.7 * cm).roundWithUnit(fractionDigits: 1)),
    ),
    marginModel: MarginModel.marginAll(1.0 * cm),
    spacingVertical: 0.5 / 10 * cm,
    spacingHorizontal: 0.5 / 10 * cm,
    unit: POINT,
  ),
];

// ignore: constant_identifier_names
const double PRINT_MARGIN_AROUND_IMAGE_BY_POINT = 0.5 / 10 / 2.54 * 72; // 0.5mm

// ignore: constant_identifier_names
const double PRINT_DEFAULT_DPI = 600;
// a = |1 1 1 1 1|                          |5|
//     |1 1 1 1 1|                          |6|
//     |1 1 1 1 1|        x                 |7|
//     |1 1 1 1 1|                          |8|

// ignore: constant_identifier_names
const double EPSILON_E5 = 1e-5;

// ignore: constant_identifier_names
const double EPSILON_E10 = 1e-10;
