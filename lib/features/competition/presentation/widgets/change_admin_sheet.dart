import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/widgets/pill_nav_row.dart';
import 'package:offroad_nav/design/widgets/form_fields_label.dart'; // pillInputDecoration

class UserPickItem {
  final String uid;
  final String name;
  final String email;

  const UserPickItem({
    required this.uid,
    required this.name,
    required this.email,
  });
}

class ChangeAdminSheet extends StatefulWidget {
  const ChangeAdminSheet({
    super.key,
    required this.currentAdminId,
    this.title = 'Select administrator',
  });

  final String currentAdminId;
  final String title;

  @override
  State<ChangeAdminSheet> createState() => _ChangeAdminSheetState();
}

class _ChangeAdminSheetState extends State<ChangeAdminSheet> {
  final _ctrl = TextEditingController();

  bool _loading = false;
  String? _error;
  final List<DocumentSnapshot> _results = [];

  String _capFirst(String s) => s.isEmpty ? s : (s[0].toUpperCase() + s.substring(1));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final raw = _ctrl.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _results.clear();
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _results.clear();
    });

    final q = raw;
    final qLower = raw.toLowerCase();
    final qCap = _capFirst(qLower);

    try {
      final Map<String, DocumentSnapshot> bucket = {};

      Future<void> _byName(String needle) async {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where('name', isGreaterThanOrEqualTo: needle)
            .where('name', isLessThanOrEqualTo: '$needle\uf8ff')
            .limit(50)
            .get();
        for (final d in snap.docs) {
          bucket[d.id] = d;
        }
      }

      Future<void> _byEmail(String needle) async {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isGreaterThanOrEqualTo: needle)
            .where('email', isLessThanOrEqualTo: '$needle\uf8ff')
            .limit(50)
            .get();
        for (final d in snap.docs) {
          bucket[d.id] = d;
        }
      }

      // prefix варианты (почти как в твоём SendInvitePage)
      await _byName(q);
      if (qLower != q) await _byName(qLower);
      if (qCap != q && qCap != qLower) await _byName(qCap);

      await _byEmail(q);
      if (qLower != q) await _byEmail(qLower);

      // fallback: добираем и фильтруем contains() на клиенте
      if (bucket.length < 10) {
        final extraByName = await FirebaseFirestore.instance
            .collection('users')
            .orderBy('name')
            .limit(150)
            .get();

        for (final d in extraByName.docs) {
          final data = (d.data() as Map?) ?? {};
          final name = (data['name'] ?? '').toString().toLowerCase();
          final email = (data['email'] ?? '').toString().toLowerCase();
          if (name.contains(qLower) || email.contains(qLower)) {
            bucket[d.id] = d;
          }
        }

        if (bucket.length < 10) {
          final extraByEmail = await FirebaseFirestore.instance
              .collection('users')
              .orderBy('email')
              .limit(150)
              .get();

          for (final d in extraByEmail.docs) {
            final data = (d.data() as Map?) ?? {};
            final name = (data['name'] ?? '').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            if (name.contains(qLower) || email.contains(qLower)) {
              bucket[d.id] = d;
            }
          }
        }
      }

      final filtered = bucket.values
          .where((doc) => doc.id != widget.currentAdminId) // не показываем текущего админа
          .toList();

      if (!mounted) return;
      setState(() => _results.addAll(filtered));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Search failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _pick(DocumentSnapshot doc) {
    final data = (doc.data() as Map?) ?? {};
    final email = (data['email'] ?? '').toString().trim();
    final name = (data['name'] ?? '').toString().trim();

    final title = name.isNotEmpty
        ? name
        : (email.contains('@') ? email.split('@').first : email);

    Navigator.pop(
      context,
      UserPickItem(uid: doc.id, name: title, email: email),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: backgroundSecondColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      widget.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 10),

            SizedBox(
              height: 50,
              child: TextField(
                controller: _ctrl,
                onSubmitted: (_) => _search(),
                decoration: pillInputDecoration('Search name or email...').copyWith(
                  prefixIcon: const Icon(Icons.search_rounded, color: textHintColor),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.tune_rounded, color: textHintColor),
                    onPressed: _search,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Flexible(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                      : _results.isEmpty
                          ? const Center(
                              child: Text(
                                'Type a name or email to search',
                                style: TextStyle(color: textHintColor, fontWeight: FontWeight.w600),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: _results.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final u = _results[i];
                                final data = (u.data() as Map?) ?? {};
                                final email = (data['email'] ?? '').toString();
                                final name = (data['name'] ?? '').toString();

                                final title = name.isNotEmpty
                                    ? name
                                    : (email.contains('@') ? email.split('@').first : email);

                                return PillNavRow(
                                  title: title,
                                  subtitle: email.isNotEmpty ? email : null,
                                  leading: const Icon(Icons.person_rounded, color: textHintColor),
                                  trailing: const Icon(Icons.chevron_right_rounded, color: textHintColor),
                                  onTap: () => _pick(u),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
