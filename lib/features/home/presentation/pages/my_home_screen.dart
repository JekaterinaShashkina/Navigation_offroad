import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/profile_avatar_button.dart';
import 'package:offroad_nav/design/widgets/route_search_widget.dart';
import 'package:offroad_nav/pages/profile/profile_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  Future<String?> _getAvatarPath() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['img'] as String?;
  }

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    print('CURRENT USER: $user'); // временный лог в консоль

    return Scaffold(
      body: Stack(
        children: [
          // Google Map на фоне
          GoogleMap(
            initialCameraPosition: _initialPosition,
            mapType: MapType.hybrid,
            onMapCreated: (controller) => _controller.complete(controller),
          ),
// 🔍 Диагностический баннер
            // Positioned(
            //   top: 150,
            //   left: 16,
            //   child: Container(
            //     padding: const EdgeInsets.all(8),
            //     decoration: BoxDecoration(
            //       color: Colors.black.withOpacity(0.5),
            //       borderRadius: BorderRadius.circular(8),
            //     ),
            //     child: Builder(
            //       builder: (context) {
            //         final user = FirebaseAuth.instance.currentUser;
            //         if (user == null) {
            //           return const Text(
            //             'NOT LOGGED IN',
            //             style: TextStyle(color: Colors.white),
            //           );
            //         }
            //         return Text(
            //           'UID: ${user.uid}\n'
            //           'EMAIL: ${user.email ?? "no email"}',
            //           style: const TextStyle(color: Colors.white, fontSize: 11),
            //         );
            //       },
            //     ),
            //   ),
            // ),
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