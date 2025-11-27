import 'dart:io';

Future<dynamic> deleteAllFilesInDirectory(Directory? directory) async {
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
