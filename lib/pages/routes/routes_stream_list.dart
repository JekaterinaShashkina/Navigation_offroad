import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:offroad_nav/pages/routes/route_card.dart';
import 'package:offroad_nav/pages/routes/route_detail_page.dart';

enum RoutesTab { all, mine }

class RoutesStreamList extends StatelessWidget {
  const RoutesStreamList({
    super.key,
    required this.tab,
    required this.searchText,
  });

  final RoutesTab tab;
  final String searchText;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final Query<Map<String, dynamic>> baseQuery = switch (tab) {
      RoutesTab.all => FirebaseFirestore.instance
          .collection('routes')
          .where('isPrivate', isEqualTo: false)
          .orderBy('createdAt', descending: true),
      RoutesTab.mine => FirebaseFirestore.instance
          .collection('routes')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true),
    };

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: baseQuery.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final docs = snap.data?.docs ?? [];
        final q = searchText.trim().toLowerCase();

        final filtered = docs.where((d) {
          final m = d.data();
          final name = (m['name'] ?? '').toString().toLowerCase();
          final sub  = (m['subtitle'] ?? '').toString().toLowerCase();
          return q.isEmpty || name.contains(q) || sub.contains(q);
        }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('No routes found'));
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final doc = filtered[i];
            final m = doc.data();
            final uidCurr = uid;
            final isOwner = (m['userId'] == uidCurr);

            final len = (m['lengthKm'] is num) ? (m['lengthKm'] as num).toDouble() : null;
            final lengthText = len == null ? '-' : '${len.toStringAsFixed(2)} km';
            final ts = m['createdAt'];
            final dateText = (ts is Timestamp)
                ? ts.toDate().toLocal().toString().split('.')[0]
                : '';

            return RouteCard(
              title: (m['name'] ?? 'Unnamed').toString(),
              lengthText: lengthText,
              dateText: dateText,
              isPrivate: (m['isPrivate'] == true),
              isOwner: isOwner,
              onToggleVisibility: isOwner
                  ? () => doc.reference.update({'isPrivate': !(m['isPrivate'] == true)})
                  : null,
              onDelete: isOwner ? () => _confirmDelete(context, doc.id) : null,
              onTap: () => _openDetails(context, m),
            );
          },
        );
      },
    );
  }

  Future<void> _openDetails(BuildContext context, Map<String, dynamic> route) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteDetailPage(
          name: (route['name'] ?? 'Route').toString(),
          points: route['points'],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete route?'),
        content: const Text('Are you sure you want to delete this route?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('routes').doc(docId).delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
