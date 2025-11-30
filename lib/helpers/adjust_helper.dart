import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/commons/shaders/brightness_custom.dart';
import 'package:pass1_/commons/shaders/combine_shader.dart';
import 'package:pass1_/helpers/export_images/export_adjusted.dart';
import 'package:pass1_/models/project_model.dart';
import 'package:path_provider/path_provider.dart';

class AdjustHelpers {
  // tim so lon nhat chia het cho targetDivisor va nho hon so da cho
  // tim so nho nhat chia het cho targetDivisor va lon hon( hoac nho hon ) so da cho
  static int getNearestNumberAndDivisibleTargetNumber(
    double currentNumber,
    int targetDivisor, {
    bool isGreatThan = true,
  }) {
    int integerResult;
    if (isGreatThan) {
      integerResult = currentNumber.ceil();
    } else {
      integerResult = currentNumber.floor();
    }
    while (integerResult % targetDivisor != 0) {
      if (isGreatThan) {
        integerResult++;
      } else {
        integerResult--;
      }
    }

    return integerResult;
  }

  static Future<void> onExportAdjust({
    required ProjectModel projectModel,
    required CustomBrightnessShaderConfiguration brightnessShaderConfiguration,
    required GlobalKey keyConvertedImage,
    required CombineShaderCustomConfiguration combineShaderCustomConfiguration,
    required int indexBackgroundSelected,
    required imageSize,
    required TransformationController transformationController,
    required Size newSizeConvertedImage,
    required Size standardOriginalImageFramePreviewSize,
    required void Function(ProjectModel model) onUpdateProject,
    required Paint? paintBlurShadowLeft,
    required Paint? paintBlurShadowRight,
    required List<double> listValueForShader,
  }) async {
    Size? _newSizeConvertedImage;
    RenderObject? renderObject = keyConvertedImage.currentContext
        ?.findRenderObject();
    if (renderObject != null) {
      _newSizeConvertedImage = (renderObject as RenderBox).size;
    }
    // combineShaderCustomConfiguration.log();
    // List<double> newListValueForShader = listValueForShader.toList();
    // newListValueForShader.last = listValueForShader.last *
    //     5; // sao lại khác so với sharpen của preview ????
    // CombineShaderCustomConfiguration customCombineShader =
    //     combineShaderCustomConfiguration.copyWith(newListValueForShader);
    // customCombineShader.log();
    List<ui.Image> results = await Future.wait([
      onExportBackground(projectModel, brightnessShaderConfiguration),
      onExportObject(
        combineShaderCustomConfiguration,
        projectModel.bgRemovedFile!,
      ),
    ]);
    ui.Image adjustedBgFile = results[0];
    Uint8List uint8listBg = (await adjustedBgFile.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    File(
      "${(await getExternalStorageDirectory())!.path}/bg.png",
    ).writeAsBytesSync(uint8listBg);

    ui.Image adjustObjectFile = results[1];
    Uint8List uint8listObj = (await adjustObjectFile.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    String scaledObjectPath =
        "${(await getExternalStorageDirectory())!.path}/scaled_object.png";
    File(scaledObjectPath).writeAsBytesSync(uint8listObj);

    Offset objectOffset;
    if (indexBackgroundSelected != 0) {
      final vector3 = transformationController.value.getTranslation();
      objectOffset = Offset(vector3.x, vector3.y);
    } else {
      objectOffset = const Offset(0, 0);
    }
    Size size = imageSize;

    ui.Image? result = await exportAdjustedImage(
      adjustedBgFile,
      adjustObjectFile,
      objectOffset,
      _newSizeConvertedImage ?? newSizeConvertedImage,
      needBlurAndShadow: [1, 2, 3].contains(indexBackgroundSelected),
      listOffsetBlur: [
        Offset(
          SHADOW_EDGE_INSET_LEFT.left /
              standardOriginalImageFramePreviewSize.width *
              size.width,
          SHADOW_EDGE_INSET_LEFT.top /
              standardOriginalImageFramePreviewSize.height *
              size.height,
        ),
        Offset(
          SHADOW_EDGE_INSET_RIGHT.left /
              standardOriginalImageFramePreviewSize.width *
              size.width,
          SHADOW_EDGE_INSET_RIGHT.top /
              standardOriginalImageFramePreviewSize.height *
              size.height,
        ),
      ],
      listPaint: [
        (paintBlurShadowLeft ?? PAINT_BLURREDRED_SHADOW_LEFT)
          ..colorFilter = ColorFilter.mode(
            black.withValues(alpha: projectModel.listBlurShadow[0]),
            BlendMode.srcIn,
          ),
        (paintBlurShadowRight ?? PAINT_BLURREDRED_SHADOW_RIGHT)
          ..colorFilter = ColorFilter.mode(
            black.withValues(alpha: projectModel.listBlurShadow[1]),
            BlendMode.srcIn,
          ),
      ],
    );

    onUpdateProject(projectModel..uiImageAdjusted = result);
  }
}
