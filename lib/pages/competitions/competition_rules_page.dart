import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/styles.dart';
import 'package:offroad_nav/design/images.dart';

class CompetitionRulesPage extends StatelessWidget {
  final String? current;

  const CompetitionRulesPage({super.key, this.current});

  @override
  Widget build(BuildContext context) {
    final rules = const [
      ('Fastest time', _lorem),
      ('Most waypoints', _lorem),
      ('Checkpoint hunt', _lorem),
      ('Fuel economy challenge', _lorem),
    ];

    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: AppBar(
        backgroundColor: backgroundMainColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: arrowBackImage, onPressed: () => Navigator.pop(context)),
        title: const Text('Rules', style: head1TextStyle),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: rules.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final (title, text) = rules[i];
          final selected = current == title;
          return Material(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.pop(context, title),
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
                          child: Text(title,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700, color: textMainColor)),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle, color: Colors.black, size: 20),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(text, style: hintTextStyle),
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

const _lorem =
    'Lorem ipsum, or lipsum as it is sometimes known, is dummy text used in laying out print, '
    'graphic or web designs. In publishing and graphic design, Lorem ipsum is a placeholder text.';
