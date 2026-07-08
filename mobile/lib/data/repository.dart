import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/answer.dart';
import '../models/question.dart';
import '../models/tag.dart';
import '../models/user.dart';
import 'app_database.dart';
import 'seed_data.dart';

enum SortMode { recent, popular, unsolved }

/// Single source of truth for the app's data: an in-memory cache that is
/// read-through for the UI (synchronous, instant) and write-through to
/// SQLite (every mutation persists before notifyListeners fires), so the
/// UI stays snappy while nothing is ever lost on process death.
class AppRepository extends ChangeNotifier {
  AppRepository._(this._db);

  final AppDatabase _db;
  Database get _sql => _db.db;

  final Map<String, User> _users = {};
  final Map<String, Question> _questions = {};
  int _idCounter = 0;

  static Future<AppRepository> create(AppDatabase db) async {
    final repo = AppRepository._(db);
    await repo._init();
    return repo;
  }

  Future<void> _init() async {
    if (await _db.isEmpty) {
      await _seed();
    }
    await _loadAll();
  }

  Future<void> _seed() async {
    final batch = _sql.batch();
    for (final u in SeedData.users) {
      batch.insert('users', u.toMap());
    }
    for (final (q, answers) in SeedData.questionsWithAnswers) {
      batch.insert('questions', q.toMap());
      for (final a in answers) {
        batch.insert('answers', a.toMap());
      }
    }
    await batch.commit(noResult: true);
  }

  Future<void> _loadAll() async {
    final userRows = await _sql.query('users');
    _users
      ..clear()
      ..addEntries(
        userRows.map((r) => MapEntry(r['id'] as String, User.fromMap(r))),
      );

    final dismissedIds = (await _sql.query(
      'question_dismissals',
    )).map((r) => r['questionId'] as String).toSet();

    final questionRows = await _sql.query(
      'questions',
      orderBy: 'createdAt DESC',
    );
    final answerRows = await _sql.query('answers', orderBy: 'createdAt ASC');

    final answersByQuestion = <String, List<Answer>>{};
    for (final r in answerRows) {
      final author = _users[r['authorId'] as String]!;
      final answer = Answer.fromMap(r, author: author);
      answersByQuestion.putIfAbsent(answer.questionId, () => []).add(answer);
    }

    _questions
      ..clear()
      ..addEntries(
        questionRows.map((r) {
          final id = r['id'] as String;
          final author = _users[r['authorId'] as String]!;
          final q = Question.fromMap(
            r,
            author: author,
            answers: answersByQuestion[id] ?? const [],
            isDismissed: dismissedIds.contains(id),
          );
          return MapEntry(id, q);
        }),
      );
  }

  // ---------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------

  User get currentUser => _users[SeedData.currentUserId]!;

  /// Sorted most-recent-first, matching the `questions` table's default
  /// ordering loaded in [_loadAll].
  List<Question> get questions =>
      _questions.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Question? questionById(String id) => _questions[id];

  List<Question> sortedAndFiltered(SortMode mode, {Tag? tag}) {
    var list = questions;
    if (tag != null) {
      list = list.where((q) => q.tag == tag).toList();
    }
    switch (mode) {
      case SortMode.recent:
        break;
      case SortMode.popular:
        list = [...list]..sort((a, b) => b.upvotes.compareTo(a.upvotes));
      case SortMode.unsolved:
        list = list.where((q) => !q.isSolved).toList();
    }
    return list;
  }

  List<Question> get myQuestions =>
      questions.where((q) => q.authorId == currentUser.id).toList();

  List<Question> get myAnsweredQuestions => questions
      .where((q) => q.answers.any((a) => a.authorId == currentUser.id))
      .toList();

  /// Same substring-match logic as the web's search page: case-insensitive
  /// OR match across title/content/tag.
  List<Question> search(String query, {Tag? tag}) {
    final q = query.trim().toLowerCase();
    return questions.where((question) {
      if (tag != null && question.tag != tag) return false;
      if (q.isEmpty) return true;
      return question.title.toLowerCase().contains(q) ||
          question.content.toLowerCase().contains(q) ||
          question.tag.label.toLowerCase().contains(q);
    }).toList();
  }

  int get questionsCount => _questions.length;

  int get answersCount =>
      _questions.values.fold(0, (sum, q) => sum + q.answers.length);

  int get resolvedPercent {
    if (_questions.isEmpty) return 0;
    final solved = _questions.values.where((q) => q.isSolved).length;
    return ((solved / _questions.length) * 100).round();
  }

  // ---------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------

  Future<Question> createQuestion({
    required String title,
    required String content,
    required Tag tag,
  }) async {
    final question = Question(
      id: _newId(),
      title: title,
      content: content,
      authorId: currentUser.id,
      author: currentUser,
      tag: tag,
      answers: const [],
      upvotes: 0,
      hasUpvoted: false,
      isSolved: false,
      views: 0,
      createdAt: DateTime.now(),
    );
    await _sql.insert('questions', question.toMap());
    await _bumpUser(currentUser.id, questionsDelta: 1);
    _questions[question.id] = question;
    notifyListeners();
    return question;
  }

  Future<void> updateQuestion(Question updated) async {
    await _sql.update(
      'questions',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [updated.id],
    );
    _questions[updated.id] = updated;
    notifyListeners();
  }

  Future<void> deleteQuestion(String id) async {
    await _sql.delete('answers', where: 'questionId = ?', whereArgs: [id]);
    await _sql.delete(
      'question_dismissals',
      where: 'questionId = ?',
      whereArgs: [id],
    );
    await _sql.delete('questions', where: 'id = ?', whereArgs: [id]);
    await _bumpUser(currentUser.id, questionsDelta: -1);
    _questions.remove(id);
    notifyListeners();
  }

  Future<void> toggleQuestionUpvote(String id) async {
    final q = _questions[id];
    if (q == null) return;
    final updated = q.copyWith(
      hasUpvoted: !q.hasUpvoted,
      upvotes: q.upvotes + (q.hasUpvoted ? -1 : 1),
    );
    await _sql.update(
      'questions',
      {'upvotes': updated.upvotes, 'hasUpvoted': updated.hasUpvoted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    _questions[id] = updated;
    notifyListeners();
  }

  Future<Answer> addAnswer(String questionId, String content) async {
    final question = _questions[questionId];
    if (question == null) {
      throw ArgumentError('Unknown question $questionId');
    }
    final answer = Answer(
      id: _newId(),
      questionId: questionId,
      authorId: currentUser.id,
      author: currentUser,
      content: content,
      upvotes: 0,
      isValidated: false,
      createdAt: DateTime.now(),
      hasUpvoted: false,
    );
    await _sql.insert('answers', answer.toMap());
    await _bumpUser(currentUser.id, answersDelta: 1);
    _questions[questionId] = question.copyWith(
      answers: [...question.answers, answer],
    );
    notifyListeners();
    return answer;
  }

  Future<void> toggleAnswerUpvote(String questionId, String answerId) async {
    final question = _questions[questionId];
    if (question == null) return;
    final answers = question.answers.map((a) {
      if (a.id != answerId) return a;
      return a.copyWith(
        hasUpvoted: !a.hasUpvoted,
        upvotes: a.upvotes + (a.hasUpvoted ? -1 : 1),
      );
    }).toList();
    final updatedAnswer = answers.firstWhere((a) => a.id == answerId);
    await _sql.update(
      'answers',
      {
        'upvotes': updatedAnswer.upvotes,
        'hasUpvoted': updatedAnswer.hasUpvoted ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [answerId],
    );
    _questions[questionId] = question.copyWith(answers: answers);
    notifyListeners();
  }

  /// Marks [answerId] as the validated solution (unsets any prior one on
  /// the same question) and flips the question to isSolved. Only the
  /// question's author should be able to trigger this from the UI.
  Future<void> validateAnswer(String questionId, String answerId) async {
    final question = _questions[questionId];
    if (question == null) return;
    final answers = question.answers
        .map((a) => a.copyWith(isValidated: a.id == answerId))
        .toList();

    final batch = _sql.batch();
    for (final a in answers) {
      batch.update(
        'answers',
        {'isValidated': a.isValidated ? 1 : 0},
        where: 'id = ?',
        whereArgs: [a.id],
      );
    }
    batch.update(
      'questions',
      {'isSolved': 1},
      where: 'id = ?',
      whereArgs: [questionId],
    );
    await batch.commit(noResult: true);

    _questions[questionId] = question.copyWith(
      answers: answers,
      isSolved: true,
    );
    notifyListeners();
  }

  /// "Indiquer si je réponds ou si je ne peux pas" (US7): toggles the
  /// current user's dismissal of a question they chose not to help with.
  Future<void> toggleDismissal(String questionId) async {
    final question = _questions[questionId];
    if (question == null) return;
    final dismissed = !question.isDismissed;
    if (dismissed) {
      await _sql.insert(
        'question_dismissals',
        {'questionId': questionId},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      await _sql.delete(
        'question_dismissals',
        where: 'questionId = ?',
        whereArgs: [questionId],
      );
    }
    _questions[questionId] = question.copyWith(isDismissed: dismissed);
    notifyListeners();
  }

  /// Records that the current user opened this question, clearing the
  /// "new activity" indicator used by US8.
  Future<void> markQuestionSeen(String id) async {
    final question = _questions[id];
    if (question == null) return;
    final now = DateTime.now();
    await _sql.update(
      'questions',
      {'lastCheckedAt': now.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
    _questions[id] = question.copyWith(lastCheckedAt: now);
    notifyListeners();
  }

  Future<void> updateProfile({String? school, String? field, String? year}) {
    final updated = currentUser.copyWith(
      school: school,
      field: field,
      year: year,
    );
    return _saveUser(updated);
  }

  Future<void> addSkill(String skill) {
    final trimmed = skill.trim();
    if (trimmed.isEmpty || currentUser.skills.contains(trimmed)) {
      return Future.value();
    }
    return _saveUser(
      currentUser.copyWith(skills: [...currentUser.skills, trimmed]),
    );
  }

  Future<void> removeSkill(String skill) {
    return _saveUser(
      currentUser.copyWith(
        skills: currentUser.skills.where((s) => s != skill).toList(),
      ),
    );
  }

  Future<void> _saveUser(User updated) async {
    await _sql.update(
      'users',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [updated.id],
    );
    _users[updated.id] = updated;
    notifyListeners();
  }

  Future<void> _bumpUser(
    String userId, {
    int questionsDelta = 0,
    int answersDelta = 0,
  }) async {
    final user = _users[userId]!;
    final updated = user.copyWith(
      questionsCount: user.questionsCount + questionsDelta,
      answersCount: user.answersCount + answersDelta,
    );
    await _sql.update(
      'users',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [userId],
    );
    _users[userId] = updated;
  }

  String _newId() {
    _idCounter++;
    return '${DateTime.now().microsecondsSinceEpoch}_$_idCounter';
  }
}
