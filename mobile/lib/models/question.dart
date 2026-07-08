import 'answer.dart';
import 'tag.dart';
import 'user.dart';

/// Mirrors the `Question` interface from the web app's src/types/index.ts.
/// `author` and `answers` are resolved by the repository (joins), not
/// stored denormalized in SQLite.
class Question {
  const Question({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.author,
    required this.tag,
    required this.answers,
    required this.upvotes,
    required this.hasUpvoted,
    required this.isSolved,
    required this.views,
    required this.createdAt,
    this.lastCheckedAt,
    this.isDismissed = false,
  });

  final String id;
  final String title;
  final String content;
  final String authorId;
  final User author;
  final Tag tag;
  final List<Answer> answers;
  final int upvotes;
  final bool hasUpvoted;
  final bool isSolved;
  final int views;
  final DateTime createdAt;

  /// Last time the current user opened this question's detail screen.
  /// Used to compute "new activity since I last checked" (US8).
  final DateTime? lastCheckedAt;

  /// Whether the current user marked "je ne peux pas aider" on this
  /// question (US7).
  final bool isDismissed;

  /// True if an answer was added after [lastCheckedAt] (US8).
  bool get hasNewActivitySince {
    if (lastCheckedAt == null) return answers.isNotEmpty;
    return answers.any((a) => a.createdAt.isAfter(lastCheckedAt!));
  }

  Question copyWith({
    String? title,
    String? content,
    Tag? tag,
    List<Answer>? answers,
    int? upvotes,
    bool? hasUpvoted,
    bool? isSolved,
    int? views,
    DateTime? lastCheckedAt,
    bool? isDismissed,
  }) {
    return Question(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId,
      author: author,
      tag: tag ?? this.tag,
      answers: answers ?? this.answers,
      upvotes: upvotes ?? this.upvotes,
      hasUpvoted: hasUpvoted ?? this.hasUpvoted,
      isSolved: isSolved ?? this.isSolved,
      views: views ?? this.views,
      createdAt: createdAt,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }

  factory Question.fromMap(
    Map<String, Object?> map, {
    required User author,
    required List<Answer> answers,
    bool isDismissed = false,
  }) {
    return Question(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      authorId: map['authorId'] as String,
      author: author,
      tag: Tag.fromLabel(map['tag'] as String),
      answers: answers,
      upvotes: map['upvotes'] as int,
      hasUpvoted: (map['hasUpvoted'] as int) == 1,
      isSolved: (map['isSolved'] as int) == 1,
      views: map['views'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastCheckedAt: map['lastCheckedAt'] != null
          ? DateTime.parse(map['lastCheckedAt'] as String)
          : null,
      isDismissed: isDismissed,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'authorId': authorId,
      'tag': tag.label,
      'upvotes': upvotes,
      'hasUpvoted': hasUpvoted ? 1 : 0,
      'isSolved': isSolved ? 1 : 0,
      'views': views,
      'createdAt': createdAt.toIso8601String(),
      'lastCheckedAt': lastCheckedAt?.toIso8601String(),
    };
  }
}
