/// Mirrors the `User` interface from the web app's src/types/index.ts,
/// plus [avatarColor] for the local account system (signup/profile).
class User {
  const User({
    required this.id,
    required this.name,
    required this.avatar,
    required this.avatarColor,
    required this.school,
    required this.field,
    required this.year,
    required this.skills,
    required this.reputation,
    required this.answersCount,
    required this.questionsCount,
    required this.joinedAt,
    required this.username,
    required this.passwordHash,
    this.photoPath = '',
  });

  final String id;
  final String name;
  final String avatar;

  /// ARGB value (`Color.toARGB32()`), chosen from `AppColors.avatarPalette`.
  final int avatarColor;
  final String school;
  final String field;
  final String year;
  final List<String> skills;
  final int reputation;
  final int answersCount;
  final int questionsCount;
  final DateTime joinedAt;

  /// Login identifier, unique across accounts (compared case-insensitively).
  final String username;

  /// SHA-256 hex digest — local-only account system, unsalted is an
  /// accepted simplification here (see AppRepository docs).
  final String passwordHash;

  /// Local file path to a chosen avatar photo. Empty string means "no
  /// photo, fall back to the colored initials circle" — chosen over a
  /// nullable sentinel so `copyWith` can express "remove the photo"
  /// without a separate flag.
  final String photoPath;

  /// Two-letter initials derived from a display name, e.g. "Wall Fatah" -> "WF".
  static String initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase());
    final initials = letters.join();
    return initials.isEmpty ? '?' : initials;
  }

  User copyWith({
    String? name,
    String? avatar,
    int? avatarColor,
    String? school,
    String? field,
    String? year,
    List<String>? skills,
    int? answersCount,
    int? questionsCount,
    String? photoPath,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      avatarColor: avatarColor ?? this.avatarColor,
      school: school ?? this.school,
      field: field ?? this.field,
      year: year ?? this.year,
      skills: skills ?? this.skills,
      reputation: reputation,
      answersCount: answersCount ?? this.answersCount,
      questionsCount: questionsCount ?? this.questionsCount,
      joinedAt: joinedAt,
      username: username,
      passwordHash: passwordHash,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  factory User.fromMap(Map<String, Object?> map) {
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      avatar: map['avatar'] as String,
      avatarColor: map['avatarColor'] as int,
      school: map['school'] as String,
      field: map['field'] as String,
      year: map['year'] as String,
      skills: (map['skills'] as String)
          .split(',')
          .where((s) => s.isNotEmpty)
          .toList(),
      reputation: map['reputation'] as int,
      answersCount: map['answersCount'] as int,
      questionsCount: map['questionsCount'] as int,
      joinedAt: DateTime.parse(map['joinedAt'] as String),
      username: map['username'] as String,
      passwordHash: map['passwordHash'] as String,
      photoPath: map['photoPath'] as String? ?? '',
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'avatarColor': avatarColor,
      'school': school,
      'field': field,
      'year': year,
      'skills': skills.join(','),
      'reputation': reputation,
      'answersCount': answersCount,
      'questionsCount': questionsCount,
      'joinedAt': joinedAt.toIso8601String(),
      'username': username,
      'passwordHash': passwordHash,
      'photoPath': photoPath,
    };
  }
}
