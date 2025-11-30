import 'dart:io';
import 'dart:ui';
import 'package:flutter_image_filters/flutter_image_filters.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/commons/shaders/brightness_custom.dart';
import 'package:pass1_/helpers/log_custom.dart';
import 'package:pass1_/models/project_model.dart';

Future<Image?> exportAdjustedImage(
  Image uiImageBg, // original size
  Image uiImageObject, // scaled size
  Offset offsetObject,
  Size previewFrame, { // khung hien thi anh,
  bool needBlurAndShadow = false,
  List<Offset> listOffsetBlur = const [],
  List<Paint> listPaint = const [],
}) async {
  try {
    // TextureSource tsBackground = await TextureSource.fromFile(fileBg);
    Offset mainOffsetObject = Offset(
      (offsetObject.dx / previewFrame.width) * uiImageObject.width,
      (offsetObject.dy / previewFrame.height) * uiImageObject.height,
    );
    // TextureSource tsObject = await TextureSource.fromFile(fileObject);
    PictureRecorder pictureRecorder = PictureRecorder();
    Canvas canvas = Canvas(pictureRecorder);
    // draw with original size
    canvas.drawImage(
      uiImageBg,
      Offset.zero,
      Paint()..blendMode = BlendMode.src,
    );
    double scaleCanvasWidth = uiImageBg.width / uiImageObject.width;
    double scaleCanvasHeight = uiImageBg.height / uiImageObject.height;

    canvas.save();
    canvas.scale(scaleCanvasWidth, scaleCanvasHeight);
    // draw blur with scale size
    if (needBlurAndShadow) {
      for (int i = 0; i < listOffsetBlur.length; i++) {
        // convert to offset on preview frame
        Offset offsetBlurShadow = Offset(
          (listOffsetBlur[i].dx / previewFrame.width) * uiImageObject.width +
              mainOffsetObject.dx,
          (listOffsetBlur[i].dy / previewFrame.height) * uiImageObject.height +
              mainOffsetObject.dy,
        );
        canvas.drawImage(uiImageObject, offsetBlurShadow, listPaint[i]);
      }
      canvas.drawImage(
        uiImageObject,
        mainOffsetObject,
        PAINT_BLURRED..maskFilter = const MaskFilter.blur(BlurStyle.inner, 0.2),
      );
    }
    // draw with scaled size
    canvas.drawImage(
      uiImageObject,
      mainOffsetObject,
      Paint()..blendMode = BlendMode.srcOver,
    );
    canvas.restore();

    Picture picture = pictureRecorder.endRecording();
    Image adjustedImage = picture.toImageSync(
      uiImageBg.width,
      uiImageBg.height,
    );
    consolelog(
      "adjustedImage adjustedImage ${adjustedImage.width} - ${adjustedImage.height}",
    );
    return adjustedImage;
  } catch (e) {
    print("exportAdjustedImage error: $e");
    consolelog("exportAdjustedImage error: $e");
    return null;
  }
}

Future<Image> onExportObject(
  ShaderConfiguration shaderConfiguration,
  File originalImage, { // scaled size
  TextureSource? textureConverted,
}) async {
  final textureOnlyObject = await TextureSource.fromFile(originalImage);
  Image image = await shaderConfiguration.export(
    textureOnlyObject,
    textureOnlyObject.size,
  );
  return image;
}

// Future<Image> onExportObject(
//   ShaderConfiguration shaderConfiguration,
//   File bgRemovedImage, // scaled size
//   {
//   TextureSource? textureConverted,
// }) async {
//   final textureOnlyObject = await TextureSource.fromFile(bgRemovedImage);
//   Image image = await shaderConfiguration.export(
//     textureOnlyObject,
//     textureOnlyObject.size,
//   );
//   return image;
// }

Future<Image> onExportBackground(
  ProjectModel projectModel,
  CustomBrightnessShaderConfiguration brightnessShaderConfiguration,
) async {
  final stopwatch = Stopwatch()..start();
  final textureOriginal = await TextureSource.fromFile(
    projectModel.selectedFile!,
  ); // original size

  final bg = projectModel.background;
  consolelog(
    "onExportAdjust call bgbg: ${brightnessShaderConfiguration.getBrightness}",
  );
  Image image;
  if (bg is Color) {
    // shaderConfiguration = FillColorConfiguration()..color = bg;
    PictureRecorder recorder = PictureRecorder();
    Canvas canvas = Canvas(recorder);
    Paint paint = Paint()..color = bg;
    canvas.drawPaint(paint);
    image = await recorder.endRecording().toImage(
      textureOriginal.size.width.toInt(),
      textureOriginal.size.height.toInt(),
    );
  } else {
    image = await brightnessShaderConfiguration.export(
      textureOriginal,
      textureOriginal.size,
    );
  }

  // final ByteData? byteData =
  //     await image.toByteData(format: ImageByteFormat.png);
  // Uint8List uint8list = byteData!.buffer.asUint8List();
  // final outPath =
  //     "${(await getExternalStorageDirectory())!.path}/adjusted_bg.png";
  // final result = await File(outPath).writeAsBytes(uint8list);
  stopwatch.stop();
  print("onExportBackground Time: ${stopwatch.elapsedMilliseconds}");
  return image;
}
