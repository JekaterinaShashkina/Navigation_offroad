import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/styles.dart';
import 'package:offroad_nav/design/widgets/app_bar.dart';
import 'package:offroad_nav/features/competition/domain/config/competition_rules.dart';

class CompetitionRulesPage extends StatelessWidget {
  final String? current;

  const CompetitionRulesPage({super.key, this.current});

  @override
  Widget build(BuildContext context) {
    final rules = competitionRules;

    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: NewAppBar(
        title: 'Rules', onPressed: () => Navigator.pop(context),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: rules.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final rule = rules[i];
          final selected = current == rule.title;

          return Material(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.pop(context, rule.title),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x141A1A1A), blurRadius: 16, offset: Offset(0, 8)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(rule.title,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700, color: textMainColor)),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle, color: Colors.black, size: 20),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(rule.description, style: hintTextStyle),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

