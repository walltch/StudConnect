import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:studconnect/data/app_database.dart';
import 'package:studconnect/data/repository.dart';
import 'package:studconnect/main.dart';

Future<AppRepository> _testRepository() async {
  sqfliteFfiInit();
  final db = await AppDatabase.open(
    factory: databaseFactoryFfi,
    dbPath: inMemoryDatabasePath,
  );
  return AppRepository.create(db);
}

void main() {
  testWidgets('app boots on the feed tab with the bottom nav visible', (
    tester,
  ) async {
    final repository = await _testRepository();
    await tester.pumpWidget(StudConnectApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text("Fil d'actualité"), findsWidgets);
    expect(find.text('Rechercher'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Poser une question'), findsOneWidget);
  });

  testWidgets('bottom nav switches tabs', (tester) async {
    final repository = await _testRepository();
    await tester.pumpWidget(StudConnectApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Profil'), findsWidgets);
  });
}
