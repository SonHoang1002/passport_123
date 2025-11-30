import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pass1_/a_test/pdf_function/generate_mimetype.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/helpers/file_helpers.dart';
import 'package:pass1_/helpers/firebase_helpers.dart';
import 'package:pass1_/helpers/log_custom.dart';

class MyMethodChannel {
  static const platform = MethodChannel('com.tapuniverse.passportphoto');

  static Future<File?> resizeAndResoluteImage({
    required String inputPath,
    required int format,
    List<double>? listWH,
    List<double>? scaleWH,
    String? outPath,
    int? quality = 80,
  }) async {
    try {
      String _outPath = inputPath;
      int formatStatus = format; // [JPG, PNG].indexOf(format); //, WEBP, HEIC
      if (outPath == null) {
        final extension = LIST_FORMAT_IMAGE[formatStatus];
        _outPath = await createStoragePathWithInput(
          inputPath,
          extension: extension.toLowerCase(),
          useAvailableDefaultSuffix: true,
        );
      } else {
        _outPath = outPath;
      }
      consolelog("formatStatus ${listWH} - ${quality}");
      // consolelog("inputPath ${inputPath}");
      // consolelog("_outPath ${_outPath}");

      Map<String, dynamic> data = {
        "inputPath": inputPath,
        "outputPath": _outPath,
        "indexFormat": formatStatus,
        "width": listWH?[0].round(),
        "height": listWH?[1].round(),
        "scale": scaleWH,
        "quality": quality,
      };
      var resultResize = await platform.invokeMethod(
        "resizeAndResoluteImage",
        data,
      );
      if (resultResize == true) {
        return File(_outPath);
      } else {
        return null;
      }
    } catch (e) {
      print("resizeAndResoluteImage error: $e");
      consolelog("resizeAndResoluteImage error: $e");
      return null;
    }
  }

  static Future<void> showPopupReview() async {
    try {
      var isRating = await FirebaseHelpers().checkRating();
      // check xem da danh gia hay chua
      if (!isRating) {
        await FirebaseHelpers().updateRating();
        await platform.invokeMethod("showPopupFeedback");
      }
    } on PlatformException catch (e) {
      print("Error: ${e.message}");
    }
  }

  static Future<void> maskTwoImage(
    String originalPath,
    String transparentPath,
    String outPath,
  ) async {
    try {
      bool result = await platform.invokeMethod("maskTwoImage", [
        originalPath,
        transparentPath,
        outPath,
      ]);
      consolelog("result ${result}");
    } on PlatformException catch (e) {
      print("Error: ${e.message}");
    }
  }

  static Future<bool?> detectObjectAndDeleteBackground(
    String inputPath,
    String outPath,
  ) async {
    try {
      // chuyển đổi ảnh gốc sang ảnh đen trắng
      final extension = inputPath.split(".").last;
      final formatIndex = LIST_FORMAT_IMAGE.indexOf(extension.toUpperCase());
      consolelog("inputPath ${inputPath}");
      bool? result = await platform.invokeMethod("detectAndSeperateObject", [
        inputPath,
        outPath,
        formatIndex,
      ]);
      return result;
    } catch (e) {
      print("detectAndSeperateObject error: $e");
      consolelog("detectAndSeperateObject error: $e");
      return null;
    }
  }

  static Future<bool> createActionDocument(
    List<String> listInputPath,
    int indexImageFormat,
  ) async {
    try {
      String mimeType = generateMimeType(indexImageFormat);
      Map<String, dynamic> nativeData = {
        "listPath": listInputPath,
        "mimeType": mimeType,
      };

      bool? result = await platform.invokeMethod(
        "action_create_document",
        nativeData,
      );

      return result ?? false;
    } catch (e) {
      print("createActionDocument error: $e");
      consolelog("createActionDocument error: $e");
      return false;
    }
  }

  // action_create_document

  /// [passportPath]         : Ảnh đã được cropped
  ///
  /// [outputPath]           : Đường dẫn đích
  ///
  /// [paperSize]            : Kích thước paper đổi ra đơn vị pixel
  ///
  /// [passportSize]         : Kích thước passport đổi ra đơn vị pixel
  ///
  /// [countImageOn1Row]     : Số ảnh trong 1 dòng
  ///
  /// [countRow]             : Số dòng trong 1 trang
  ///
  /// [countImageNeedDraw]   : Số ảnh cần vẽ trong 1 trang
  ///
  /// [spacingHorizontal]
  /// [spacingVertical]      : Khoảng cách giữa các ảnh 2 chiều
  ///
  /// [marginModel]          : Khoảng cách padding của paper
  ///
  /// [outputFormat]         :  0: JPG, 1: PNG , 2: JPG
  ///
  /// [qualityPassport]      :  Compression của passport
  ///
  static Future<dynamic> generateSinglePage({
    required String passportPath,
    required String outputPath,
    required List<double> paperSize,
    required List<double> passportSize,
    required int countImageOn1Row,
    required int countRow,
    required int countImageNeedDraw,
    required List<double> spacingHorizontal,
    required List<double> spacingVertical,
    required EdgeInsets marginEdgeInsets,
    required int qualityPassport,
    required int outputFormat,
  }) async {
    try {
      int bitmapConfigIndex = 0;
      List<double> margin = [
        marginEdgeInsets.left,
        marginEdgeInsets.top,
        marginEdgeInsets.right,
        marginEdgeInsets.bottom,
      ];
      Map<String, dynamic> nativeData = {
        "passportPath": passportPath,
        "outputPath": outputPath,
        "paperSize": paperSize,
        "passportSize": passportSize,
        "countImageOn1Row": countImageOn1Row,
        "countRow": countRow,
        "countImageNeedDraw": countImageNeedDraw,
        "spacingHorizontal": spacingHorizontal,
        "spacingVertical": spacingVertical,
        "margins": margin,
        "qualityPassport": qualityPassport,
        "outputFormat": outputFormat,
        "bitmapConfigIndex": bitmapConfigIndex,
      };

      var result = await platform.invokeMethod(
        "generateSinglePage",
        nativeData,
      );
      return result;
    } catch (e) {
      print("generateSinglePage error: $e");
      consolelog("generateSinglePage error: $e");
      return null;
    }
  }

  static Future<void> showToast(String message) async {
    Map<String, dynamic> nativeData = {"message": message};
    return await platform.invokeMethod('showToast', nativeData);
  }

  static Future<bool> checkNetworkConnection() async {
    return await platform.invokeMethod('checkNetworkConnection');
  }
}
