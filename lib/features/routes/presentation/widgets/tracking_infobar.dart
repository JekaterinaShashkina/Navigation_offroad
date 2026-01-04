import 'package:flutter/material.dart';

class TrackingInfoBar extends StatelessWidget {
  const TrackingInfoBar({
    super.key,
    required this.started,
    required this.distToStartM,
    required this.remainingMeters,
    required this.eta,
    required this.elapsed,
  });

  final bool started;
  final double? distToStartM;
  final double remainingMeters;
  final Duration eta;
  final Duration elapsed;

  String _fmtKm(double meters) => (meters / 1000).toStringAsFixed(2);
  String _fmtMin(Duration d) => '${d.inMinutes} min';

  @override
  Widget build(BuildContext context) {
    final text = !started
        ? 'Go to the start: ${(distToStartM ?? 0).toStringAsFixed(0)} m'
        : 'Distance left: ${_fmtKm(remainingMeters)} km\n'
          'Time left: ${eta == Duration.zero ? '—' : _fmtMin(eta)} • Elapsed: ${_fmtMin(elapsed)}';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.65),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.25),
          ),
        ),
      ),
    );
  }
}
