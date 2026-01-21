import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TrackingProfile { auto, walk, moto, def }

class TrackingProfileNotifier extends Notifier<TrackingProfile> {
  @override
  TrackingProfile build() => TrackingProfile.def;

  void set(TrackingProfile value) => state = value;
}

final trackingProfileProvider =
    NotifierProvider<TrackingProfileNotifier, TrackingProfile>(
  TrackingProfileNotifier.new,
);

extension TrackingProfileX on TrackingProfile {
  String get id => name; // безопасный стабильный id

  String get title {
    switch (this) {
      case TrackingProfile.auto:
        return 'Auto';
      case TrackingProfile.walk:
        return 'Walk';
      case TrackingProfile.moto:
        return 'Moto';
      case TrackingProfile.def:
        return 'Default';
    }
  }
}