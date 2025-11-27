import 'dart:typed_data';
import 'package:passport_photo_2/helpers/native_bridge/document_saver/document_saver_method_channel.dart';

class DocumentFileSavePlus {
  Future<String?> get platformVersion {
    return MethodChannelDocumentFileSavePlus.platformVersion;
  }

  Future<int?> get batteryPercentage {
    return MethodChannelDocumentFileSavePlus.batteryPercentage;
  }

  Future<void> saveMultipleFiles({
    List<Uint8List>? dataList,
    required List<String> fileNameList,
    required List<String> mimeTypeList,
  }) async {
    return MethodChannelDocumentFileSavePlus.saveMultipleFiles(
      dataList: dataList,
      fileNameList: fileNameList,
      mimeTypeList: mimeTypeList,
    );
  }

  Future<void> saveFile(
    Uint8List data,
    String fileName,
    String mimeType,
  ) async {
    return MethodChannelDocumentFileSavePlus.saveMultipleFiles(
      dataList: [data],
      fileNameList: [fileName],
      mimeTypeList: [mimeType],
    );
  }
}