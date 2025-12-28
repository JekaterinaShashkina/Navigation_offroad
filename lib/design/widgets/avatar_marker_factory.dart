import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// Делает круглые маркеры-аватары для GoogleMap и кеширует их.
/// Использование:
///   final icon = await AvatarMarkerFactory.I.get(userId: uid, photoUrl: url);
class AvatarMarkerFactory {
  AvatarMarkerFactory._();

  static final AvatarMarkerFactory I = AvatarMarkerFactory._();

  final Map<String, BitmapDescriptor> _cache = {};
  final Map<String, Future<BitmapDescriptor>> _inFlight = {};

  /// Можно сделать несколько размеров (напр. 96/128/160) по кейсам
  static const int defaultSize = 140;

  BitmapDescriptor get defaultIcon => BitmapDescriptor.defaultMarker;

  void clear() => _cache.clear();

  /// Получить BitmapDescriptor для аватара (круглый + белая рамка).
  /// Кэшируется по ключу: "$userId|$photoUrl|$size"
  Future<BitmapDescriptor> get({
    required String userId,
    required String? photoUrl,
    int size = defaultSize,
  }) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return Future.value(defaultIcon);
    }

    final key = '$userId|$photoUrl|$size';

    final cached = _cache[key];
    if (cached != null) return Future.value(cached);

    final inflight = _inFlight[key];
    if (inflight != null) return inflight;

    final fut = _build(photoUrl, size).then((icon) {
      _cache[key] = icon;
      _inFlight.remove(key);
      return icon;
    }).catchError((_) {
      _inFlight.remove(key);
      return defaultIcon;
    });

    _inFlight[key] = fut;
    return fut;
  }

  Future<BitmapDescriptor> _build(String url, int size) async {
    final png = await _circlePngFromUrl(url, size: size);
    return BitmapDescriptor.fromBytes(png);
  }

  Future<Uint8List> _circlePngFromUrl(String url, {required int size}) async {
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('HTTP ${resp.statusCode}');
    }
    final bytes = resp.bodyBytes;

    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: size,
      targetHeight: size,
    );
    final frame = await codec.getNextFrame();
    final img = frame.image;

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

    // белая обводка
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
}
