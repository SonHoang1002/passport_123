import 'dart:io';
import "dart:ui" as ui;
import 'package:passport_photo_2/helpers/file_helpers.dart';
import 'package:passport_photo_2/models/country_passport_model.dart';
import 'package:passport_photo_2/models/crop_model.dart';

class ProjectModel {
  /// from import
  /// original size
  File? selectedFile;

  /// from import
  ///
  /// scale size
  ///
  File? bgRemovedFile;

  /// scale size
  File? scaledSelectedFile;

  ui.Image? scaledSelectedImage;

  /// generated from adjust screen
  /// orignal size
  ui.Image? uiImageAdjusted;

  /// generated from crop screen with
  ui.Image? uiImageCropped;

  /// orignal size with ratio of passport
  File? croppedFile;

  /// generated from finish screen ( unused )
  ///
  File? exportedFile;

  ///
  /// May be: File, Color, null
  ///
  dynamic background;

  /// [0.0, 0.0, 1.0 ]: min, default, max
  double brightness;

  List<double> listBlurShadow;

  /// adjust properties ( exposure, constrast, saturation, shadow, highlight, sharpen )
  List<double> listAdjustValue;

  //
  CountryModel? countryModel;

  CropModel? cropModel;

  /// scale size
  ui.Image? scaledCroppedImage;

  ProjectModel({
    this.selectedFile,
    this.bgRemovedFile,
    this.scaledSelectedFile,
    this.scaledSelectedImage,
    this.background = "",
    this.brightness = 0.5,
    this.listAdjustValue = const [],
    this.listBlurShadow = const [0.15, 0.1], // 0: left, 1: right
    this.countryModel,
    this.cropModel,
    this.scaledCroppedImage,
  });
  void resetAllImage() async {
    selectedFile = scaledSelectedFile = bgRemovedFile = uiImageAdjusted =
        croppedFile = exportedFile = scaledCroppedImage = null;
    await deleteAllTempFile();
  }

  /// reset adjustedImage, croppedImage, exportedFile
  void resetACEImage() {
    uiImageAdjusted = croppedFile = exportedFile = null;
  }
}
