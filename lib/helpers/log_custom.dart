import 'dart:developer';

void consolelog(dynamic message) {
  StackTrace stackTrace = StackTrace.current;
  String fileName = stackTrace.toString().split("\n")[1].split("(").last;
  fileName = fileName.substring(0, fileName.length - 1).split("/").last;
  log("$fileName ===> $message");
}
