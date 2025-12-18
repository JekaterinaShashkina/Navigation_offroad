import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image/image.dart' as img;

class MarkerIcon {
  /// widthPx/heightPx — итоговый размер картинки маркера в пикселях.
  static Future<BitmapDescriptor> fromPngAsset(
    String assetPath, {
    required int widthPx,
    required int heightPx,
  }) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Failed to decode image: $assetPath');
    }

    final resized = img.copyResize(
      decoded,
      width: widthPx,
      height: heightPx,
      interpolation: img.Interpolation.average,
    );

    final png = img.encodePng(resized);
    return BitmapDescriptor.bytes(Uint8List.fromList(png));
  }
}
