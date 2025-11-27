import 'dart:io';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_image_filters/flutter_image_filters.dart';
import 'package:passport_photo_2/commons/shaders/black_to_transparent_shader.dart';
import 'package:passport_photo_2/helpers/log_custom.dart';
import 'package:passport_photo_2/helpers/native_bridge/method_channel.dart';
import 'package:path_provider/path_provider.dart';

class RemoveBackgroundHelpers {
  ///
  Future<File?> cutBackgroundRemoverWithMethodChannel(
    String resizedPath,
  ) async {
    try {
      String pathBlackWhite =
          "${(await getExternalStorageDirectory())!.path}/black_white.png";

      BlackToTransparentConfiguration config =
          BlackToTransparentConfiguration();

      ///Ảnh đen trắng
      TextureSource textureBlackWhite =
          await TextureSource.fromFile(File(pathBlackWhite));

      /// Ảnh có nền trong suốt.MASK IMAGE
      Image imageObjectMaskNenTrongsuot =
          await config.export(textureBlackWhite, textureBlackWhite.size);
      final ByteData? finalMaskNenTrongsuot = await imageObjectMaskNenTrongsuot
          .toByteData(format: ImageByteFormat.png);
      String scaledTransparentPath =
          "${(await getExternalStorageDirectory())!.path}/scaled_transparent_mask.png";

      final outputMask = File(scaledTransparentPath);
      await outputMask.writeAsBytes(
        finalMaskNenTrongsuot!.buffer.asUint8List(),
        flush: true,
      );
      String transparentPath = scaledTransparentPath;
      // "${(await getExternalStorageDirectory())!.path}/transparent_mask.png";
      // TextureSource ttsOriginal =
      //     await TextureSource.fromFile(File(originalPath));

      // MyMethodChannel.resizeAndResoluteImage(
      //   scaledTransparentPath,
      //   1,
      //   [ttsOriginal.width.toDouble(), ttsOriginal.height.toDouble()],
      //   [1, 1],
      //   outPath: transparentPath,
      //   quality: 90,
      // );

      String outputPath =
          "${(await getExternalStorageDirectory())!.path}/removed_bg.png";

      await MyMethodChannel.maskTwoImage(
        resizedPath,
        transparentPath,
        outputPath,
      ); // tra ve anh voi kich thuoc ban dau

      return File(outputPath);
    } catch (e) {
      print("cutBackgroundRemoverWithShader: ${e}");
      consolelog("cutBackgroundRemoverWithShader: ${e}");
      return null;
    }
  }

  Future<File?> cutBackgroundRemoverWithMethodChannelWithOriginalSize(
    String originalPath,
  ) async {
    try {
      String pathBlackWhite =
          "${(await getExternalStorageDirectory())!.path}/black_white.png";
      // TextureSource ttsBlackWhite =
      //     await TextureSource.fromFile(File(pathBlackWhite));

      TextureSource ttsOriginal =
          await TextureSource.fromFile(File(originalPath));

      BlackToTransparentConfiguration config =
          BlackToTransparentConfiguration();
      // scale into original size
      String pathBlackWhiteOriginalSize =
          "${(await getExternalStorageDirectory())!.path}/black_white_orin_size.png";

      File? blackWhiteOriginalSizeFile =
          await MyMethodChannel.resizeAndResoluteImage(
       inputPath:  pathBlackWhite,
       format:  1,
       listWH:  [ttsOriginal.width.toDouble(), ttsOriginal.height.toDouble()],
      scaleWH:   [1, 1],
        outPath: pathBlackWhiteOriginalSize,
        quality: 90,
      );

      ///Ảnh đen trắng
      TextureSource textureBlackWhite =
          await TextureSource.fromFile(blackWhiteOriginalSizeFile!);

      /// Ảnh có nền trong suốt.MASK IMAGE
      Image imageObjectMaskNenTrongsuot =
          await config.export(textureBlackWhite, textureBlackWhite.size);

      final ByteData? finalMaskNenTrongsuot = await imageObjectMaskNenTrongsuot
          .toByteData(format: ImageByteFormat.png);
      String scaledTransparentPathOriginalSize =
          "${(await getExternalStorageDirectory())!.path}/transparent_mask_orin_size.png";

      final outputMask = File(scaledTransparentPathOriginalSize);
      await outputMask.writeAsBytes(
        finalMaskNenTrongsuot!.buffer.asUint8List(),
        flush: true,
      );

      String bgRemovedPath =
          "${(await getExternalStorageDirectory())!.path}/removed_bg_orin_size.png";

      await MyMethodChannel.maskTwoImage(
        originalPath,
        scaledTransparentPathOriginalSize,
        bgRemovedPath,
      ); // tra ve anh voi kich thuoc ban dau

      return File(bgRemovedPath);
    } catch (e) {
      print("cutBackgroundRemoverWithShader: ${e}");
      consolelog("cutBackgroundRemoverWithShader: ${e}");
      return null;
    }
  }

  // /// Sử dung để cắt ảnh gốc thành ảnh mới, trong đó 1 phần ảnh được giữ lại tuỳ theo
  // Future<File?> cutBackgroundRemover(String originalPath) async {
  //   try {
  //     String pathBlackWhite =
  //         "${(await getExternalStorageDirectory())!.path}/temp.png";

  //     /// Ảnh gốc
  //     TextureSource textureOriginal =
  //         await TextureSource.fromFile(File(originalPath));

  //     ///Ảnh đen trắng
  //     TextureSource textureBlackWhite =
  //         await TextureSource.fromFile(File(pathBlackWhite));

  //     PictureRecorder pictureRecorder = PictureRecorder();
  //     Canvas canvas = Canvas(pictureRecorder);
  //     //vẽ ảnh gốc
  //     canvas.drawImage(textureOriginal.image, Offset.zero,
  //         Paint()..blendMode = BlendMode.src);

  //     // scale ảnh trong suốt và vẽ ảnh trong suốt đó
  //     canvas.save();
  //     canvas.scale(
  //       textureOriginal.width / textureBlackWhite.width,
  //       textureOriginal.height / textureBlackWhite.height,
  //     );
  //     canvas.drawImage(
  //       textureBlackWhite.image,
  //       Offset.zero,
  //       Paint()
  //         ..blendMode = BlendMode.dstIn
  //         ..colorFilter = const ColorFilter.matrix(
  //             [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 1, 0, 0]),
  //     );
  //     canvas.restore();

  //     Picture picture = pictureRecorder.endRecording();
  //     Image finalImage = picture.toImageSync(
  //         textureOriginal.image.width, textureOriginal.image.height);
  //     final ByteData? finalBytes =
  //         await finalImage.toByteData(format: ImageByteFormat.png);
  //     String outputPath =
  //         "${(await getExternalStorageDirectory())!.path}/$ADJUST_PROCESSING_IMAGE_NAME.png";
  //     final output = File(outputPath);
  //     File result = await output.writeAsBytes(finalBytes!.buffer.asUint8List(),
  //         flush: true);
  //     return result;
  //   } catch (e) {
  //     print("cutBackgroundRemover: ${e}");
  //     consolelog("cutBackgroundRemover: ${e}");
  //     return null;
  //   }
  // }

  // Future<File?> cutBackgroundRemoverWithShader(String originalPath) async {
  //   try {
  //     String pathBlackWhite =
  //         "${(await getExternalStorageDirectory())!.path}/temp.png";

  //     BlackToTransparentConfiguration config =
  //         BlackToTransparentConfiguration();

  //     /// Ảnh gốc
  //     TextureSource textureOriginal =
  //         await TextureSource.fromFile(File(originalPath));
  //     // Image imageOriginal =
  //     //     await config.export(textureOriginal, textureOriginal.size);
  //     // final ByteData? finalOrignal =
  //     //     await imageOriginal.toByteData(format: ImageByteFormat.png);
  //     // String outputPathOriginal =
  //     //     "${(await getExternalStorageDirectory())!.path}/original_image.png";
  //     // final outputOriginal = File(outputPathOriginal);
  //     // File resultOriginal = await outputOriginal
  //     //     .writeAsBytes(finalOrignal!.buffer.asUint8List(), flush: true);

  //     ///Ảnh đen trắng
  //     TextureSource textureBlackWhite =
  //         await TextureSource.fromFile(File(pathBlackWhite));

  //     /// Ảnh có nền trong suốt.MASK IMAGE
  //     Image imageObjectMaskNenTrongsuot =
  //         await config.export(textureBlackWhite, textureBlackWhite.size);
  //     // final ByteData? finalMaskNenTrongsuot = await imageObjectMaskNenTrongsuot
  //     //     .toByteData(format: ImageByteFormat.png);
  //     // String outputPathMask =
  //     //     "${(await getExternalStorageDirectory())!.path}/mask.png";
  //     // final outputMask = File(outputPathMask);
  //     // File resultMask = await outputMask
  //     //     .writeAsBytes(finalMaskNenTrongsuot!.buffer.asUint8List(), flush: true);

  //     PictureRecorder pictureRecorder = PictureRecorder();
  //     Canvas canvas = Canvas(pictureRecorder);
  //     //vẽ ảnh gốc
  //     // canvas.drawColor(const Color.fromRGBO(255, 255, 255, 1), BlendMode.src);
  //     canvas.drawImage(textureOriginal.image, Offset.zero,
  //         Paint()..blendMode = BlendMode.src);
  //     // scale ảnh trong suốt và vẽ ảnh trong suốt đó
  //     canvas.save();
  //     canvas.scale(
  //       textureOriginal.width / imageObjectMaskNenTrongsuot.width,
  //       textureOriginal.height / imageObjectMaskNenTrongsuot.height,
  //     );
  //     canvas.drawImage(imageObjectMaskNenTrongsuot, Offset.zero,
  //         Paint()..blendMode = BlendMode.dstIn);
  //     canvas.restore();

  //     Picture picture = pictureRecorder.endRecording();
  //     Image finalImage = picture.toImageSync(
  //         textureOriginal.image.width, textureOriginal.image.height);
  //     final ByteData? finalBytes =
  //         await finalImage.toByteData(format: ImageByteFormat.png);
  //     String outputPath =
  //         "${(await getExternalStorageDirectory())!.path}/final_image.png";
  //     final output = File(outputPath);
  //     File result = await output.writeAsBytes(
  //         // (await imageObjectMaskNenTrongsuot.toByteData(format: ImageByteFormat.png))!
  //         finalBytes!.buffer.asUint8List(),
  //         flush: true);
  //     return result;
  //   } catch (e) {
  //     print("cutBackgroundRemoverWithShader: ${e}");
  //     consolelog("cutBackgroundRemoverWithShader: ${e}");
  //     return null;
  //   }
  // }
}
