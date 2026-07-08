import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:studconnect/data/app_database.dart';
import 'package:studconnect/data/repository.dart';

/// Shared helper for tests: a fresh, seeded [AppRepository] backed by an
/// in-memory SQLite database (via sqflite_common_ffi), so widget tests
/// exercise the real repository, not a mock.
Future<AppRepository> buildTestRepository() async {
  sqfliteFfiInit();
  final db = await AppDatabase.open(
    factory: databaseFactoryFfi,
    dbPath: inMemoryDatabasePath,
  );
  return AppRepository.create(db);
}
