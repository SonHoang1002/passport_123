import 'dart:io';

import 'package:pass1_/commons/constants.dart';

Future<double> getFileSize(File file) async {
  if (file.existsSync()) {
    int fileSizeInBytes = await file.length();
    double fileSizeInKB = (fileSizeInBytes / MB_TO_KB);
    return fileSizeInKB;
  } else {
    return 0.0;
  }
}
