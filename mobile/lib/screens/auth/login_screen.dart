import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared/auth_header.dart';
import '../../widgets/shared/user_avatar.dart';

/// Real login screen: identifiant + mot de passe, checked locally against
/// the on-device accounts (see AppRepository.logInWithCredentials — no
/// backend, this is a single-device local account system). The full
/// account list is still reachable (collapsed under "Comptes de démo")
/// for convenience when demoing/grading, but it's no longer the primary
/// flow.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _error;
  bool _showDemoAccounts = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AppRepository repo) async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final ok = await repo.logInWithCredentials(
      _usernameController.text,
      _passwordController.text,
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = ok ? null : 'Identifiant ou mot de passe incorrect.';
    });
  }

  void _forgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Fonctionnalité à venir sur cette version locale — '
          'utilise un compte de démo en attendant.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const AuthHeader(
                    subtitle: 'La mémoire collective étudiante',
                  ),
                  const SizedBox(height: 28),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Identifiant',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          onSubmitted: (_) => _submit(repo),
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _forgotPassword,
                            child: const Text('Mot de passe oublié ?'),
                          ),
                        ),
                        if (_error != null) ...[
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                        ],
                        const SizedBox(height: 4),
                        ElevatedButton(
                          onPressed: _submitting ? null : () => _submit(repo),
                          child: Text(
                            _submitting ? 'Connexion…' : 'Se connecter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OU',
                          style: TextStyle(color: AppColors.slate600),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/signup'),
                      icon: const Icon(Icons.person_add_alt_1, size: 18),
                      label: const Text('Créer un compte'),
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _showDemoAccounts = !_showDemoAccounts),
                    icon: Icon(
                      _showDemoAccounts
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 18,
                    ),
                    label: const Text('Comptes de démo'),
                  ),
                  if (_showDemoAccounts) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Mot de passe pour tous les comptes de démo : password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.slate600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final account in repo.allUsers) ...[
                      AppCard(
                        padding: const EdgeInsets.all(12),
                        onTap: () => repo.logIn(account.id),
                        child: Row(
                          children: [
                            UserAvatar(user: account, radius: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    account.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
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
                      const SizedBox(height: 8),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
