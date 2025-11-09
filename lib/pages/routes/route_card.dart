import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/images.dart';

class RouteCard extends StatelessWidget {
  const RouteCard({
    super.key,
    required this.title,
    required this.lengthText,
    required this.dateText,
    required this.isPrivate,
    required this.isOwner,
    this.onToggleVisibility,
    this.onDelete,
    this.onTap,
    this.widthFactor = 0.94,
  });

  final String title;
  final String lengthText;
  final String dateText;
  final bool isPrivate;
  final bool isOwner;
  final VoidCallback? onToggleVisibility;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    final chipColor = isPrivate ? Colors.red.shade100 : Colors.green.shade100;
    final chipText  = isPrivate ? Colors.red : Colors.green;

    return Align(
      alignment: Alignment.center,
      child: FractionallySizedBox(
        widthFactor: widthFactor, // ← делает поуже
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
                  // Меньше иконка
                  SizedBox(width: 28, height: 28, child: routesImage),
                  const SizedBox(width: 10),

                  // Контент
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Заголовок + чип/удаление справа
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
                            // Public/Private (только для владельца кликабельно)
                            InkWell(
                              onTap: isOwner ? onToggleVisibility : null,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: padding8, vertical: padding6),
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

                        // Инфо ПОД названием
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
