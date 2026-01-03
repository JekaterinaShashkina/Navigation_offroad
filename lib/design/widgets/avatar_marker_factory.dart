import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart' as svg;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:vector_graphics/vector_graphics.dart';

class   AvatarMarkerFactory {
  AvatarMarkerFactory._();
  static final AvatarMarkerFactory I = AvatarMarkerFactory._();

  final Map<String, BitmapDescriptor> _cache = {};
  final Map<String, Future<BitmapDescriptor>> _inFlight = {};

  static const int defaultSize = 140;

  BitmapDescriptor get defaultIcon => BitmapDescriptor.defaultMarker;

  Future<BitmapDescriptor> get({
    required String userId,
    required String? photoUrlOrAsset, // может быть url или assets/...
    int size = defaultSize,
  }) {
    final src = photoUrlOrAsset;
    if (src == null || src.isEmpty) return Future.value(defaultIcon);

    final key = '$userId|$src|$size';
    final cached = _cache[key];
    if (cached != null) return Future.value(cached);

    final inflight = _inFlight[key];
    if (inflight != null) return inflight;

    final fut = _build(src, size).then((icon) {
      _cache[key] = icon;
      _inFlight.remove(key);

      return icon;
    }).catchError((e, st) {
      _inFlight.remove(key);
        debugPrint('❌ avatar build failed: user=$userId src=$src size=$size err=$e');
  debugPrintStack(stackTrace: st);
      return defaultIcon;
    });
    debugPrint('✅ avatar ready for user=$userId}');
    _inFlight[key] = fut;
    return fut;
  }

  Future<BitmapDescriptor> _build(String src, int size) async {
    final png = await _circlePngFromSource(src, size: size);
    return BitmapDescriptor.bytes(png);
  }

  Future<Uint8List> _circlePngFromSource(String src, {required int size}) async {
    // 1) получить bytes (растр) или svg-string
    final bool isAsset = src.startsWith('assets/');
    final bool isSvg = src.toLowerCase().endsWith('.svg');

    ui.Image img;

    if (isSvg) {
      final String svgText = isAsset
          ? await rootBundle.loadString(src)
          : await _downloadText(src);

      img = await _renderSvgToImage(svgText, size: size);
    } else {
      final Uint8List bytes = isAsset
          ? (await rootBundle.load(src)).buffer.asUint8List()
          : await _downloadBytes(src);

      img = await _decodeRasterToImage(bytes, size: size);
    }

    // 2) сделать круг + рамку
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint()..isAntiAlias = true;

    final r = ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
    canvas.clipPath(ui.Path()..addOval(r));
    canvas.drawImageRect(
      img,
      ui.Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      r,
      paint,
    );

    final border = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = const ui.Color(0xFFFFFFFF)
      ..isAntiAlias = true;
    canvas.drawOval(r, border);

    final picture = recorder.endRecording();
    final outImg = await picture.toImage(size, size);
    final pngBytes = await outImg.toByteData(format: ui.ImageByteFormat.png);
    return pngBytes!.buffer.asUint8List();
  }

  Future<ui.Image> _decodeRasterToImage(Uint8List bytes, {required int size}) async {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: size,
      targetHeight: size,
    );
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<Uint8List> _downloadBytes(String url) async {
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('HTTP ${resp.statusCode}');
    }
    return resp.bodyBytes;
  }

  Future<String> _downloadText(String url) async {
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('HTTP ${resp.statusCode}');
    }
    return resp.body;
  }

Future<ui.Image> _renderSvgToImage(String svgText, {required int size}) async {
  final pictureInfo = await vg.loadPicture(
    svg.SvgStringLoader(svgText),
    null,
  );

  final picture = pictureInfo.picture;
  final img = await picture.toImage(size, size);

  picture.dispose(); // ✅ один dispose
  return img;
}
}
