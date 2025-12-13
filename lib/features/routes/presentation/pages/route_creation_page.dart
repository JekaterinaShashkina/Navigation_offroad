import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:offroad_nav/features/routes/application/controllers/tracker_controller.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/features/routes/presentation/widgets/route_action_bar.dart';
import 'package:offroad_nav/features/routes/presentation/widgets/tracker_map.dart';

// NEW: доменные штуки
import 'package:offroad_nav/features/routes/domain/entities/route_entity.dart';
import 'package:offroad_nav/features/routes/data/repositories/routes_repository.dart';
// import 'package:offroad_nav/features/routes/domain/repositories/routes_repository.dart';

class RouteCreationPage extends StatefulWidget {
  const RouteCreationPage({super.key});

  @override
  State<RouteCreationPage> createState() => _RouteCreationPageState();
}

class _RouteCreationPageState extends State<RouteCreationPage> {
  final _ctrl = TrackerController();
  final _routesRepo = RoutesRepository();          // <-- репозиторий

  //late final IRoutesRepository _routesRepo;

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
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );

  if (name == null || name.isEmpty) return;

  // считаем длину
  double lengthKm = 0;
  for (int i = 0; i + 1 < _ctrl.track.length; i++) {
    lengthKm += _distanceMeters(_ctrl.track[i], _ctrl.track[i + 1]) / 1000.0;
  }
  lengthKm = double.parse(lengthKm.toStringAsFixed(3));

  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final entity = RouteEntity(
    id: '', // id проставит Firestore, мы его вернём из saveRoute при желании
    ownerId: uid,
    name: name,
    points: _ctrl.track
        .map((p) => RoutePoint(p.latitude, p.longitude))
        .toList(),
    isPublic: false,        // по умолчанию приватный
    createdAt: DateTime.now(),
    lengthKm: lengthKm,
  );

  await _routesRepo.saveRoute(entity);

  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Route saved')),
  );

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
                  setState(() {});
                },
                child: const Icon(Icons.my_location, color: Colors.white),
              ),
            ),
          ),

          // Нижняя панель
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
