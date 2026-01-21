import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/images.dart';
import 'package:offroad_nav/features/routes/domain/entities/completed_route_entity.dart';

class CompletedRouteCard extends StatelessWidget {
  const CompletedRouteCard({
    super.key,
    required this.item,
    this.onTap,
    this.widthFactor = 0.94,
  });

  final CompletedRouteEntity item;
  final VoidCallback? onTap;
  final double widthFactor;

  String _formatKm(double? meters) {
    if (meters == null) return '-';
    final km = meters / 1000.0;
    return '${km.toStringAsFixed(2)} km';
  }

  String _formatDuration(int? sec) {
    if (sec == null) return '-';
    final d = Duration(seconds: sec);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    final d = dt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final title = (item.routeName?.trim().isNotEmpty ?? false)
        ? item.routeName!.trim()
        : 'Unnamed route';

    final lengthText = _formatKm(item.distanceMeters);
    final durText = _formatDuration(item.durationSec);
    final dateText = _formatDate(item.createdAt);

    // чип справа (можешь поменять логику/тексты)
    final chipLabel = switch (item.mode) {
      'solo' => 'Solo',
      'group' => 'Group',
      'competition' => 'Race',
      _ => 'Route',
    };

    final chipColor = switch (item.mode) {
      'solo' => Colors.blue.shade100,
      'group' => Colors.green.shade100,
      'competition' => Colors.orange.shade100,
      _ => Colors.grey.shade200,
    };

    final chipText = item.competitionId != null
        ? Colors.orange.shade900
        : Colors.blue.shade900;

    return Align(
      alignment: Alignment.center,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Material(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(radius12),
          child: InkWell(
            borderRadius: BorderRadius.circular(radius12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 28, height: 28, child: routesImage),
                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: fontSize16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: padding8,
                                vertical: padding6,
                              ),
                              decoration: BoxDecoration(
                                color: chipColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                chipLabel,
                                style: TextStyle(
                                  color: chipText,
                                  fontWeight: FontWeight.w700,
                                  fontSize: fontSize12,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: padding6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Length: $lengthText  km · Time: $durText'),
                            const SizedBox(height: 2),
                            Text(
                              'Date: $dateText',
                              style: TextStyle(
                                fontSize: fontSize12,
                                color: textHintColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
