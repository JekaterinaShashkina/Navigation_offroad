import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:offroad_nav/features/groups/presentation/models/live_user_view.dart';

class LeaderFollowState {
  final String? leaderId;
  final LatLng? leaderPos;
  final double? leaderHeading;
  final bool followLeader;

  const LeaderFollowState({
    required this.leaderId,
    required this.leaderPos,
    required this.leaderHeading,
    required this.followLeader,
  });

  LeaderFollowState copyWith({
    String? leaderId,
    LatLng? leaderPos,
    double? leaderHeading,
    bool? followLeader,
  }) {
    return LeaderFollowState(
      leaderId: leaderId ?? this.leaderId,
      leaderPos: leaderPos ?? this.leaderPos,
      leaderHeading: leaderHeading ?? this.leaderHeading,
      followLeader: followLeader ?? this.followLeader,
    );
  }

  static const empty = LeaderFollowState(
    leaderId: null,
    leaderPos: null,
    leaderHeading: null,
    followLeader: false,
  );
}

class LeaderFollowController {
  LeaderFollowState _state = LeaderFollowState.empty;
  LeaderFollowState get state => _state;

  void setLeaderId(String? id) {
    if (id == _state.leaderId) return;
    _state = _state.copyWith(leaderId: id);
  }

  void applyUsers(List<LiveUserView> users) {
    final id = _state.leaderId;
    if (id == null) return;

    final leader = users.where((u) => u.userId == id).cast<LiveUserView?>().firstWhere(
          (u) => u != null,
          orElse: () => null,
        );

    if (leader == null) {
      _state = _state.copyWith(leaderPos: null, leaderHeading: null);
      return;
    }
    _state = _state.copyWith(
      leaderPos: LatLng(leader.lat, leader.lng),
      leaderHeading: leader.heading,
    );
  }

  /// Возвращает true если включили follow, false если выключили.
  bool toggleFollow() {
    _state = _state.copyWith(followLeader: !_state.followLeader);
    return _state.followLeader;
  }
}
