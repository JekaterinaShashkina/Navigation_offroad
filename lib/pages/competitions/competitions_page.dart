// lib/pages/competitions/competitions_page.dart
import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/styles.dart';
import 'package:offroad_nav/design/images.dart';

import 'create_competition_page.dart';
import 'competition_view_page.dart';

class CompetitionsPage extends StatefulWidget {
  const CompetitionsPage({super.key});

  @override
  State<CompetitionsPage> createState() => _CompetitionsPageState();
}

enum _Filter { all, completed }

class _CompetitionVM {
  final String title;
  final String place;
  final bool completed;

  const _CompetitionVM({
    required this.title,
    required this.place,
    this.completed = false,
  });
}

class _CompetitionsPageState extends State<CompetitionsPage> {
  final _search = TextEditingController();
  String _query = '';
  _Filter _filter = _Filter.all;

  // демо-данные
  final _items = const <_CompetitionVM>[
    _CompetitionVM(
      title: 'Bangabandhu Military Museum',
      place: 'Mumbai plaza green Road Taj tower',
    ),
    _CompetitionVM(
      title: 'Paradies Sweets',
      place: 'Rupokotha Road Mumbai india',
      completed: true,
    ),
    _CompetitionVM(
      title: 'Cheez & Beanz',
      place: 'Tajmohal Road Shekhertck Mumbai',
    ),
    _CompetitionVM(
      title: 'Royal Group of Industries',
      place: 'Mumbai plaza green Road Taj tower',
      completed: true,
    ),
    _CompetitionVM(
      title: 'SP Filling Station',
      place: 'Mumbai plaza green Road Taj tower',
    ),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<_CompetitionVM> get _filtered {
    final q = _query.trim().toLowerCase();
    return _items.where((e) {
      if (_filter == _Filter.completed && !e.completed) return false;
      if (q.isEmpty) return true;
      return e.title.toLowerCase().contains(q) || e.place.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: AppBar(
        backgroundColor: backgroundMainColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: arrowBackImage,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My competitions', style: head1TextStyle),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(padding16, padding16, padding16, padding16),
        child: Column(
          children: [
            // Search
            SizedBox(
              height: 50,
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search....',
                  hintStyle: hintTextStyle,
                  prefixIcon: const Icon(Icons.search, color: textHintColor),
                  contentPadding: const EdgeInsets.symmetric(horizontal: padding16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFE6E6EA)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFE6E6EA)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFD0D0D6)),
                  ),
                  filled: true,
                  fillColor: surfaceColor,
                ),
              ),
            ),
            const SizedBox(height: height12),

            // Tabs
            Row(
              children: [
                _Pill(
                  label: 'All',
                  selected: _filter == _Filter.all,
                  onTap: () => setState(() => _filter = _Filter.all),
                ),
                const SizedBox(width: 12),
                _Pill(
                  label: 'Completed',
                  selected: _filter == _Filter.completed,
                  onTap: () => setState(() => _filter = _Filter.completed),
                ),
                const Spacer(),
                Container(
                  height: 36,
                  width: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6E6EA),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: height12),

            // Список
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(child: Text('Nothing found', style: hintTextStyle))
                  : ListView.separated(
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final item = _filtered[i];
                        return _CompetitionCard(
                          title: item.title,
                          subtitle: item.place,
                          completed: item.completed,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CompetitionViewPage(
                                  title: item.title,
                                  description:
                                      'Mumbai plaza green Road Taj tower — short placeholder description.',
                                  initialRule: 'Fastest time',
                                ),
                              ),
                            );
                          },
                        ); 
                      },
                    ), 
            ), 

            const SizedBox(height: height12),

            // Кнопка "Create a competition"
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateCompetitionPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shape: const StadiumBorder(),
                  backgroundColor: const Color(0xFFF4C84A),
                  foregroundColor: Colors.black,
                ),
                child: const Text(
                  'Create a competition',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompetitionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool completed;
  final VoidCallback? onTap;

  const _CompetitionCard({
    required this.title,
    required this.subtitle,
    required this.completed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Color(0x141A1A1A), blurRadius: 16, offset: Offset(0, 8)),
            ],
            color: surfaceColor,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6E6EA),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  completed ? Icons.check_rounded : Icons.schedule_rounded,
                  size: 18,
                  color: const Color(0xFF717784),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: textMainColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: hintTextStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Color(0xFF9AA2AE)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.black : const Color(0xFFE6E6EA),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF5B606B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
