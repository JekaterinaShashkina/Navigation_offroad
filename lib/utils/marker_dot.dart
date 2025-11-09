// lib/utils/marker_dot.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:offroad_nav/design/colors.dart';

/// Генератор круглых иконок для маркеров Google Map.
/// Иконки кэшируются по параметрам.
class MarkerDot {
  static final Map<String, BitmapDescriptor> _cache = {};

  /// Получить (или собрать) круглую иконку.
  static Future<BitmapDescriptor> get({
    int size = 18,
    Color fill = const Color(0xFFE53935),   // красный
    Color stroke = surfaceColor,
    double strokeWidth = 2.0,
    double shadowBlur = 0,                   // 0 = без тени
    Color? shadowColor,
  }) async {
    final key =
        '$size-${fill.value}-${stroke.value}-${strokeWidth.toStringAsFixed(2)}-$shadowBlur-${shadowColor?.value}';
    final cached = _cache[key];
    if (cached != null) return cached;

    final icon = await _build(
      size: size,
      fill: fill,
      stroke: stroke,
      strokeWidth: strokeWidth,
      shadowBlur: shadowBlur,
      shadowColor: shadowColor ?? Colors.black.withOpacity(0.25),
    );
    _cache[key] = icon;
    return icon;
  }

  // Реальный рендер кружка на Canvas → PNG → BitmapDescriptor
  static Future<BitmapDescriptor> _build({
    required int size,
    required Color fill,
    required Color stroke,
    required double strokeWidth,
    required double shadowBlur,
    required Color shadowColor,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final s = size.toDouble();
    final center = Offset(s / 2, s / 2);
    final r = s / 2;

    if (shadowBlur > 0) {
      final pShadow = Paint()
        ..color = shadowColor
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, shadowBlur);
      canvas.drawCircle(center, r, pShadow);
    }

    final pStroke = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, r - strokeWidth / 2, pStroke);

    final pFill = Paint()..color = fill;
    canvas.drawCircle(center, r - strokeWidth, pFill);

    final img = await recorder.endRecording().toImage(size, size);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(Uint8List.view(bytes!.buffer));
  }
}
