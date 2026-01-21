import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/dimension.dart';
import 'package:offroad_nav/design/widgets/pill_nav_row.dart';
import 'package:offroad_nav/features/routes/presentation/tracking/sources/live_tracking_source.dart';
import 'package:offroad_nav/features/routes/presentation/tracking/settings/tracking_profile.dart';

class TrackingSettingsSheet extends ConsumerWidget {
  const TrackingSettingsSheet({
    super.key,
    required this.onApplyProfile,
  });

  final Future<void> Function(TrackingProfile p) onApplyProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(trackingProfileProvider);

    final items = const [
      TrackingProfile.auto,
      TrackingProfile.walk,
      TrackingProfile.moto,
    ];

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: backgroundMainColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: textMainColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tracking settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Tracking mode',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: height12),

            ...items.map((p) {
              final selected = p == current;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PillNavRow(
                  title: p.title,
                  leading: Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: selected ? buttonBackgroundColor : textHintColor,
                  ),
                  trailing: const Icon(Icons.chevron_right, color: textHintColor),
                  onTap: () async {
                    ref.read(trackingProfileProvider.notifier).set(p);
                    await onApplyProfile(p); // ✅ GPS apply
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
