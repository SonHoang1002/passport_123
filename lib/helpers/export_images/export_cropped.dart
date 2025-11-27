import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:passport_photo_2/commons/constants.dart';
import 'package:passport_photo_2/helpers/log_custom.dart';
import 'package:passport_photo_2/models/country_passport_model.dart';
import 'package:path_provider/path_provider.dart';

///
/// Trả ra ảnh có kích thước của original image nhưng theo tỉ lệ của passport
///
/// Ví dụ:   Size [4882 - 7052] -> Size [4882 -  6276] theo passport có tỉ lệ [35:45] (inch)
///
Future<List<dynamic>> exportCroppedImage({
  required ui.Image uiImageAjdusted, // original size
  required CountryModel countryModel,
  required double scaleByInteractView,
  required double rotation,
  required Matrix4 matrix,
  required Size imageSizePreview,
  required Size frameSize,
}) async {
  Stopwatch stopwatch = Stopwatch();
  stopwatch.start();

  // khoang cach ban dau khi build xong man hinh
  var khoangCachBanDauX = (imageSizePreview.width - frameSize.width) / 2;
  var khoangCachBanDauY = (imageSizePreview.height - frameSize.height) / 2;
  // CỐ ĐỊNH ẢNH
  // DI CHUYỂN KHUNG CANVAS THEO OFFSET ĐỂ VẼ ẢNH
  ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  Canvas canvas = Canvas(pictureRecorder);
  canvas.save();
  // vì căn giữa ảnh nên offset của image có thể không nằm điểm Offset(0,0) của khung ảnh,
  // do đó cần phải tính đoạn chệnh lệch và dịch chuyển canvas về điểm đầu của ảnh
  canvas.translate(
    (matrix.getTranslation().x - khoangCachBanDauX * scaleByInteractView) *
        uiImageAjdusted.width /
        imageSizePreview.width,
    (matrix.getTranslation().y - khoangCachBanDauY * scaleByInteractView) *
        uiImageAjdusted.width /
        imageSizePreview.width,
  );
  // scale theo InteractiveView
  canvas.scale(scaleByInteractView);
  // Tính toán dịch chuyển canvas về điểm trung tâm và xoay
  // https://stackoverflow.com/questions/51323233/flutter-how-to-rotate-an-image-around-the-center-with-canvas#:~:text=We%20thus%20first%20move%20the,position%2C%20with%20the%20rotation%20applied.
  // and preview alpha ben trong phan assets/images/
  final double r = sqrt(uiImageAjdusted.width * uiImageAjdusted.width +
          uiImageAjdusted.height * uiImageAjdusted.height) /
      2;
  final alpha = atan(uiImageAjdusted.height / uiImageAjdusted.width);
  final beta = alpha + rotation;
  final shiftY = r * sin(beta);
  final shiftX = r * cos(beta);
  final translateX = uiImageAjdusted.width / 2 - shiftX;
  final translateY = uiImageAjdusted.height / 2 - shiftY;
  canvas.translate(translateX, translateY);
  canvas.rotate(rotation);

  canvas.drawImage(
    uiImageAjdusted,
    Offset.zero,
    Paint()..blendMode = BlendMode.src,
  );
  canvas.restore();

  final picture = pictureRecorder.endRecording();
  int uiImageAjdustedWidth =
      frameSize.width * uiImageAjdusted.width ~/ imageSizePreview.width;
  int uiImageAjdusteHeight =
      frameSize.height * uiImageAjdusted.height ~/ imageSizePreview.height;

  ui.Image croppedImage = picture.toImageSync(
    uiImageAjdustedWidth,
    uiImageAjdusteHeight,
  );

  final ByteData? adjustedBytes =
      await croppedImage.toByteData(format: ui.ImageByteFormat.png);

  // save file
  final outPath =
      "${(await getExternalStorageDirectory())!.path}/$CROPPED_PROCESSING_IMAGE_NAME.png";
  final output = File(outPath);
  File result = await output.writeAsBytes(
    adjustedBytes!.buffer.asUint8List(),
  );
  stopwatch.stop();
  consolelog("exportCroppedImage Time:  ${stopwatch.elapsedMilliseconds}");
  return [result, croppedImage];
}

Future<File?> exportCroppedImage1({
  required ui.Image uiImageAjdusted,
  required CountryModel countryModel,
  required double scaleByInteractView,
  required double rotation,
  required Matrix4 matrix,
  required Size imageSizePreview,
  required Size frameSize,
}) async {
  // TextureSource textureAdjusted = await TextureSource.fromFile(fileAdjusted);
  Stopwatch stopwatch = Stopwatch();
  stopwatch.start();
  // khoang cach ban dau khi build xong man hinh
  var khoangCachBanDauX = (imageSizePreview.width - frameSize.width) / 2;
  var khoangCachBanDauY = (imageSizePreview.height - frameSize.height) / 2;
  // CỐ ĐỊNH ẢNH
  // DI CHUYỂN KHUNG CANVAS THEO OFFSET ĐỂ VẼ ẢNH
  ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  Canvas canvas = Canvas(pictureRecorder);
  canvas.save();
  // vì căn giữa ảnh nên offset của image có thể không nằm điểm Offset(0,0) của khung ảnh,
  // do đó cần phải tính đoạn chệnh lệch và dịch chuyển canvas về điểm đầu của ảnh
  canvas.translate(
    (matrix.getTranslation().x - khoangCachBanDauX * scaleByInteractView) *
        uiImageAjdusted.width /
        imageSizePreview.width,
    (matrix.getTranslation().y - khoangCachBanDauY * scaleByInteractView) *
        uiImageAjdusted.width /
        imageSizePreview.width,
  );
  // scale theo InteractiveView
  canvas.scale(scaleByInteractView);
  // Tính toán dịch chuyển canvas về điểm trung tâm và xoay
  // https://stackoverflow.com/questions/51323233/flutter-how-to-rotate-an-image-around-the-center-with-canvas#:~:text=We%20thus%20first%20move%20the,position%2C%20with%20the%20rotation%20applied.
  // and preview alpha ben trong phan assets/images/
  final double r = sqrt(uiImageAjdusted.width * uiImageAjdusted.width +
          uiImageAjdusted.height * uiImageAjdusted.height) /
      2;
  final alpha = atan(uiImageAjdusted.height / uiImageAjdusted.width);
  final beta = alpha + rotation;
  final shiftY = r * sin(beta);
  final shiftX = r * cos(beta);
  final translateX = uiImageAjdusted.width / 2 - shiftX;
  final translateY = uiImageAjdusted.height / 2 - shiftY;
  canvas.translate(translateX, translateY);
  canvas.rotate(rotation);

  canvas.drawImage(
    uiImageAjdusted,
    Offset.zero,
    Paint()..blendMode = BlendMode.src,
  );
  canvas.restore();

  final picture = pictureRecorder.endRecording();
  ui.Image croppedImage = picture.toImageSync(
    frameSize.width * uiImageAjdusted.width ~/ imageSizePreview.width,
    frameSize.height * uiImageAjdusted.width ~/ imageSizePreview.width,
  );

  final ByteData? adjustedBytes =
      await croppedImage.toByteData(format: ui.ImageByteFormat.png);

  // save file
  final outPath =
      "${(await getExternalStorageDirectory())!.path}/$CROPPED_PROCESSING_IMAGE_NAME.png";
  final output = File(outPath);
  File result = await output.writeAsBytes(
    adjustedBytes!.buffer.asUint8List(),
  );
  stopwatch.stop();
  consolelog("exportCroppedImage Time:  ${stopwatch.elapsedMilliseconds}");
  return result;
}
