import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/features/home/presentation/widgets/profile_avatar_button.dart';
import 'package:offroad_nav/design/widgets/route_search_widget.dart';

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

  @override
  Widget build(BuildContext context) {

   // final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Stack(
        children: [
          // Google Map на фоне
          GoogleMap(
            initialCameraPosition: _initialPosition,
            mapType: MapType.hybrid,
            onMapCreated: (controller) => _controller.complete(controller),
          ),
          // Белая панель с аватаркой
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 135,
              color: surfaceColor,
              padding: const EdgeInsets.symmetric(horizontal: padding16, vertical: 40),
                child: Row(
                  children: const [
                    ProfileAvatarButton(size: 50),
                    SizedBox(width: width16),
                    Expanded(child: SizedBox()),
                  ],
                ),
            ),
          ),

          // Поле поиска и результаты (независимо от белой панели)
          Positioned(
            top: 45,
            right: 16,
            child: SizedBox(
              width: 300,
              child: const RouteSearchWidget(),
            ),
          ),

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