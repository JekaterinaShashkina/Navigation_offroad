import 'dart:async';
import 'tracking_sample.dart';

abstract class ITrackingSource {
  Stream<TrackSample> watch();
  Future<void> dispose();
}