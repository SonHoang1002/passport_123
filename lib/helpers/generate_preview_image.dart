import 'dart:io';
import 'package:passport_photo_2/commons/constants.dart';
import 'package:passport_photo_2/helpers/native_bridge/method_channel.dart';
import 'package:path_provider/path_provider.dart';

Future<File?> generateSmallImage(
  String inputPath,
  List<double> listWH, {
  String? newName = "preview_test",
  List<double> ratios = const [1 / 4, 1 / 4],
}) async {
  final extension = inputPath.split(".").last;
  final path = (await getExternalStorageDirectory())!.path;
  final newPath = "$path/$newName.png";
  File resultFile = File(newPath);
  if (resultFile.existsSync()) {
    return resultFile;
  }
  final format = LIST_FORMAT_IMAGE.indexOf(extension.toUpperCase());
  final result = await MyMethodChannel.resizeAndResoluteImage(
    inputPath: inputPath,
    format: format,
    listWH: listWH,
    scaleWH: ratios,
    outPath: newPath,
  );
  return result;
}
