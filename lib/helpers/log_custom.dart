import 'dart:developer';

void consolelog(dynamic message, {String tag = ""}) {
  StackTrace stackTrace = StackTrace.current;
  String fileName = stackTrace.toString().split("\n")[1].split("(").last;
  // fileName = fileName.substring(0, fileName.length - 1).split("/").last;
  var dateTime = DateTime.now();
  var hour = dateTime.hour;
  var minute = dateTime.minute;
  var second = dateTime.second;

  log(" $hour:$minute:$second ~~ $fileName ~~ $message");
}
