// lib/pages/competitions/competitions_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/styles.dart';
import 'package:offroad_nav/design/images.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/features/competition/application/providers/competitions_providers.dart';
import 'package:offroad_nav/features/competition/domain/entities/competition.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/competition_card.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/filter_pill.dart';

import 'create_competition_page.dart';
import 'competition_view_page.dart';

class CompetitionsPage extends ConsumerStatefulWidget  {
  const CompetitionsPage({super.key});

  @override
  ConsumerState<CompetitionsPage> createState() => _CompetitionsPageState();
}

enum _Filter { all, completed }

class _CompetitionsPageState extends ConsumerState<CompetitionsPage> {
  final _search = TextEditingController();
  String _query = '';
  _Filter _filter = _Filter.all;

  // // демо-данные
  // final _items = const <_CompetitionVM>[
  //   _CompetitionVM(
  //     title: 'Bangabandhu Military Museum',
  //     place: 'Mumbai plaza green Road Taj tower',
  //   ),
  //   _CompetitionVM(
  //     title: 'Paradies Sweets',
  //     place: 'Rupokotha Road Mumbai india',
  //     completed: true,
  //   ),
  //   _CompetitionVM(
  //     title: 'Cheez & Beanz',
  //     place: 'Tajmohal Road Shekhertck Mumbai',
  //   ),
  //   _CompetitionVM(
  //     title: 'Royal Group of Industries',
  //     place: 'Mumbai plaza green Road Taj tower',
  //     completed: true,
  //   ),
  //   _CompetitionVM(
  //     title: 'SP Filling Station',
  //     place: 'Mumbai plaza green Road Taj tower',
  //   ),
  // ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Competition> _applyFilter(List<Competition> items) {
    final q = _query.trim().toLowerCase();

    return items.where((e) {
      if (_filter == _Filter.completed && !e.isCompleted) return false;

      if (q.isEmpty) return true;
      
      final title = e.title.toLowerCase();
      final desc = (e.description ?? '').toLowerCase();

      return title.toLowerCase().contains(q) || desc.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final competitionsAsync = ref.watch(myCompetitionsProvider);
    
    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        title: 'My competitions', onPressed: () => Navigator.pop(context),
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
                FilterPill(
                  label: 'All',
                  selected: _filter == _Filter.all,
                  onTap: () => setState(() => _filter = _Filter.all),
                ),
                const SizedBox(width: 12),
                FilterPill(
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
              child: competitionsAsync.when(
                data: (items) {
                  final filtered = _applyFilter(items);
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('Nothing found', style: hintTextStyle),
                    );
                  }
              return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final item = filtered[i];
                        return CompetitionCard(
                          title: item.title,
                          subtitle: item.description ?? item.rule,
                          completed: item.isCompleted,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CompetitionViewPage(
                                  competition: item,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(
                  child: Text(
                    'Failed to load competitions',
                    style: hintTextStyle,
                  ),
                ),
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

