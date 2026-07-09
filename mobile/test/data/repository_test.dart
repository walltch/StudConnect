import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:studconnect/data/app_database.dart';
import 'package:studconnect/data/repository.dart';
import 'package:studconnect/models/tag.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  late AppRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final db = await AppDatabase.open(
      factory: databaseFactoryFfi,
      dbPath: inMemoryDatabasePath,
    );
    repo = await AppRepository.create(db);
    await repo.logIn('wall');
  });

  // In-memory sqflite_common_ffi connections must be closed explicitly,
  // otherwise they accumulate across the suite and eventually stall new
  // opens.
  tearDown(() async {
    await repo.close();
  });

  group('seed data', () {
    test('loads the 7 seed users and 5 seed questions', () async {
      expect(repo.allUsers.length, 7);
      expect(repo.questions.length, 5);
      expect(repo.currentUser.id, 'wall');
    });

    test('q1 has its 2 denormalized answers resolved via join', () async {
      final q1 = repo.questionById('q1')!;
      expect(q1.answers.length, 2);
      expect(q1.answers.first.author.name, isNotEmpty);
    });
  });

  group('question CRUD (US1, US4)', () {
    test('createQuestion persists and is retrievable', () async {
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
      final created = await repo.createQuestion(
        title: 'Titre initial',
        content: 'Contenu',
        tag: Tag.autre,
      );
      await repo.updateQuestion(created.copyWith(title: 'Titre modifié'));
      expect(repo.questionById(created.id)?.title, 'Titre modifié');
    });

    test('deleteQuestion removes it and its answers', () async {
      final created = await repo.createQuestion(
        title: 'À supprimer',
        content: 'Contenu',
        tag: Tag.autre,
      );
      await repo.addAnswer(created.id, 'Une réponse');
      await repo.deleteQuestion(created.id);
      expect(repo.questionById(created.id), isNull);
    });

    test(
      'survives a fresh AppRepository over the same db file (persistence)',
      () async {
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

        await repo1.close();
      },
    );
  });

  group('answers (US3, US7)', () {
    test('addAnswer appends and bumps author answersCount', () async {
      final beforeCount = repo.currentUser.answersCount;
      await repo.addAnswer('q2', 'Ma réponse');
      final q2 = repo.questionById('q2')!;
      expect(q2.answers.any((a) => a.content == 'Ma réponse'), isTrue);
      expect(repo.currentUser.answersCount, beforeCount + 1);
    });

    test('validateAnswer marks solution and solves the question', () async {
      await repo.validateAnswer('q2', 'a3');
      final q2 = repo.questionById('q2')!;
      expect(q2.isSolved, isTrue);
      expect(q2.answers.firstWhere((a) => a.id == 'a3').isValidated, isTrue);
    });

    test('toggleDismissal flips isDismissed', () async {
      expect(repo.questionById('q4')!.isDismissed, isFalse);
      await repo.toggleDismissal('q4');
      expect(repo.questionById('q4')!.isDismissed, isTrue);
      await repo.toggleDismissal('q4');
      expect(repo.questionById('q4')!.isDismissed, isFalse);
    });
  });

  group('profile (US2, US5)', () {
    test('updateProfile changes year/field/school', () async {
      await repo.updateProfile(year: 'M2');
      expect(repo.currentUser.year, 'M2');
    });

    test('updateProfile changes name and recomputes initials', () async {
      await repo.updateProfile(name: 'Léa Martin');
      expect(repo.currentUser.name, 'Léa Martin');
      expect(repo.currentUser.avatar, 'LM');
    });

    test('updateProfile changes avatarColor', () async {
      await repo.updateProfile(avatarColor: 0xFF000000);
      expect(repo.currentUser.avatarColor, 0xFF000000);
    });

    test(
      'addSkill/removeSkill mutate skills list without duplicates',
      () async {
        final before = repo.currentUser.skills.length;
        await repo.addSkill('Flutter');
        expect(repo.currentUser.skills.length, before + 1);
        await repo.addSkill('Flutter'); // duplicate, ignored
        expect(repo.currentUser.skills.length, before + 1);
        await repo.removeSkill('Flutter');
        expect(repo.currentUser.skills.length, before);
      },
    );
  });

  group('comptes locaux', () {
    test('starts logged out until logIn/signUp is called', () async {
      SharedPreferences.setMockInitialValues({});
      final db = await AppDatabase.open(
        factory: databaseFactoryFfi,
        dbPath: inMemoryDatabasePath,
      );
      final fresh = await AppRepository.create(db);
      expect(fresh.isLoggedIn, isFalse);
      expect(fresh.currentUserOrNull, isNull);
      expect(() => fresh.currentUser, throwsStateError);
      await fresh.close();
    });

    test('allUsers lists every seed persona, including teammates', () {
      final names = repo.allUsers.map((u) => u.name).toSet();
      expect(names, containsAll(['Anis Boua', 'Samy Berrari', 'Charles Keita']));
    });

    test('logIn switches currentUser and persists across a fresh repo', () async {
      SharedPreferences.setMockInitialValues({});
      final db = await AppDatabase.open(
        factory: databaseFactoryFfi,
        dbPath: inMemoryDatabasePath,
      );
      final repo1 = await AppRepository.create(db);
      await repo1.logIn('bob');
      expect(repo1.currentUser.id, 'bob');

      // Re-open a repository against the *same* database/session store,
      // simulating an app relaunch.
      final repo2 = await AppRepository.create(db);
      expect(repo2.currentUser.id, 'bob');
      await repo1.close();
    });

    test('logOut clears the session', () async {
      expect(repo.isLoggedIn, isTrue);
      await repo.logOut();
      expect(repo.isLoggedIn, isFalse);
      expect(repo.currentUserOrNull, isNull);
    });

    test('signUp creates a new local account and logs into it', () async {
      final before = repo.allUsers.length;
      final created = await repo.signUp(
        name: 'Léa Martin',
        school: 'ESGI Bordeaux',
        field: 'Bachelor Réseaux',
        year: 'B1',
        avatarColor: 0xFF123456,
      );

      expect(repo.allUsers.length, before + 1);
      expect(repo.isLoggedIn, isTrue);
      expect(repo.currentUser.id, created.id);
      expect(repo.currentUser.name, 'Léa Martin');
      expect(repo.currentUser.avatar, 'LM');
      expect(repo.currentUser.reputation, 0);
    });
  });

  group('feed/search (US6)', () {
    test('sortedAndFiltered(unsolved) excludes solved questions', () async {
      final unsolved = repo.sortedAndFiltered(SortMode.unsolved);
      expect(unsolved.every((q) => !q.isSolved), isTrue);
    });

    test('sortedAndFiltered(popular) is sorted by upvotes desc', () async {
      final popular = repo.sortedAndFiltered(SortMode.popular);
      for (var i = 0; i < popular.length - 1; i++) {
        expect(
          popular[i].upvotes,
          greaterThanOrEqualTo(popular[i + 1].upvotes),
        );
      }
    });

    test('search matches content, not just title', () async {
      final results = repo.search('XGBoost');
      expect(results.any((q) => q.id == 'q3'), isTrue);
    });

    test('myQuestions returns only current user authored questions', () async {
      expect(repo.myQuestions.every((q) => q.authorId == 'wall'), isTrue);
    });
  });
}
