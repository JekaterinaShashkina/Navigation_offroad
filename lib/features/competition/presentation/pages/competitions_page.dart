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

class CompetitionsPage extends ConsumerStatefulWidget {
  const CompetitionsPage({super.key});

  @override
  ConsumerState<CompetitionsPage> createState() => _CompetitionsPageState();
}

class _CompetitionsPageState extends ConsumerState<CompetitionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

    @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }  

  @override
  Widget build(BuildContext context) {
    final competitionsAsync = ref.watch(competitionsListProvider);
    
    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: AppBar(
        title: const Text('Competitions'),
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateCompetitionPage()),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],      
      ),
body: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: textHintColor,
            labelColor: Colors.black,
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Active'),
              Tab(text: 'Past'),
            ],
          ),
          Expanded(
            child: competitionsAsync.when(
              data: (items) {
                final upcoming =
                    items.where((c) => c.status == CompetitionStatus.upcoming).toList();
                final active =
                    items.where((c) => c.status == CompetitionStatus.active).toList();
                final past =
                    items.where((c) => c.status == CompetitionStatus.ended).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(context, upcoming),
                    _buildList(context, active),
                    _buildList(context, past),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load competitions\n$e')),
            ),

                      ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateCompetitionPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  Widget _buildList(BuildContext context, List<Competition> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No competitions yet',
          style: TextStyle(color: textHintColor),
        ),
);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(padding16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final competition = items[index];
        return CompetitionCard(
          competition: competition,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CompetitionViewPage(competitionId: competition.id),
            ),
          ),
        );
      },
    );
  }
}
