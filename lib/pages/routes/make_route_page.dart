import 'package:flutter/material.dart';
import 'package:offroad_nav/design/widgets/app_button.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/pages/routes/route_creation_page.dart';
import 'package:offroad_nav/pages/routes/route_planner_page.dart';

class MakeRoutePage extends StatelessWidget {
  const MakeRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NewAppBar(
        title: "Make a route",
        onPressed: () => Navigator.pop(context),
      ),
      body: Container(
        color: backgroundMainColor,
        width: double.infinity,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppButton(
                text: "Drive/walk",
                foregroundColor: textMainColor,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RouteCreationPage()),
                  );
                },
              ),
              const SizedBox(height: 20),
              AppButton(
                text: "Add waypoints",
                foregroundColor: surfaceColor,
                backgroundColor: bgNightColor,
                // secondaryBackground: true,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RoutePlannerPage()),
                  );                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}