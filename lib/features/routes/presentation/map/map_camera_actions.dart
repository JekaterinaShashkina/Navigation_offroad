import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapCameraActions {
  static Future<void> centerOn({
    required GoogleMapController? controller,
    required LatLng? target,
    double zoom = 17,
    double tilt = 60,
    double bearing = 0,
  }) async {
    if (controller == null || target == null) return;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: zoom,
          tilt: tilt,
          bearing: bearing,
        ),
      ),
    );
  }

  static Future<void> faceNorth({
    required GoogleMapController? controller,
    required LatLng? keepTarget,
    double zoom = 17,
    double tilt = 60,
  }) async {
    if (controller == null || keepTarget == null) return;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: keepTarget,
          zoom: zoom,
          tilt: tilt,
          bearing: 0,
        ),
      ),
    );
  }
}
