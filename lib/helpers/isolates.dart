import 'dart:io';
import 'dart:isolate';
import 'package:flutter_image_filters/flutter_image_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pass1_/commons/shaders/brightness_custom.dart';
import 'package:pass1_/helpers/export_images/export_adjusted.dart';
import 'package:pass1_/models/project_model.dart';

class FlutterIsolates {
  static Future<File?> handleExportAdjust(
    ProjectModel projectModel,
    CustomBrightnessShaderConfiguration brightnessShaderConfiguration,
    ShaderConfiguration shaderExportConfiguration,
    Offset objectOffset,
    Size adjustSize,
  ) async {
    final ReceivePort receivePort = ReceivePort();
    RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
    try {
      await Isolate.spawn(_exportFileAdjust, [
        receivePort.sendPort,
        [
          rootIsolateToken,
          projectModel,
          brightnessShaderConfiguration,
          shaderExportConfiguration,
          objectOffset,
          adjustSize,
        ],
      ]);
      File? response = await receivePort.first;
      return response;
    } catch (e) {
      debugPrint('Isolate Failed: ${e}');
    }
    receivePort.close();
    return null;
  }

  static Future<void> _exportFileAdjust(List<dynamic> args) async {
    SendPort resultPort = args[0];
    BackgroundIsolateBinaryMessenger.ensureInitialized(args[1][0]);
    ProjectModel projectModel = args[1][1] as ProjectModel;
    CustomBrightnessShaderConfiguration brightnessShaderConfiguration =
        args[1][2] as CustomBrightnessShaderConfiguration;
    ShaderConfiguration shaderExportConfiguration =
        args[1][3] as ShaderConfiguration;
    Offset objectOffset = args[1][4] as Offset;
    Size adjustSize = args[1][5] as Size;
    final adjustedBgFile = await onExportBackground(
      projectModel,
      brightnessShaderConfiguration,
    );
    final adjustObjectFile = await onExportObject(
      shaderExportConfiguration,
      projectModel.bgRemovedFile!,
    );
    final result = await exportAdjustedImage(
      adjustedBgFile,
      adjustObjectFile,
      objectOffset,
      adjustSize,
    );
    resultPort.send(result);
    Isolate.exit(resultPort);
  }
}
