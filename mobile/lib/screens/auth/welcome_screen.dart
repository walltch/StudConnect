import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared/user_avatar.dart';

/// Landing screen when logged out: pick an existing local account or
/// create a new one. No password — this is a single-device local
/// account system, not a synced/secured one (see AppRepository docs).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final accounts = repo.allUsers;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'StudConnect',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'La mémoire collective étudiante',
              style: TextStyle(color: AppColors.slate600),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/signup'),
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: const Text('Créer un compte'),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'OU CONNECTE-TOI À UN COMPTE EXISTANT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.slate600,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 10),
            for (final account in accounts) ...[
              AppCard(
                padding: const EdgeInsets.all(12),
                onTap: () => repo.logIn(account.id),
                child: Row(
                  children: [
                    UserAvatar(user: account, radius: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${account.year} · ${account.field}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.slate600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.slate600,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
