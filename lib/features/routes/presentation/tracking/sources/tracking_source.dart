import 'dart:async';
import 'tracking_sample.dart';

abstract class ITrackingSource {
  Stream<TrackSample> watch();
  Future<void> pause();
  Future<void> resume();
  Future<void> dispose();
}
