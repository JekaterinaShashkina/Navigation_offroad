// lib/pages/competitions/competitions_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/styles.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';

import 'package:offroad_nav/features/competition/application/providers/competitions_providers.dart';
import 'package:offroad_nav/features/competition/domain/entities/competition.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/competition_card.dart';
import 'package:offroad_nav/features/competition/presentation/widgets/filter_pill.dart';

import 'create_competition_page.dart';
import 'competition_view_page.dart';

enum _MyCompetitionsFilter { all, completed, upcoming, active }

class CompetitionsPage extends ConsumerStatefulWidget {
  const CompetitionsPage({super.key});

  @override
  ConsumerState<CompetitionsPage> createState() => _CompetitionsPageState();
}

class _CompetitionsPageState extends ConsumerState<CompetitionsPage> {
  final _searchCtrl = TextEditingController();
  _MyCompetitionsFilter _filter = _MyCompetitionsFilter.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final competitionsAsync = ref.watch(competitionsListProvider);

    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        title: 'Competitions',
        onPressed: () => Navigator.pop(context),
        // если в твоём NewAppBar нет actions — оставь обычный AppBar ниже.
      ),
      body: competitionsAsync.when(
        data: (items) {
          final filtered = _applyFilterAndSearch(items);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // Search pill
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: padding16),
                child: _SearchPill(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                ),
              ),

              const SizedBox(height: 12),

              // Filter pills row
              SizedBox(
                height: 38,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: padding16),
                  scrollDirection: Axis.horizontal,
                  children: [
                    FilterPill(
                      label: 'All',
                      selected: _filter == _MyCompetitionsFilter.all,
                      onTap: () => setState(() => _filter = _MyCompetitionsFilter.all),
                    ),

                    const SizedBox(width: 10),
                    FilterPill(
                      label: 'Upcoming',
                      selected: _filter == _MyCompetitionsFilter.upcoming,
                      onTap: () => setState(() => _filter = _MyCompetitionsFilter.upcoming),
                    ),
                    const SizedBox(width: 10),
                    FilterPill(
                      label: 'Active',
                      selected: _filter == _MyCompetitionsFilter.active,
                      onTap: () => setState(() => _filter = _MyCompetitionsFilter.active),
                    ),
                    const SizedBox(width: 10),
                    FilterPill(
                      label: 'Completed',
                      selected: _filter == _MyCompetitionsFilter.completed,
                      onTap: () => setState(() => _filter = _MyCompetitionsFilter.completed),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // List
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No competitions yet',
                          style: TextStyle(color: textHintColor),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          padding16,
                          0,
                          padding16,
                          90, // место под нижнюю кнопку
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final competition = filtered[index];
                          return CompetitionCard(
                            competition: competition,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CompetitionViewPage(competitionId: competition.id),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load competitions\n$e')),
      ),

      // Bottom "Create a competition" button like in design
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(padding16, 10, padding16, 14),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateCompetitionPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF6C645), // жёлтая как в макете
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: const Text(
                'Create a competition',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Competition> _applyFilterAndSearch(List<Competition> items) {
    // 1) фильтр по статусу
    Iterable<Competition> out = items;

    switch (_filter) {
      case _MyCompetitionsFilter.all:
        break;
      case _MyCompetitionsFilter.completed:
        out = out.where((c) => c.status == CompetitionStatus.ended);
        break;
      case _MyCompetitionsFilter.upcoming:
        out = out.where((c) => c.status == CompetitionStatus.upcoming);
        break;
      case _MyCompetitionsFilter.active:
        out = out.where((c) => c.status == CompetitionStatus.active);
        break;
    }

    // 2) поиск
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      out = out.where((c) {
        final name = (c.name).toLowerCase();
        return name.contains(q);
      });
    }

    return out.toList();
  }
}

/// Search pill
class _SearchPill extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const _SearchPill({
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search.....',
        hintStyle: hintTextStyle.copyWith(color: textHintColor),
        prefixIcon: const Icon(Icons.search, color: textHintColor),
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      ),
    );
  }
}
