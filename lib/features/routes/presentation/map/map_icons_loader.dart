import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/marker_icon.dart';

class MapIconsLoader {
  Future<BitmapDescriptor> loadArrow() {
    return MarkerIcon.fromPngAsset(
      'assets/images/navigation_arrow.png',
      widthPx: 36,
      heightPx: 36,
    );
  }

  Future<BitmapDescriptor> loadCrown() {
    return MarkerIcon.fromPngAsset(
      'assets/images/leader_crown.png',
      widthPx: 24,
      heightPx: 24,
    );
  }
}
