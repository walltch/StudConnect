/// Mirrors the `User` interface from the web app's src/types/index.ts.
class User {
  const User({
    required this.id,
    required this.name,
    required this.avatar,
    required this.school,
    required this.field,
    required this.year,
    required this.skills,
    required this.reputation,
    required this.answersCount,
    required this.questionsCount,
    required this.joinedAt,
  });

  final String id;
  final String name;
  final String avatar;
  final String school;
  final String field;
  final String year;
  final List<String> skills;
  final int reputation;
  final int answersCount;
  final int questionsCount;
  final DateTime joinedAt;

  User copyWith({
    String? school,
    String? field,
    String? year,
    List<String>? skills,
    int? answersCount,
    int? questionsCount,
  }) {
    return User(
      id: id,
      name: name,
      avatar: avatar,
      school: school ?? this.school,
      field: field ?? this.field,
      year: year ?? this.year,
      skills: skills ?? this.skills,
      reputation: reputation,
      answersCount: answersCount ?? this.answersCount,
      questionsCount: questionsCount ?? this.questionsCount,
      joinedAt: joinedAt,
    );
  }

  factory User.fromMap(Map<String, Object?> map) {
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      avatar: map['avatar'] as String,
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
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'school': school,
      'field': field,
      'year': year,
      'skills': skills.join(','),
      'reputation': reputation,
      'answersCount': answersCount,
      'questionsCount': questionsCount,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }
}
