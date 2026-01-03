import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:flutter_svg/flutter_svg.dart' as svg; // SvgStringLoader, PictureInfo
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/painting.dart' show applyBoxFit, BoxFit, FittedSizes;

/// Делает круглые маркеры-аватары для GoogleMap и кеширует их.
/// Использование:
///   final icon = await AvatarMarkerFactory.I.get(userId: uid, photoUrl: url);
class   AvatarMarkerFactory {
  AvatarMarkerFactory._();
  static final AvatarMarkerFactory I = AvatarMarkerFactory._();

  final Map<String, BitmapDescriptor> _cache = {};
  final Map<String, Future<BitmapDescriptor>> _inFlight = {};

  static const int defaultSize = 140;

  BitmapDescriptor get defaultIcon => BitmapDescriptor.defaultMarker;

  /// Получить BitmapDescriptor для аватара (круглый + белая рамка).
  /// Кэшируется по ключу: "$userId|$photoUrl|$size"
  Future<BitmapDescriptor> get({
    required String userId,
    required String? photoUrlOrAsset, // может быть url или assets/...
    int size = defaultSize,
  }) {
    final src = photoUrlOrAsset;
    if (src == null || src.isEmpty) return Future.value(defaultIcon);

    final key = 'v3|$userId|$src|$size';
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
  return BitmapDescriptor.fromBytes(png);
  }

  Future<Uint8List> _circlePngFromSource(String src, {required int size}) async {
    // 1) получить bytes (растр) или svg-string
    final bool isAsset = src.startsWith('assets/');
    final lower = src.toLowerCase();
    final pathOnly = lower.split('?').first;
    final isSvg = pathOnly.endsWith('.svg');


    ui.Image img;

    if (isSvg) {
      final String svgText = isAsset
          ? await rootBundle.loadString(src)
          : await _downloadText(src);

      img = await _renderSvgToImage(svgText, size: size);
      debugPrint('************************rendered img: ${img.width}x${img.height}');
    } else {
      final Uint8List bytes = isAsset
          ? (await rootBundle.load(src)).buffer.asUint8List()
          : await _downloadBytes(src);

      img = await _decodeRasterToImage(bytes, size: size);
    }
    // debugPrint('***********************avatar src=$src isAsset=$isAsset isSvg=$isSvg');
    // 2) сделать круг + рамку
final outSize = ui.Size(size.toDouble(), size.toDouble());
final srcSize = ui.Size(img.width.toDouble(), img.height.toDouble());

final recorder = ui.PictureRecorder();
final canvas = ui.Canvas(recorder);
final paint = ui.Paint()..isAntiAlias = true;

final padding = size * 0.25;

final inner = ui.Rect.fromLTWH(
  padding,
  padding,
  outSize.width - padding * 2,
  outSize.height - padding * 2,
);

canvas.clipPath(ui.Path()..addOval(inner));

final fitted = applyBoxFit(
  BoxFit.cover, // если хочешь целиком; для заполнения круга -> BoxFit.cover
  srcSize,
  inner.size,
);

// какие части брать/куда класть
final inputSubrect = Alignment.center.inscribe(
  fitted.source,
  Offset.zero & srcSize,
);

final outputSubrect = Alignment.center.inscribe(
  fitted.destination,
  inner,
);

canvas.drawImageRect(img, inputSubrect, outputSubrect, paint);
final border = ui.Paint()
  ..style = ui.PaintingStyle.stroke
  ..strokeWidth = size * 0.06 // ~5.3
  ..color = const ui.Color(0xFFFFFFFF)
  ..isAntiAlias = true;

canvas.drawOval(inner, border);

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

Future<ui.Image> _renderSvgToImage(String rawSvg, {required int size}) async {
  final svg.PictureInfo pictureInfo = await svg.vg.loadPicture(
    svg.SvgStringLoader(rawSvg),
    null,
  );

  final ui.Image image = await pictureInfo.picture.toImage(size, size);
  pictureInfo.picture.dispose();
  return image;

}

}
