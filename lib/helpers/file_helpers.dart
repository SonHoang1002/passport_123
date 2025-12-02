import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:pass1_/a_test/pdf_function/generate_mimetype.dart';
import 'package:pass1_/helpers/size_helpers.dart';
import 'package:pass1_/helpers/native_bridge/document_saver/document_file_save_plus.dart';
import 'package:pass1_/helpers/native_bridge/method_channel.dart';
import 'package:pass1_/helpers/random_number.dart';
import 'package:path_provider/path_provider.dart';

Future<void> deleteAllTempFile() async {
  await _deleteAllFilesInDirectory(await getExternalStorageDirectory());
}

Future<dynamic> _deleteAllFilesInDirectory(Directory? directory) async {
  debugPrint("_deleteAllFilesInDirectory call: ${directory?.path}");
  if (directory == null) return "Directory null !!";
  List results = [];
  String message = "";
  try {
    if (directory.existsSync()) {
      for (var file in directory.listSync()) {
        if (file is File) {
          try {
            await file.delete();
            results.add(file.path);
          } catch (e) {
            print("Error while delete file: $e");
          }
        }
      }
      return results;
    } else {
      message = "Directory does not exist.";
      print(message);
    }
  } catch (e) {
    message = 'Error deleting files: $e';
    print(message);
  }
  return message;
}

///
/// From /storage/emulated/0/Pictures/ScreenShots/image_wedding.png
/// to /storage/emulated/0/Android/data/com.tapuniverse.passportphoto/files/image_wedding_edit_9960.png
///
Future<String> createStoragePathWithInput(
  String inputPath, {
  String? extension,
  bool? useAvailableDefaultSuffix,
}) async {
  final rootPath = await getExternalStorageDirectory();
  if (rootPath == null) return inputPath;

  String fileName = inputPath.split("/").last;
  String name = fileName.split(".").first;
  String _extension = extension ?? fileName.split(".").last;
  String newName = name;
  if (useAvailableDefaultSuffix == true) {
    if (name.contains("_edit_")) {
      newName = "${name.split("_edit_").first}_edit_1111";
    } else {
      newName = "${newName}_edit_1111";
    }
  } else {
    if (name.contains("_edit_")) {
      newName = "${name.split("_edit_").first}_edit_${randomInt()}";
    } else {
      newName = "${newName}_edit_${randomInt()}";
    }
  }
  String newFileName = "$newName.$_extension";

  return "${rootPath.path}/$newFileName";
}

///
///  inputFile from saveToLibrary:
///  File: '/storage/emulated/0/Android/data/com.tapuniverse.passportphoto/files/finished_image.jpg'
///
Future<File> saveToLibrary({
  required int indexImageFormat,
  required File inputFile,
  required String fileName,
}) async {
  String originalPath = "/storage/emulated/0/Pictures/";
  Uint8List byteData = inputFile.readAsBytesSync();

  String outputPath;
  String? resultPath;

  String mimeType = generateMimeType(indexImageFormat);

  if (indexImageFormat == 2) {
    outputPath = "${(await getDownloadsDirectory())!.path}/$fileName";
  } else {
    outputPath = originalPath + fileName;
  }
  DocumentFileSavePlus().saveFile(byteData, fileName, mimeType);
  resultPath = outputPath;

  await MediaScanner.loadMedia(path: outputPath);
  return File(resultPath);
}

Future<File?> resizeImageBeforeAPI(
  String selectedPath, {
  double maxDimension = 1200,
}) async {
  String outPath =
      "${(await getExternalStorageDirectory())!.path}/resize_before_api.png";
  File selectedFile = File(selectedPath);
  var decodedOriginalImage = await decodeImageFromList(
    selectedFile.readAsBytesSync(),
  );
  Size originalSize = Size(
    decodedOriginalImage.width.toDouble(),
    decodedOriginalImage.height.toDouble(),
  );

  Size newSize = FlutterSizeHelpers.handleScaleWithSpecialDimension(
    originalSize: originalSize,
  );

  final resizeImage = await MyMethodChannel.resizeAndResoluteImage(
    inputPath: selectedPath,
    format: 0,
    listWH: [newSize.width, newSize.height],
    scaleWH: [1, 1],
    outPath: outPath,
    quality: 90,
  );

  // var decodedResizedImage = await decodeImageFromList(
  //   resizeImage!.readAsBytesSync(),
  // );
  // consolelog(
  //     "stopwatch call resizeImageBeforeAPI decodedResizedImage ${decodedResizedImage.width} - ${decodedResizedImage.height}");

  return resizeImage;
}
