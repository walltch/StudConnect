import 'user.dart';

/// Mirrors the `Answer` interface from the web app's src/types/index.ts.
/// `author` is resolved by the repository (join on authorId), not stored
/// denormalized in SQLite.
class Answer {
  const Answer({
    required this.id,
    required this.questionId,
    required this.authorId,
    required this.author,
    required this.content,
    required this.upvotes,
    required this.isValidated,
    required this.createdAt,
    required this.hasUpvoted,
  });

  final String id;
  final String questionId;
  final String authorId;
  final User author;
  final String content;
  final int upvotes;
  final bool isValidated;
  final DateTime createdAt;
  final bool hasUpvoted;

  Answer copyWith({int? upvotes, bool? isValidated, bool? hasUpvoted}) {
    return Answer(
      id: id,
      questionId: questionId,
      authorId: authorId,
      author: author,
      content: content,
      upvotes: upvotes ?? this.upvotes,
      isValidated: isValidated ?? this.isValidated,
      createdAt: createdAt,
      hasUpvoted: hasUpvoted ?? this.hasUpvoted,
    );
  }

  factory Answer.fromMap(Map<String, Object?> map, {required User author}) {
    return Answer(
      id: map['id'] as String,
      questionId: map['questionId'] as String,
      authorId: map['authorId'] as String,
      author: author,
      content: map['content'] as String,
      upvotes: map['upvotes'] as int,
      isValidated: (map['isValidated'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      hasUpvoted: (map['hasUpvoted'] as int) == 1,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'questionId': questionId,
      'authorId': authorId,
      'content': content,
      'upvotes': upvotes,
      'isValidated': isValidated ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'hasUpvoted': hasUpvoted ? 1 : 0,
    };
  }
}
