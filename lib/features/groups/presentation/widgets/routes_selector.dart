import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';

class RoutesSelector extends StatefulWidget {
  final String? initialActiveRouteId;
  final bool isLeader;
  final void Function(String routeId) onOpen;
  final Future<void> Function(String routeId) onSelect;

  const RoutesSelector({
    super.key,
    required this.initialActiveRouteId,
    required this.isLeader,
    required this.onOpen,
    required this.onSelect,
  });

  @override
  State<RoutesSelector> createState() => _RoutesSelectorState();
}

class _RoutesSelectorState extends State<RoutesSelector> {
  String? _activeRouteId;

  @override
  void initState() {
    super.initState();
    _activeRouteId = widget.initialActiveRouteId;
  }

  Future<void> _handleSetActive(String routeId) async {
    // обновляем в Firestore
    await widget.onSelect(routeId);

    // и сразу обновляем локальное состояние, чтобы UI подсветился
    if (!mounted) return;
    setState(() {
      _activeRouteId = routeId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeRouteId = _activeRouteId;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(radius20),
          topRight: Radius.circular(radius20),
        ),
      ),
      child: Column(
        children: [
          if (activeRouteId != null)
            Container(
              margin: const EdgeInsets.all(padding16),
              padding: const EdgeInsets.all(padding12),
              decoration: BoxDecoration(
                color: backgroundMainColor,
                borderRadius: BorderRadius.circular(radius12),
                border: Border.all(color: listShadowColor, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: buttonBackgroundColor),
                  const SizedBox(width: width16),
                  const Expanded(
                    child: Text(
                      'Active route',
                      style: TextStyle(
                        fontSize: fontSize16,
                        fontWeight: FontWeight.w500,
                        color: textMainColor,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => widget.onOpen(activeRouteId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonBackgroundColor,
                      foregroundColor: textMainColor,
                    ),
                    child: const Text('Open'),
                  ),
                ],
              ),
            ),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('routes')
                  .where('isPrivate', isEqualTo: false)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No routes found'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(padding16),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    final data = d.data();
                    final name = (data['name'] ?? 'Unnamed').toString();
                    final isActive = activeRouteId == d.id;

                    return GestureDetector(
                      onTap: () => widget.onOpen(d.id),
                      child: Container(
                        padding: const EdgeInsets.all(padding12),
                        decoration: BoxDecoration(
                          color: backgroundMainColor,
                          borderRadius: BorderRadius.circular(radius12),
                          border: Border.all(
                            color: isActive
                                ? buttonBackgroundColor
                                : listShadowColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.route, color: textMainColor),
                            const SizedBox(width: width16),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: fontSize16,
                                  color: textMainColor,
                                ),
                              ),
                            ),
                            if (isActive)
                              ElevatedButton(
                                onPressed: () => widget.onOpen(d.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonBackgroundColor,
                                  foregroundColor: textMainColor,
                                ),
                                child: const Text('Open'),
                              )
                            else if (widget.isLeader)
                              ElevatedButton(
                                onPressed: () => _handleSetActive(d.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonBackgroundColor,
                                  foregroundColor: textMainColor,
                                ),
                                child: const Text('Set active'),
                              )
                            else
                              ElevatedButton(
                                onPressed: () => widget.onOpen(d.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonBackgroundColor,
                                  foregroundColor: textMainColor,
                                ),
                                child: const Text('Open'),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
