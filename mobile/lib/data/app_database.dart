import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Owns the single-file SQLite database (studconnect.db).
///
/// Tests inject [factory] (sqflite_common_ffi) and [dbPath]
/// (inMemoryDatabasePath) so the repository layer can be exercised
/// against a real SQLite engine without a platform channel.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static Future<AppDatabase> open({
    DatabaseFactory? factory,
    String? dbPath,
  }) async {
    final dbFactory = factory ?? databaseFactory;
    final path = dbPath ?? await _defaultPath();

    final db = await dbFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(version: 1, onCreate: _onCreate),
    );
    return AppDatabase._(db);
  }

  static Future<String> _defaultPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'studconnect.db');
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        avatar TEXT NOT NULL,
        avatarColor INTEGER NOT NULL,
        school TEXT NOT NULL,
        field TEXT NOT NULL,
        year TEXT NOT NULL,
        skills TEXT NOT NULL,
        reputation INTEGER NOT NULL,
        answersCount INTEGER NOT NULL,
        questionsCount INTEGER NOT NULL,
        joinedAt TEXT NOT NULL,
        username TEXT NOT NULL,
        passwordHash TEXT NOT NULL,
        photoPath TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE questions(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        authorId TEXT NOT NULL,
        tag TEXT NOT NULL,
        upvotes INTEGER NOT NULL DEFAULT 0,
        hasUpvoted INTEGER NOT NULL DEFAULT 0,
        isSolved INTEGER NOT NULL DEFAULT 0,
        views INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        lastCheckedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE answers(
        id TEXT PRIMARY KEY,
        questionId TEXT NOT NULL,
        authorId TEXT NOT NULL,
        content TEXT NOT NULL,
        upvotes INTEGER NOT NULL DEFAULT 0,
        isValidated INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        hasUpvoted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE question_dismissals(
        questionId TEXT PRIMARY KEY
      )
    ''');
  }

  Future<bool> get isEmpty async {
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM questions');
    return (rows.first['c'] as int) == 0;
  }

  Future<void> close() => db.close();
}
