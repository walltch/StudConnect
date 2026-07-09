import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/app_database.dart';
import 'data/repository.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await AppDatabase.open();
  final repository = await AppRepository.create(db);
  runApp(StudConnectApp(repository: repository));
}

class StudConnectApp extends StatelessWidget {
  const StudConnectApp({super.key, required this.repository});

  final AppRepository repository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: repository,
      child: MaterialApp.router(
        title: 'StudConnect',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: buildAppRouter(repository),
      ),
    );
  }
}
