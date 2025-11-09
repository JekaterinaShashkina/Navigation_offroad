import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:offroad_nav/controllers/tracking/tracker_controller.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/design/images.dart';
import 'package:offroad_nav/design/styles.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/widgets/route_action_bar.dart';
import 'package:offroad_nav/design/widgets/tracker_map.dart';

// class RouteCreationPage extends StatefulWidget {
//   const RouteCreationPage({super.key});

//   @override
//   State<RouteCreationPage> createState() => _RouteCreationPageState();
// }

// class _RouteCreationPageState extends State<RouteCreationPage> {
//   GoogleMapController? _controller;
//   final Location _location = Location();
//   LatLng? _currentPosition;

//   double _heading = 0.0;

//   StreamSubscription<LocationData>? _locationSub;
//   StreamSubscription<CompassEvent>? _compassSub;
//   BitmapDescriptor? _arrowIcon;

//   final _database = FirebaseDatabase.instanceFor(
//     app: Firebase.app(),
//     databaseURL: 'https://react-ff62a-default-rtdb.europe-west1.firebasedatabase.app',
//   ).ref();
//   final String? userId = FirebaseAuth.instance.currentUser?.uid;

//   // ====== Запись маршрута ======
//   bool _isRecording = false;
//   Timer? _recordingTimer;
//   final List<LatLng> _recordingPoints = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadArrowIcon();
//     _initLocationTracking();
//     _listenCompass();
//   }

//   Future<void> _loadArrowIcon() async {
//     _arrowIcon = await BitmapDescriptor.fromAssetImage(
//       const ImageConfiguration(size: Size(48, 48)),
//       'assets/images/navigation_arrow.png',
//     );
//   }

//   Future<void> _initLocationTracking() async {
//     bool serviceEnabled = await _location.serviceEnabled();
//     if (!serviceEnabled) {
//       serviceEnabled = await _location.requestService();
//       if (!serviceEnabled) return;
//     }

//     PermissionStatus permission = await _location.hasPermission();
//     if (permission == PermissionStatus.denied) {
//       permission = await _location.requestPermission();
//       if (permission != PermissionStatus.granted) return;
//     }

//     _locationSub = _location.onLocationChanged.listen((loc) {
//       if (!mounted) return;
//       if (loc.latitude == null || loc.longitude == null) return;

//       final newPos = LatLng(loc.latitude!, loc.longitude!);
//       setState(() => _currentPosition = newPos);

//       _updateCameraPosition();
//       _sendToFirebase(newPos);

//       if (_isRecording &&
//           (_recordingPoints.isEmpty || _calculateDistance(_recordingPoints.last, newPos) > 0.003)) {
//         _recordingPoints.add(newPos);
//       }
//     });
//   }

//   void _listenCompass() {
//     _compassSub = FlutterCompass.events?.listen((event) {
//       if (!mounted) return;
//       final heading = event.heading ?? 0.0;
//       _heading = heading;

//       if (_currentPosition != null) {
//         _updateCameraPosition();
//       }
//     });
//   }

//   void _updateCameraPosition() {
//     if (_currentPosition == null || _controller == null) return;

//     const double zoom = 18;
//     const double forwardOffsetMeters = 80;

//     final target = _offsetFromPosition(_currentPosition!, forwardOffsetMeters, 0, _heading);

//     _controller?.moveCamera(
//       CameraUpdate.newCameraPosition(
//         CameraPosition(
//           target: target,
//           zoom: zoom,
//           tilt: 60,
//           bearing: _heading,
//         ),
//       ),
//     );
//   }

//   LatLng _offsetFromPosition(
//       LatLng position, double distanceForward, double distanceRight, double bearing) {
//     const double earthRadius = 6378137.0;
//     final radBearing = bearing * pi / 180;
//     final radRight = radBearing + pi / 2;

//     final deltaNorth = distanceForward * cos(radBearing) + distanceRight * cos(radRight);
//     final deltaEast = distanceForward * sin(radBearing) + distanceRight * sin(radRight);

//     final deltaLat = deltaNorth / earthRadius * (180 / pi);
//     final deltaLon = deltaEast / (earthRadius * cos(position.latitude * pi / 180)) * (180 / pi);

//     return LatLng(position.latitude + deltaLat, position.longitude + deltaLon);
//   }

//   void _sendToFirebase(LatLng pos) {
//     if (userId != null) {
//       _database.child("users/$userId/location").set({
//         'lat': pos.latitude,
//         'lng': pos.longitude,
//         'timestamp': ServerValue.timestamp,
//       });
//     }
//   }

//   double _calculateDistance(LatLng a, LatLng b) {
//     const double p = 0.017453292519943295;
//     final double lat1 = a.latitude;
//     final double lon1 = a.longitude;
//     final double lat2 = b.latitude;
//     final double lon2 = b.longitude;
//     final double a1 = 0.5 - cos((lat2 - lat1) * p) / 2 +
//         cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
//     return 12742 * asin(sqrt(a1)); // km
//   }

//   // =================== ЗАПИСЬ МАРШРУТА ===================
//   void _toggleRecording() {
//     if (_isRecording) {
//       _pauseRecording();
//     } else {
//       _startRecording();
//     }
//   }

//   void _startRecording() {
//     if (_isRecording) return;
//     setState(() => _isRecording = true);
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Recording started')),
//       );
//     }
//   }

//   void _pauseRecording() {
//     if (!_isRecording) return;
//     setState(() => _isRecording = false);
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Recording paused')),
//       );
//     }
//   }

//   void _deleteRecording() {
//     setState(() {
//       _isRecording = false;
//       _recordingPoints.clear();
//     });
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Route cleared')),
//       );
//     }
//   }

//   Future<void> _saveRecording() async {
//     if (_recordingPoints.length < 2) return;

//     final controller = TextEditingController();
//     final routeName = await showDialog<String>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('Save Route'),
//         content: TextField(
//           controller: controller,
//           autofocus: true,
//           decoration: const InputDecoration(hintText: 'Enter name'),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(ctx).pop(null),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
//             child: const Text('Save'),
//           ),
//         ],
//       ),
//     );

//     if (routeName == null || routeName.isEmpty) return;

//     final points = _recordingPoints
//         .map((p) => {'lat': p.latitude, 'lng': p.longitude})
//         .toList();

//     double lengthKm = 0.0;
//     for (int i = 0; i < _recordingPoints.length - 1; i++) {
//       lengthKm += _calculateDistance(_recordingPoints[i], _recordingPoints[i + 1]);
//     }

//     if (userId != null) {
//       await FirebaseFirestore.instance.collection('routes').add({
//         'userId': userId,
//         'name': routeName,
//         'points': points,
//         'lengthKm': double.parse(lengthKm.toStringAsFixed(3)),
//         'createdAt': Timestamp.fromDate(DateTime.now()),
//         'isPrivate': true,
//       });
//     }

//     // ✅ очищаем маршрут без snackbar
//     setState(() {
//       _isRecording = false;
//       _recordingPoints.clear();
//     });

//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Route saved')),
//       );
//     }
//   }

//   @override
//   void dispose() {
//     _locationSub?.cancel();
//     _compassSub?.cancel();
//     _recordingTimer?.cancel();
//     _controller?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: NewAppBar(
//         title: "Route Recording",
//         onPressed: () => Navigator.of(context).pop(),
//       ),
//       body: Stack(
//         children: [
//           GoogleMap(
//             mapType: MapType.hybrid,
//             initialCameraPosition: const CameraPosition(
//               target: LatLng(59.0, 26.0),
//               zoom: 12,
//             ),
//             polylines: {
//               if (_recordingPoints.isNotEmpty)
//                 Polyline(
//                   polylineId: const PolylineId('route'),
//                   color: Colors.orange,
//                   width: 6,
//                   points: _recordingPoints,
//                 ),
//             },
//             markers: {
//               if (_currentPosition != null)
//                 Marker(
//                   markerId: const MarkerId('current'),
//                   position: _currentPosition!,
//                   rotation: 0.0,
//                   icon: _arrowIcon ?? BitmapDescriptor.defaultMarker,
//                   anchor: const Offset(0.5, 0.5),
//                 ),
//             },
//             onMapCreated: (controller) => _controller = controller,
//             myLocationEnabled: false,
//             myLocationButtonEnabled: false,
//           ),

//           // Нижняя панель
//           Positioned(
//             bottom: 45,
//             left: 0,
//             right: 0,
//             child: SafeArea(
//               top: false,
//               child: Center(
//                 child: Container(
//                   width: 327,
//                   height: 70,
//                   decoration: BoxDecoration(
//                     color: Colors.black,
//                     borderRadius: BorderRadius.circular(60),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center, // центрируем весь ряд
//                     children: [
//                       // Save
//                       SizedBox(
//                         width: 103.67,
//                         height: 54,
//                         child: ElevatedButton(
//                           onPressed: _saveRecording,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: buttonSecondBackgroundColor,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(100),
//                               side: const BorderSide(color: Colors.white, width: 1),
//                             ),
//                             padding: EdgeInsets.zero,
//                           ),
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               saveIconNavigation,
//                               const SizedBox(height: 4),
//                               Text('Save', style: robotoRegular14TextStyle),
//                             ],
//                           ),
//                         ),
//                       ),

//                       // Go / Pause
//                       SizedBox(
//                         width: 103.67,
//                         height: 54,
//                         child: ElevatedButton(
//                           onPressed: _toggleRecording,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.black,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(100),
//                             ),
//                             padding: EdgeInsets.zero,
//                           ),
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               _isRecording ? pauseIconNavigation : goIconNavigation,
//                               const SizedBox(height: 4),
//                               Text(_isRecording ? 'Pause' : 'Go', style: robotoRegular14TextStyle),
//                             ],
//                           ),
//                         ),
//                       ),

//                       // Delete
//                       SizedBox(
//                         width: 103.67,
//                         height: 54,
//                         child: ElevatedButton(
//                           onPressed: _deleteRecording,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.black,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(100),
//                             ),
//                             padding: EdgeInsets.zero,
//                           ),
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               deleteIconNavigation,
//                               const SizedBox(height: 4),
//                               Text('Delete', style: robotoRegular14TextStyle),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


class RouteCreationPage extends StatefulWidget {
  const RouteCreationPage({super.key});

  @override
  State<RouteCreationPage> createState() => _RouteCreationPageState();
}

class _RouteCreationPageState extends State<RouteCreationPage> {
  final _ctrl = TrackerController();

  // размеры нижней панели (для паддинга карты)
  static const double _panelHeight = 70;
  static const double _panelBottom = 45;

  BitmapDescriptor? _arrowIcon;

  @override
  void initState() {
    super.initState();
    _loadArrow();
    _ctrl.start();
  }

  Future<void> _loadArrow() async {
    _arrowIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/navigation_arrow.png',
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_ctrl.track.length < 2) return;

    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Route'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    // считаем длину (км)
    double lengthKm = 0;
    for (int i = 0; i + 1 < _ctrl.track.length; i++) {
      lengthKm += _distanceMeters(_ctrl.track[i], _ctrl.track[i + 1]) / 1000.0;
    }
    lengthKm = double.parse(lengthKm.toStringAsFixed(3));

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('routes').add({
        'userId': uid,
        'name': name,
        'points': _ctrl.track
            .map((p) => {'lat': p.latitude, 'lng': p.longitude})
            .toList(),
        'lengthKm': lengthKm,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'isPrivate': true,
      });
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Route saved')));

    // очистка
    _ctrl.clearTrack();
  }

  // расстояние между точками, м
  double _distanceMeters(LatLng a, LatLng b) {
    const double R = 6378137.0;
    final double dLat = (b.latitude - a.latitude) * math.pi / 180.0;
    final double dLon = (b.longitude - a.longitude) * math.pi / 180.0;
    final double lat1 = a.latitude * math.pi / 180.0;
    final double lat2 = b.latitude * math.pi / 180.0;

    final double sinDLat = math.sin(dLat / 2);
    final double sinDLon = math.sin(dLon / 2);

    final double h = sinDLat * sinDLat +
        math.cos(lat1) * math.cos(lat2) * sinDLon * sinDLon;
    final double c = 2 * math.asin(math.min(1.0, math.sqrt(h)));
    return R * c;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        _panelHeight + _panelBottom + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: NewAppBar(
        title: 'Route Recording',
        onPressed: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          TrackerMap(
            controller: _ctrl,
            bottomPadding: bottomPadding,
            arrowIcon: _arrowIcon,
          ),

          // Re-center
          Positioned(
            right: 16,
            top: 16,
            child: SafeArea(
              bottom: false,
              child: FloatingActionButton.small(
                backgroundColor: Colors.black87,
                onPressed: () {
                  _ctrl.followMe = true;
                  // перерисуемся — TrackerMap сам подхватит followMe
                  setState(() {});
                },
                child: const Icon(Icons.my_location, color: Colors.white),
              ),
            ),
          ),

          // Нижняя панель — обновляется при изменении контроллера
          Positioned(
            left: 0,
            right: 0,
            bottom: _panelBottom,
            child: SafeArea(
              top: false,
              child: Center(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, _) {
                    return SizedBox(
                      width: 327,
                      child: RouteActionBar(
                        isRecording: _ctrl.isRecording,
                        onSave: _ctrl.track.length >= 2 ? _save : null,
                        onToggleGo: () => _ctrl.isRecording
                            ? _ctrl.pauseRecording()
                            : _ctrl.startRecording(),
                        onDelete:
                            _ctrl.track.isNotEmpty ? _ctrl.clearTrack : null,
                        canSave: _ctrl.track.length >= 2,
                        canDelete: _ctrl.track.isNotEmpty,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}