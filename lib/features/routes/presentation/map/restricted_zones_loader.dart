import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:offroad_nav/design/colors.dart';

class RestrictedZonesLoader {
  /// Загружает GeoJSON из assets и конвертит в polygons для GoogleMap
  static Future<Set<Polygon>> loadFromAsset(
    String assetPath, {
    int maxPolygons = 2000, // защита от "слишком много"
  }) async {
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final features = (json['features'] as List?) ?? const [];
    final result = <Polygon>{};

    int idx = 0;

    for (final f in features) {
      if (result.length >= maxPolygons) break;

      final geom = (f as Map)['geometry'];
      if (geom is! Map) continue;

      final type = geom['type'];
      final coords = geom['coordinates'];

      if (type == 'Polygon' && coords is List) {
        _addPolygon(result, coords, idx++);
      } else if (type == 'MultiPolygon' && coords is List) {
        for (final poly in coords) {
          if (result.length >= maxPolygons) break;
          if (poly is List) _addPolygon(result, poly, idx++);
        }
      } else if (type == 'GeometryCollection') {
        // если вдруг встретится — можно проигнорить или добавить разбор
        continue;
      }
    }

    return result;
  }

  static void _addPolygon(Set<Polygon> out, List coords, int idx) {
    // GeoJSON Polygon: [ outerRing, hole1, hole2, ... ]
    if (coords.isEmpty) return;

    final outer = _ringToLatLng(coords.first);
    if (outer.length < 3) return;

    final holes = <List<LatLng>>[];
    for (var i = 1; i < coords.length; i++) {
      final ring = _ringToLatLng(coords[i]);
      if (ring.length >= 3) holes.add(ring);
    }

    out.add(
      Polygon(
        polygonId: PolygonId('rz_$idx'),
        points: outer,
        holes: holes,
        strokeWidth: 2,
        // можно потом привести к твоим цветам
        strokeColor: errorColor,
        fillColor: chipBgColor.withOpacity(0.35), // 20% alpha
        consumeTapEvents: false,
      ),
    );
  }

  static List<LatLng> _ringToLatLng(dynamic ring) {
    if (ring is! List) return const [];

    final pts = <LatLng>[];
    for (final p in ring) {
      // GeoJSON point: [lon, lat]
      if (p is! List || p.length < 2) continue;
      final lon = (p[0] as num?)?.toDouble();
      final lat = (p[1] as num?)?.toDouble();
      if (lat == null || lon == null) continue;
      pts.add(LatLng(lat, lon));
    }

    // Часто кольцо замкнуто (последняя точка = первая) — можно оставить, но лучше убрать дубликат
    if (pts.length >= 2) {
      final a = pts.first;
      final b = pts.last;
      if (a.latitude == b.latitude && a.longitude == b.longitude) {
        pts.removeLast();
      }
    }

    return pts;
  }
}
