import 'package:flutter/material.dart';
import 'package:offroad_nav/features/routes/domain/entities/route_entity.dart';

import '../../../../design/colors.dart';
import '../../../../design/dimension.dart';
import '../../../../design/images.dart';

class RouteCard extends StatelessWidget {
  const RouteCard({
    super.key,
    required this.route,
    required this.isOwner,
    this.onToggleVisibility,
    this.onDelete,
    this.onTap,
    this.widthFactor = 0.94,
  });

  final RouteEntity route;
  final bool isOwner;
  final VoidCallback? onToggleVisibility;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    final isPrivate = !route.isPublic;

    final chipColor = isPrivate ? Colors.red.shade100 : Colors.green.shade100;
    final chipText  = isPrivate ? Colors.red : Colors.green;

    // длина
    final lengthText = route.lengthKm == null
        ? '-'
        : '${route.lengthKm!.toStringAsFixed(2)} km';

    // дата
    final dateText = route.createdAt.toLocal().toString().split('.')[0];

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
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 28, height: 28, child: routesImage),
                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Заголовок + чип + delete
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                route.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: fontSize16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: isOwner ? onToggleVisibility : null,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: padding8,
                                  vertical: padding6,
                                ),
                                decoration: BoxDecoration(
                                  color: chipColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isPrivate ? 'Private' : 'Public',
                                  style: TextStyle(
                                    color: chipText,
                                    fontWeight: FontWeight.w700,
                                    fontSize: fontSize12,
                                  ),
                                ),
                              ),
                            ),
                            if (isOwner) ...[
                              const SizedBox(width: 4),
                              IconButton(
                                icon: deleteIcon,
                                splashRadius: 18,
                                onPressed: onDelete,
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: padding6),

                        Text(
                          'Length: $lengthText   Date: $dateText',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: fontSize12,
                            color: textHintColor,
                          ),
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