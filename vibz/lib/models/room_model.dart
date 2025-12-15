import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  final String id;
  final String name;
  final String createdBy;
  final DateTime? createdAt;
  final bool isPublic;

  final Map<String, RoomMember> members;
  final RoomSettings settings;
  final NowPlaying? nowPlaying;

  RoomModel({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.isPublic,
    required this.members,
    required this.settings,
    this.createdAt,
    this.nowPlaying,
  });

  factory RoomModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;

    final membersMap = <String, RoomMember>{};
    final rawMembers = data['members'] as Map<String, dynamic>? ?? {};
    rawMembers.forEach((uid, value) {
      membersMap[uid] = RoomMember.fromMap(value);
    });

    return RoomModel(
      id: doc.id,
      name: data['name'] ?? '',
      createdBy: data['createdBy'] ?? '',
      isPublic: data['isPublic'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      members: membersMap,
      settings: RoomSettings.fromMap(data['settings'] ?? {}),
      nowPlaying: data['nowPlaying'] != null
          ? NowPlaying.fromMap(data['nowPlaying'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdBy': createdBy,
      'isPublic': isPublic,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'members': members.map((k, v) => MapEntry(k, v.toMap())),
      'settings': settings.toMap(),
      'nowPlaying': nowPlaying?.toMap(),
    };
  }
}

/* ---------------- MEMBER ---------------- */

class RoomMember {
  final String name;
  final String role; // host | listener
  final DateTime? joinedAt;

  RoomMember({
    required this.name,
    required this.role,
    this.joinedAt,
  });

  factory RoomMember.fromMap(Map<String, dynamic> map) {
    return RoomMember(
      name: map['name'] ?? '',
      role: map['role'] ?? 'listener',
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'joinedAt': joinedAt != null
          ? Timestamp.fromDate(joinedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}

/* ---------------- SETTINGS ---------------- */

class RoomSettings {
  final int voteWindowSec;
  final bool autoplay;
  final bool allowGuests;

  RoomSettings({
    required this.voteWindowSec,
    required this.autoplay,
    required this.allowGuests,
  });

  factory RoomSettings.fromMap(Map<String, dynamic> map) {
    return RoomSettings(
      voteWindowSec: map['voteWindowSec'] ?? 30,
      autoplay: map['autoplay'] ?? true,
      allowGuests: map['allowGuests'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'voteWindowSec': voteWindowSec,
      'autoplay': autoplay,
      'allowGuests': allowGuests,
    };
  }
}

/* ---------------- NOW PLAYING ---------------- */

class NowPlaying {
  final String trackId;
  final DateTime? startedAt;

  NowPlaying({
    required this.trackId,
    this.startedAt,
  });

  factory NowPlaying.fromMap(Map<String, dynamic> map) {
    return NowPlaying(
      trackId: map['trackId'],
      startedAt: (map['startedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trackId': trackId,
      'startedAt': startedAt != null
          ? Timestamp.fromDate(startedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
