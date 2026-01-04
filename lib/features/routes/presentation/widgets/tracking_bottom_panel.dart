import 'package:flutter/material.dart';

class TrackingBottomPanel extends StatelessWidget {
  final double remainingMeters;
  final Duration eta;
  final bool started;

  final VoidCallback? onPause;
  final VoidCallback? onFinish;

  const TrackingBottomPanel({
    super.key,
    required this.remainingMeters,
    required this.eta,
    required this.started,
    this.onPause,
    this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final km = remainingMeters / 1000;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Remaining: ${km.toStringAsFixed(2)} km',
                      style: const TextStyle(color: Colors.white)),
                  Text('ETA: ${eta.inMinutes} min',
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
            if (started) ...[
              IconButton(
                onPressed: onPause,
                icon: const Icon(Icons.pause, color: Colors.white),
              ),
              IconButton(
                onPressed: onFinish,
                icon: const Icon(Icons.flag, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
