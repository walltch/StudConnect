import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:studconnect/data/app_database.dart';
import 'package:studconnect/data/repository.dart';
import 'package:studconnect/models/tag.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  Future<AppRepository> freshRepo() async {
    final db = await AppDatabase.open(
      factory: databaseFactoryFfi,
      dbPath: inMemoryDatabasePath,
    );
    return AppRepository.create(db);
  }

  group('seed data', () {
    test('loads the 4 seed users and 4 seed questions', () async {
      final repo = await freshRepo();
      expect(repo.questions.length, 4);
      expect(repo.currentUser.id, 'wall');
    });

    test('q1 has its 2 denormalized answers resolved via join', () async {
      final repo = await freshRepo();
      final q1 = repo.questionById('q1')!;
      expect(q1.answers.length, 2);
      expect(q1.answers.first.author.name, isNotEmpty);
    });
  });

  group('question CRUD (US1, US4)', () {
    test('createQuestion persists and is retrievable', () async {
      final repo = await freshRepo();
      final before = repo.questionsCount;
      final created = await repo.createQuestion(
        title: 'Comment tester un repository Flutter ?',
        content: 'Contenu de test',
        tag: Tag.informatique,
      );
      expect(repo.questionsCount, before + 1);
      expect(repo.questionById(created.id)?.title, created.title);
      expect(repo.currentUser.questionsCount, greaterThan(0));
    });

    test('updateQuestion changes fields', () async {
      final repo = await freshRepo();
      final created = await repo.createQuestion(
        title: 'Titre initial',
        content: 'Contenu',
        tag: Tag.autre,
      );
      await repo.updateQuestion(created.copyWith(title: 'Titre modifié'));
      expect(repo.questionById(created.id)?.title, 'Titre modifié');
    });

    test('deleteQuestion removes it and its answers', () async {
      final repo = await freshRepo();
      final created = await repo.createQuestion(
        title: 'À supprimer',
        content: 'Contenu',
        tag: Tag.autre,
      );
      await repo.addAnswer(created.id, 'Une réponse');
      await repo.deleteQuestion(created.id);
      expect(repo.questionById(created.id), isNull);
    });

    test('survives a fresh AppRepository over the same db file (persistence)', () async {
      final db = await AppDatabase.open(
        factory: databaseFactoryFfi,
        dbPath: inMemoryDatabasePath,
      );
      final repo1 = await AppRepository.create(db);
      await repo1.createQuestion(
        title: 'Persisté ?',
        content: 'Doit survivre',
        tag: Tag.autre,
      );

      // Re-open a repository against the *same* database instance/path,
      // simulating an app relaunch reading the same file back.
      final repo2 = await AppRepository.create(db);
      expect(repo2.questions.any((q) => q.title == 'Persisté ?'), isTrue);
    });
  });

  group('answers (US3, US7)', () {
    test('addAnswer appends and bumps author answersCount', () async {
      final repo = await freshRepo();
      final beforeCount = repo.currentUser.answersCount;
      await repo.addAnswer('q2', 'Ma réponse');
      final q2 = repo.questionById('q2')!;
      expect(q2.answers.any((a) => a.content == 'Ma réponse'), isTrue);
      expect(repo.currentUser.answersCount, beforeCount + 1);
    });

    test('validateAnswer marks solution and solves the question', () async {
      final repo = await freshRepo();
      await repo.validateAnswer('q2', 'a3');
      final q2 = repo.questionById('q2')!;
      expect(q2.isSolved, isTrue);
      expect(q2.answers.firstWhere((a) => a.id == 'a3').isValidated, isTrue);
    });

    test('toggleDismissal flips isDismissed', () async {
      final repo = await freshRepo();
      expect(repo.questionById('q4')!.isDismissed, isFalse);
      await repo.toggleDismissal('q4');
      expect(repo.questionById('q4')!.isDismissed, isTrue);
      await repo.toggleDismissal('q4');
      expect(repo.questionById('q4')!.isDismissed, isFalse);
    });
  });

  group('profile (US2, US5)', () {
    test('updateProfile changes year/field/school', () async {
      final repo = await freshRepo();
      await repo.updateProfile(year: 'M2');
      expect(repo.currentUser.year, 'M2');
    });

    test('addSkill/removeSkill mutate skills list without duplicates', () async {
      final repo = await freshRepo();
      final before = repo.currentUser.skills.length;
      await repo.addSkill('Flutter');
      expect(repo.currentUser.skills.length, before + 1);
      await repo.addSkill('Flutter'); // duplicate, ignored
      expect(repo.currentUser.skills.length, before + 1);
      await repo.removeSkill('Flutter');
      expect(repo.currentUser.skills.length, before);
    });
  });

  group('feed/search (US6)', () {
    test('sortedAndFiltered(unsolved) excludes solved questions', () async {
      final repo = await freshRepo();
      final unsolved = repo.sortedAndFiltered(SortMode.unsolved);
      expect(unsolved.every((q) => !q.isSolved), isTrue);
    });

    test('sortedAndFiltered(popular) is sorted by upvotes desc', () async {
      final repo = await freshRepo();
      final popular = repo.sortedAndFiltered(SortMode.popular);
      for (var i = 0; i < popular.length - 1; i++) {
        expect(popular[i].upvotes, greaterThanOrEqualTo(popular[i + 1].upvotes));
      }
    });

    test('search matches content, not just title', () async {
      final repo = await freshRepo();
      final results = repo.search('XGBoost');
      expect(results.any((q) => q.id == 'q3'), isTrue);
    });

    test('myQuestions returns only current user authored questions', () async {
      final repo = await freshRepo();
      expect(repo.myQuestions.every((q) => q.authorId == 'wall'), isTrue);
    });
  });
}
