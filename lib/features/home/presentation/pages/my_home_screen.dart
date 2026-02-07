import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/features/friends/data/repositories/friends_repository.dart';
import 'package:offroad_nav/features/home/presentation/pages/notifications_page.dart';
import 'package:offroad_nav/features/home/presentation/notifications/pending_invites_snackbar.dart';
import 'package:offroad_nav/features/home/presentation/widgets/map_top_bar.dart';

class MyHomeScreen extends StatefulWidget {
  const MyHomeScreen({super.key});

  @override
  State<MyHomeScreen> createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(59.0, 26.0),
    zoom: 7,
  );

  late final PendingInvitesSnackbarController _pendingSnack;

@override
void initState() {
  super.initState();
  _pendingSnack = PendingInvitesSnackbarController();
  _pendingSnack.start(context);
}
  @override
  void dispose() {
    _pendingSnack.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: backgroundMainColor,
      body: Stack(
        children: [
          // Google Map на фоне
          GoogleMap(
            initialCameraPosition: _initialPosition,
            mapType: MapType.hybrid,
            mapToolbarEnabled: false,     
            zoomControlsEnabled: false,   
            compassEnabled: false,        
            myLocationButtonEnabled: false, 
            onMapCreated: (controller) => _controller.complete(controller),
          ),
          // Белая панель с аватаркой
          Positioned(top: 0, left: 0, right: 0, child: MapTopBar()),

          // Кнопка меню снизу справа
          Positioned(
            bottom: 100,
            right: 20,
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, '/main_menu'),
              borderRadius: BorderRadius.circular(25),
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: surfaceColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 24,
                        height: 3,
                        decoration: BoxDecoration(
                          color: textMainColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 15,
                        height: 3,
                        decoration: BoxDecoration(
                          color: textMainColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: height8),
                      Container(
                        width: 24,
                        height: 3,
                        decoration: BoxDecoration(
                          color: textMainColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
