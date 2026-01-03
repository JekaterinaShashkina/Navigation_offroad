import 'package:location/location.dart';

Future<bool> ensureLocationPermissions(Location loc) async {
  bool serviceEnabled = await loc.serviceEnabled();
  if (!serviceEnabled) {
    serviceEnabled = await loc.requestService();
  }
  if (!serviceEnabled) return false;

  var perm = await loc.hasPermission();
  if (perm == PermissionStatus.denied) {
    perm = await loc.requestPermission();
  }

  if (perm != PermissionStatus.granted &&
      perm != PermissionStatus.grantedLimited) {
    return false;
  }

  return true;
}
