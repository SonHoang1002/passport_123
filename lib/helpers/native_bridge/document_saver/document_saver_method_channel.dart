import 'package:flutter/services.dart';

class MethodChannelDocumentFileSavePlus {
  /// The method channel used to interact with the native platform.

  static const platform = MethodChannel('com.tapuniverse.passportphoto');

  static Future<String?> get platformVersion async {
    return await platform.invokeMethod('getPlatformVersion');
  }

  static Future<int?> get batteryPercentage async {
    return await platform.invokeMethod('getBatteryPercentage');
  }

  static Future<void> saveMultipleFiles({
    List<Uint8List>? dataList,
    required List<String> fileNameList,
    required List<String> mimeTypeList,
  }) async {
    if (dataList!.length != fileNameList.length) {
      throw "function saveMultipleFiles: length of 'dataList' is not equal to the length of 'fileNameList'";
    }

    if (dataList.length != mimeTypeList.length) {
      throw "function saveMultipleFiles: length of 'dataList' is not equal to the length of 'mimeTypeList'";
    }

    for (var i = 0; i < dataList.length; i++) {
      if (dataList[i].isEmpty) {
        throw "function saveMultipleFiles: dataList item cannot be null";
      }
    }

    for (var i = 0; i < mimeTypeList.length; i++) {
      if (mimeTypeList[i].isEmpty) {
        throw "function saveMultipleFiles: mimeTypeList item cannot be null";
      }
    }

    var fileNameCount = {};
    for (var i = 0; i < fileNameList.length; i++) {
      String? fileName = fileNameList[i];

      if (fileName.isEmpty) fileName = "file";

      if (fileNameCount.containsKey(fileName)) {
        fileNameCount[fileName] += 1;
        var extensionIndex = fileName.lastIndexOf('.');
        if (extensionIndex == -1) extensionIndex = fileName.length;

        var extension = '';
        if (extensionIndex < fileName.length) {
          extension = fileName.substring(extensionIndex);
        }

        // ignore: prefer_interpolation_to_compose_strings
        fileName = fileName.substring(0, extensionIndex) +
            '_' +
            fileNameCount[fileName].toString() +
            extension;
      } else {
        fileNameCount[fileName] = 1;
      }

      fileNameList[i] = fileName;
    }

    try {
      await platform.invokeMethod('saveMultipleFiles', {
        "dataList": dataList,
        "fileNameList": fileNameList,
        "mimeTypeList": mimeTypeList
      });
    } on PlatformException {
      rethrow;
    }
  }
}
