import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:studconnect/data/app_database.dart';
import 'package:studconnect/data/repository.dart';

/// Shared helper for tests: a fresh, seeded [AppRepository] backed by an
/// in-memory SQLite database (via sqflite_common_ffi), so widget tests
/// exercise the real repository, not a mock.
///
/// [autoLogin] logs in as the "wall" seed persona by default, since most
/// existing screen tests assume an already-connected AppRepository.
/// Auth-flow tests (welcome/signup) pass `autoLogin: false` to exercise
/// the logged-out state.
///
/// `setMockInitialValues({})` resets shared_preferences' mock store so
/// session state never leaks between tests.
Future<AppRepository> buildTestRepository({bool autoLogin = true}) async {
  sqfliteFfiInit();
  SharedPreferences.setMockInitialValues({});
  final db = await AppDatabase.open(
    factory: databaseFactoryFfi,
    dbPath: inMemoryDatabasePath,
  );
  final repo = await AppRepository.create(db);
  if (autoLogin) {
    await repo.logIn('wall');
  }
  return repo;
}
