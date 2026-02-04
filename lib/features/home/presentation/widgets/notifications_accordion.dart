import 'package:flutter/material.dart';
import 'package:offroad_nav/design/widgets/accordion_card.dart';
import 'package:offroad_nav/features/friends/data/repositories/friend_requests_repository.dart';

// builders чтобы NotificationsPage могла переиспользовать стиль плитки
typedef RequestTileBuilder = Widget Function(FriendRequestModel req);

class NotificationsAccordion extends StatelessWidget {
  const NotificationsAccordion({
    super.key,
    required this.incomingRequests,
    required this.outgoingRequests,
    required this.buildIncomingItem,
    required this.buildOutgoingItem,
    this.initiallyExpanded = true,
    this.previewLimit = 5,
    this.onShowAllIncoming,
    this.onShowAllOutgoing,
  });

  final List<FriendRequestModel> incomingRequests;
  final List<FriendRequestModel> outgoingRequests;

  final RequestTileBuilder buildIncomingItem;
  final RequestTileBuilder buildOutgoingItem;

  final bool initiallyExpanded;
  final int previewLimit;

  final VoidCallback? onShowAllIncoming;
  final VoidCallback? onShowAllOutgoing;

  @override
  Widget build(BuildContext context) {
    // previews как в routes
    final incPreview = incomingRequests.take(previewLimit).toList();
    final incHasMore = incomingRequests.length > previewLimit;

    final outPreview = outgoingRequests.take(previewLimit).toList();
    final outHasMore = outgoingRequests.length > previewLimit;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      children: [
        AccordionCard(
          title: 'Friend requests',
          count: incomingRequests.length,
          initiallyExpanded: initiallyExpanded,
          child: incPreview.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No incoming requests'),
                )
              : Column(
                  children: [
                    for (final req in incPreview) ...[
                      buildIncomingItem(req),
                      const SizedBox(height: 10),
                    ],
                    if (incHasMore && onShowAllIncoming != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: onShowAllIncoming,
                          child: const Text('Show all'),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 10),

        AccordionCard(
          title: 'Awaiting confirmation',
          count: outgoingRequests.length,
          initiallyExpanded: initiallyExpanded,
          child: outPreview.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No outgoing requests'),
                )
              : Column(
                  children: [
                    for (final req in outPreview) ...[
                      buildOutgoingItem(req),
                      const SizedBox(height: 10),
                    ],
                    if (outHasMore && onShowAllOutgoing != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: onShowAllOutgoing,
                          child: const Text('Show all'),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
