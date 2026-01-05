import 'package:cloud_firestore/cloud_firestore.dart';

class CompetitionParticipant {
  final String uid;
  final DateTime joinedAt;
  final String? displayName;
  final String? photoUrl;

  const CompetitionParticipant({
    required this.uid,
    required this.joinedAt,
    this.displayName,
    this.photoUrl,
  });

  factory CompetitionParticipant.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return CompetitionParticipant(
      uid: doc.id,
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ??
          (data['created_at'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      displayName: data['displayName'] as String? ?? data['name'] as String?,
      photoUrl: data['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'joinedAt': Timestamp.fromDate(joinedAt),
      if (displayName != null) 'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }
}