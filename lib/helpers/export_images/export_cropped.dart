import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/helpers/log_custom.dart';
import 'package:pass1_/models/country_passport_model.dart';
import 'package:pass1_/models/crop_model.dart';
import 'package:path_provider/path_provider.dart';

///
/// Trả ra ảnh có kích thước của original image nhưng theo tỉ lệ của passport
///
/// Ví dụ:   Size [4882 - 7052] -> Size [4882 -  6276] theo passport có tỉ lệ [35:45] (inch)
///
Future<(File, ui.Image)> exportCroppedImage({
  required ui.Image uiImageAdjusted, // original size
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
        uiImageAdjusted.width /
        imageSizePreview.width,
    (matrix.getTranslation().y - khoangCachBanDauY * scaleByInteractView) *
        uiImageAdjusted.width /
        imageSizePreview.width,
  );
  // scale theo InteractiveView
  canvas.scale(scaleByInteractView);
  // Tính toán dịch chuyển canvas về điểm trung tâm và xoay
  // https://stackoverflow.com/questions/51323233/flutter-how-to-rotate-an-image-around-the-center-with-canvas#:~:text=We%20thus%20first%20move%20the,position%2C%20with%20the%20rotation%20applied.
  // and preview alpha ben trong phan assets/images/
  final double r =
      sqrt(
        uiImageAdjusted.width * uiImageAdjusted.width +
            uiImageAdjusted.height * uiImageAdjusted.height,
      ) /
      2;
  final alpha = atan(uiImageAdjusted.height / uiImageAdjusted.width);
  final beta = alpha + rotation;
  final shiftY = r * sin(beta);
  final shiftX = r * cos(beta);
  final translateX = uiImageAdjusted.width / 2 - shiftX;
  final translateY = uiImageAdjusted.height / 2 - shiftY;
  canvas.translate(translateX, translateY);
  canvas.rotate(rotation);

  canvas.drawImage(
    uiImageAdjusted,
    Offset.zero,
    Paint()..blendMode = BlendMode.src,
  );
  canvas.restore();

  final picture = pictureRecorder.endRecording();
  int uiImageAdjustedWidth =
      frameSize.width * uiImageAdjusted.width ~/ imageSizePreview.width;
  int uiImageAjdusteHeight =
      frameSize.height * uiImageAdjusted.height ~/ imageSizePreview.height;

  ui.Image croppedImage = picture.toImageSync(
    uiImageAdjustedWidth,
    uiImageAjdusteHeight,
  );

  final ByteData? adjustedBytes = await croppedImage.toByteData(
    format: ui.ImageByteFormat.png,
  );

  // save file
  final outPath =
      "${(await getExternalStorageDirectory())!.path}/$CROPPED_PROCESSING_IMAGE_NAME.png";
  final output = File(outPath);
  File result = await output.writeAsBytes(adjustedBytes!.buffer.asUint8List());
  stopwatch.stop();
  consolelog("exportCroppedImage Time:  ${stopwatch.elapsedMilliseconds}");
  return (result, croppedImage);
}

Future<(File, ui.Image)> exportCropImageV1({
  required ui.Image uiImageAdjusted,
  required CropModel cropModel,
  required Rect previewRectImage,
  required Rect previewRectCrop,
}) async {
  double currentRotation = cropModel.getAngleByRadian;
  final Size originalImageSize = Size(
    uiImageAdjusted.width.toDouble(),
    uiImageAdjusted.height.toDouble(),
  );

  final double cropLeftInImage =
      cropModel.ratioLeftInImage * originalImageSize.width;
  final double cropTopInImage =
      cropModel.ratioTopInImage * originalImageSize.height;
  final double cropRightInImage =
      cropModel.ratioRightInImage * originalImageSize.width;
  final double cropBottomInImage =
      cropModel.ratioBottomInImage * originalImageSize.height;

  final double cropWidthInImage =
      originalImageSize.width - cropLeftInImage - cropRightInImage;
  final double cropHeightInImage =
      originalImageSize.height - cropTopInImage - cropBottomInImage;

  final Rect cropRectInImage = Rect.fromLTWH(
    cropLeftInImage,
    cropTopInImage,
    cropWidthInImage,
    cropHeightInImage,
  );
  final Offset cropCenterInImage = cropRectInImage.center;
  final Offset imageCenter = Offset(
    originalImageSize.width / 2,
    originalImageSize.height / 2,
  );

  consolelog(
    "check 123123123: previewRectCrop = ${previewRectCrop.size}, previewRectImage = ${previewRectImage.size}, cropRectInImage = ${cropRectInImage.size}, originalImageSize = ${originalImageSize}",
  );

  ui.PictureRecorder recorder = ui.PictureRecorder();
  Canvas canvas = Canvas(recorder);

  // Đổ màu đen background
  canvas.drawRect(
    Rect.fromLTWH(0, 0, cropWidthInImage, cropHeightInImage),
    Paint()..color = const Color(0xFF000000),
  );

  canvas.save();

  canvas.translate(cropWidthInImage / 2, cropHeightInImage / 2);

  final Offset vectorFromCropToImage = imageCenter - cropCenterInImage;
  canvas.translate(vectorFromCropToImage.dx, vectorFromCropToImage.dy);

  canvas.rotate(currentRotation);

  canvas.drawImageRect(
    uiImageAdjusted,
    Rect.fromLTWH(0, 0, originalImageSize.width, originalImageSize.height),
    Rect.fromCenter(
      center: Offset.zero,
      width: originalImageSize.width,
      height: originalImageSize.height,
    ),
    Paint(),
  );

  canvas.restore();

  final ui.Picture picture = recorder.endRecording();
  consolelog("Crop size: $cropWidthInImage x $cropHeightInImage");

  final ui.Image resultImage = await picture.toImage(
    cropWidthInImage.toInt(),
    cropHeightInImage.toInt(),
  );

  final ByteData? bytes = await resultImage.toByteData(
    format: ui.ImageByteFormat.png,
  );

  if (bytes == null) {
    throw Exception("Failed to encode PNG");
  }

  final outPath =
      "${(await getExternalStorageDirectory())!.path}/$CROPPED_PROCESSING_IMAGE_NAME.png";

  final file = await File(outPath).writeAsBytes(bytes.buffer.asUint8List());

  return (file, resultImage);
}
