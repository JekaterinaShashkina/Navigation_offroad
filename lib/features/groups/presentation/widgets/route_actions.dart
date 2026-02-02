import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/features/routes/domain/entities/route_entity.dart';
import 'package:offroad_nav/features/routes/presentation/pages/route_detail_page.dart';

class RouteActions {
  static Future<void> openRouteById(
    BuildContext context,
    String routeId,
    String? groupId,
  ) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('routes')
          .doc(routeId)
          .get();

      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Route not found'),
            backgroundColor: errorColor,
          ),
        );
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] ?? 'Route').toString();
      final rawPoints = (data['points'] as List?) ?? const [];

      final points = rawPoints
          .map((p) => RoutePoint.fromAny(p))
          .toList();

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RouteDetailPage(
            name: name,
            points: points,
            groupId: groupId,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening route: $e'),
          backgroundColor: errorColor,
        ),
      );
    }
  }
}
