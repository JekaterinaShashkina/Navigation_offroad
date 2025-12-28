import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../design/images.dart';
import '../tracking/tracker_controller.dart';
import '../../../../design/widgets/app_bar.dart';
import '../utils/marker_icon.dart';
import '../utils/route_math.dart';
import '../widgets/route_action_bar.dart';
import '../widgets/tracker_map.dart';
import '../../domain/entities/route_entity.dart';
import '../../data/repositories/routes_repository.dart';

class RouteCreationPage extends StatefulWidget {
  const RouteCreationPage({super.key});

  @override
  State<RouteCreationPage> createState() => _RouteCreationPageState();
}

class _RouteCreationPageState extends State<RouteCreationPage> {
  final _ctrl = TrackerController();
  final _routesRepo = RoutesRepository();          // <-- репозиторий

   // размеры нижней панели (для паддинга карты)
  static const double _panelHeight = 70;
  static const double _panelBottom = 45;

  BitmapDescriptor? _customMarkerIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    _ctrl.start();
  }

 Future<void> _loadCustomMarker() async {
  final bitmap = await MarkerIcon.fromPngAsset(
    'assets/images/navigation_arrow.png',
    widthPx: 36,
    heightPx: 36,
  );

  if (!mounted) return;
  setState(() => _customMarkerIcon = bitmap);
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
    lengthKm += distanceM(_ctrl.track[i], _ctrl.track[i + 1]) / 1000.0;
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
            arrowIcon: _customMarkerIcon,
            lookAheadMeters: 0, 
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
                        actions: [
                          ActionButtonConfig(
                            label: 'Save',
                            iconWidget: saveIconNavigation,
                            onTap: _ctrl.track.length >= 2 ? _save : null,
                            enabled: _ctrl.track.length >= 2,
                            filled: _ctrl.track.length >= 2,
                          ),
                          ActionButtonConfig(
                            label: _ctrl.isRecording ? 'Pause' : 'Go',
                            iconWidget:
                                _ctrl.isRecording ? pauseIconNavigation : goIconNavigation,
                            onTap: () => _ctrl.isRecording
                                ? _ctrl.pauseRecording()
                                : _ctrl.startRecording(),
                            enabled: true,
                            filled: _ctrl.isRecording,
                          ),
                          ActionButtonConfig(
                            label: 'Delete',
                            iconWidget: deleteIconNavigation,
                            onTap: _ctrl.track.isNotEmpty ? _ctrl.clearTrack : null,
                            enabled: _ctrl.track.isNotEmpty,
                            filled: false,
                          ),
                        ],
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
