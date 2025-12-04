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

Future<File?> exportCroppedImageV1({
  required ui.Image uiImageAdjusted,
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
  ui.Image croppedImage = picture.toImageSync(
    frameSize.width * uiImageAdjusted.width ~/ imageSizePreview.width,
    frameSize.height * uiImageAdjusted.width ~/ imageSizePreview.width,
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
  return result;
}

Future<(File, ui.Image)> exportCroppedImageV2({
  required ui.Image uiImageAdjusted,
  required CountryModel countryModel,
  required CropModel cropModel,
}) async {
  Stopwatch stopwatch = Stopwatch()..start();

  final double angle = cropModel.getAngleByRadian;

  final double imgW = uiImageAdjusted.width.toDouble();
  final double imgH = uiImageAdjusted.height.toDouble();

  // Tính crop rect trong original image
  final double left = cropModel.ratioLeftInImage * imgW;
  final double top = cropModel.ratioTopInImage * imgH;
  final double right = imgW - cropModel.ratioRightInImage * imgW;
  final double bottom = imgH - cropModel.ratioBottomInImage * imgH;

  final double cropW = right - left;
  final double cropH = bottom - top;

  final Rect cropRect = Offset(left, top) & Size(cropW, cropH);
  final Offset cropCenter = cropRect.center;

  ui.PictureRecorder recorder = ui.PictureRecorder();
  Canvas canvas = Canvas(recorder);

  canvas.drawRect(
    Rect.fromLTWH(0, 0, cropW, cropH),
    Paint()..color = const Color(0xFF000000),
  );

  canvas.save();
  // Ném canvas đến điểm center của crop rect
  canvas.translate(cropRect.center.dx, cropRect.center.dy);

  // =============================
  // BƯỚC 3:
  // Xoay quanh center canvas
  // =============================
  canvas.rotate(angle);

  canvas.drawImage(
    uiImageAdjusted,
    Offset(-cropCenter.dx, -cropCenter.dy),
    Paint(),
  );

  canvas.restore();

  // =============================
  // OUTPUT
  // =============================
  final ui.Picture picture = recorder.endRecording();
  final ui.Image resultImage = await picture.toImage(
    cropW.toInt(),
    cropH.toInt(),
  );

  final ByteData? bytes = await resultImage.toByteData(
    format: ui.ImageByteFormat.png,
  );
  if (bytes == null) throw Exception("Convert PNG error");

  final outPath =
      "${(await getExternalStorageDirectory())!.path}/$CROPPED_PROCESSING_IMAGE_NAME.png";

  final File saved = await File(
    outPath,
  ).writeAsBytes(bytes.buffer.asUint8List());

  stopwatch.stop();
  consolelog("exportCroppedImageV2 Time: ${stopwatch.elapsedMilliseconds}ms");

  return (saved, resultImage);
}

Future<(File, ui.Image)> exportCroppedImageMatchDisplay({
  required ui.Image uiImageAdjusted,
  required CountryModel countryModel,
  required CropModel cropModel,
  required Rect rectImagePreview,
  required Rect rectCropHolePreview,
  required double scaleWithInit,
}) async {
  /// GIẢI PHÁP CHO VẤN ĐỀ ZOOM:
  /// - Không dùng scale từ rectImagePreview (thay đổi theo zoom)
  /// - Dùng ratio của crop rect trong ảnh hiển thị
  /// - Áp dụng ratio này vào ảnh gốc → kích thước crop cố định

  Stopwatch stopwatch = Stopwatch()..start();

  // ============================================
  // CHUẨN BỊ DỮ LIỆU
  // ============================================
  final Size originalImageSize = Size(
    uiImageAdjusted.width.toDouble(),
    uiImageAdjusted.height.toDouble(),
  );

  // ============================================
  // TÍNH RATIO THAY VÌ SCALE (FIX ZOOM ISSUE)
  // ============================================
  // Ratio của crop rect so với ảnh hiển thị (không đổi khi zoom)
  final double cropWidthRatio =
      rectCropHolePreview.width / rectImagePreview.width;
  final double cropHeightRatio =
      rectCropHolePreview.height / rectImagePreview.height;
  consolelog("Ratio ratio: $cropWidthRatio, $cropHeightRatio");
  // Áp dụng ratio vào ảnh gốc
  final double cropWidthInOriginal = originalImageSize.width * cropWidthRatio;
  final double cropHeightInOriginal =
      originalImageSize.height * cropHeightRatio;

  // Vector từ image center đến crop center (trong coordinate ảnh hiển thị)
  final Offset vectorFromImageToCrop =
      rectCropHolePreview.center - rectImagePreview.center;

  // Chuyển vector sang tỷ lệ của ảnh hiển thị
  final double vectorXRatio = vectorFromImageToCrop.dx / rectImagePreview.width;
  final double vectorYRatio =
      vectorFromImageToCrop.dy / rectImagePreview.height;

  // Áp dụng ratio vào ảnh gốc
  final Offset vectorInOriginal = Offset(
    vectorXRatio * originalImageSize.width,
    vectorYRatio * originalImageSize.height,
  );

  // ============================================
  // TẠO CANVAS VÀ VẼ
  // ============================================
  ui.PictureRecorder recorder = ui.PictureRecorder();
  Canvas canvas = Canvas(recorder);

  // Đổ màu đen
  canvas.drawRect(
    Rect.fromLTWH(0, 0, cropWidthInOriginal, cropHeightInOriginal),
    Paint()..color = const Color(0xFF000000),
  );

  canvas.save();

  // BƯỚC 1: Translate đến center của crop rect
  canvas.translate(cropWidthInOriginal / 2, cropHeightInOriginal / 2);

  // BƯỚC 2: Translate từ crop center về image center
  // (ngược lại so với vector từ image → crop)
  canvas.translate(-vectorInOriginal.dx, -vectorInOriginal.dy);

  // BƯỚC 3: Xoay quanh image center
  canvas.rotate(cropModel.getAngleByRadian);

  // BƯỚC 4: Vẽ ảnh với center tại (0,0)
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

  // ============================================
  // TẠO ẢNH KẾT QUẢ
  // ============================================
  final ui.Picture picture = recorder.endRecording();
  final ui.Image resultImage = await picture.toImage(
    cropWidthInOriginal.toInt(),
    cropHeightInOriginal.toInt(),
  );

  // ============================================
  // LƯU FILE
  // ============================================
  final ByteData? bytes = await resultImage.toByteData(
    format: ui.ImageByteFormat.png,
  );

  if (bytes == null) {
    throw Exception("Failed to encode PNG");
  }

  final outPath =
      "${(await getExternalStorageDirectory())!.path}/CROPPED_IMAGE.png";
  final file = await File(outPath).writeAsBytes(bytes.buffer.asUint8List());

  stopwatch.stop();
  consolelog("exportCroppedImage Time: ${stopwatch.elapsedMilliseconds}ms");

  return (file, resultImage);
}
