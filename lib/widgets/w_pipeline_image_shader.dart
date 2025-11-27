import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_filters/flutter_image_filters.dart';

class CustomPipelineImageShaderPreview extends StatelessWidget {
  final GroupShaderConfiguration configuration;
  final TextureSource texture;
  final BlendMode blendMode;

  const CustomPipelineImageShaderPreview({
    super.key,
    required this.configuration,
    required this.texture,
    this.blendMode = BlendMode.src,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.Image>(
      future: _export(),
      builder: ((context, snapshot) {
        if (snapshot.hasError && kDebugMode) {
          debugPrint(snapshot.error.toString());
          return SingleChildScrollView(
            child: Text(snapshot.error.toString()),
          );
        }
        ui.Image? image = snapshot.data;
        if (image == null) {
          return const SizedBox();
        }
        return ImageShaderPreview(
          configuration: configuration,
          texture: TextureSource.fromImage(image),
        );
      }),
    );
  }

  Future<ui.Image> _export() async {
    if (kDebugMode) {
      final watch = Stopwatch();
      watch.start();
      final result = await configuration.export(texture, texture.size);
      debugPrint(
        'Exporting image took ${watch.elapsedMilliseconds} milliseconds',
      );
      return result;
    } else {
      final result = await configuration.export(texture, texture.size);
      return result;
    }
  }
}
