import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repository.dart';
import '../../models/user.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared/auth_header.dart';
import '../../widgets/shared/avatar_picker.dart';

/// Creates a new local account. Navigation back to the app happens
/// automatically once AppRepository.signUp logs the new account in —
/// the router's redirect reacts to isLoggedIn via refreshListenable.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _schoolController = TextEditingController(text: 'ESGI Bordeaux');
  final _fieldController = TextEditingController();
  final _yearController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  int _avatarColor = 0;
  String _photoPath = '';
  bool _usernameEdited = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _avatarColor = AppColors.avatarPalette.first.toARGB32();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _usernameController.dispose();
    _schoolController.dispose();
    _fieldController.dispose();
    _yearController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    if (_usernameEdited) return;
    setState(() => _usernameController.text = _slugify(_nameController.text));
  }

  static String _slugify(String name) {
    const accents = {
      'à': 'a', 'â': 'a', 'ä': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'î': 'i', 'ï': 'i',
      'ô': 'o', 'ö': 'o', 'œ': 'oe',
      'ù': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c',
    };
    var slug = name.trim().toLowerCase();
    accents.forEach((accented, plain) => slug = slug.replaceAll(accented, plain));
    final parts = slug
        .split(RegExp(r'[^a-z0-9]+'))
        .where((p) => p.isNotEmpty);
    return parts.join('.');
  }

  bool get _usernameTaken =>
      _usernameController.text.trim().isNotEmpty &&
      !context.read<AppRepository>().isUsernameAvailable(
        _usernameController.text,
      );

  String? get _passwordError {
    if (_passwordController.text.isEmpty) return null;
    if (_passwordController.text.length < 4) {
      return 'Minimum 4 caractères.';
    }
    if (_confirmController.text.isNotEmpty &&
        _passwordController.text != _confirmController.text) {
      return 'Les mots de passe ne correspondent pas.';
    }
    return null;
  }

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
      _usernameController.text.trim().isNotEmpty &&
      !_usernameTaken &&
      _schoolController.text.trim().isNotEmpty &&
      _fieldController.text.trim().isNotEmpty &&
      _yearController.text.trim().isNotEmpty &&
      _passwordController.text.length >= 4 &&
      _passwordController.text == _confirmController.text;

  Future<void> _submit(AppRepository repo) async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);
    await repo.signUp(
      name: _nameController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      school: _schoolController.text.trim(),
      field: _fieldController.text.trim(),
      year: _yearController.text.trim(),
      avatarColor: _avatarColor,
      photoPath: _photoPath,
    );
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const AuthHeader(subtitle: 'Rejoins la mémoire collective'),
                  const SizedBox(height: 20),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AvatarPicker(
                          photoPath: _photoPath,
                          avatarColor: _avatarColor,
                          initials: User.initialsFor(
                            _nameController.text.trim().isEmpty
                                ? '?'
                                : _nameController.text,
                          ),
                          onPhotoChanged: (path) =>
                              setState(() => _photoPath = path),
                          onColorChanged: (c) =>
                              setState(() => _avatarColor = c),
                        ),
                        const SizedBox(height: 18),
                        Text('Nom complet *', style: _labelStyle),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nameController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Ex : Léa Martin',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('Identifiant *', style: _labelStyle),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _usernameController,
                          onChanged: (_) {
                            _usernameEdited = true;
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            hintText: 'Ex : lea.martin',
                            errorText: _usernameTaken
                                ? 'Cet identifiant est déjà pris.'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('École *', style: _labelStyle),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _schoolController,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        Text('Filière *', style: _labelStyle),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _fieldController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Ex : Mastère IA & Big Data',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('Année *', style: _labelStyle),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _yearController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Ex : M1',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('Mot de passe *', style: _labelStyle),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        Text('Confirmer le mot de passe *', style: _labelStyle),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _confirmController,
                          obscureText: true,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(errorText: _passwordError),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _isValid && !_submitting
                              ? () => _submit(repo)
                              : null,
                          child: Text(
                            _submitting ? 'Création...' : 'Créer mon compte',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const _labelStyle = TextStyle(fontWeight: FontWeight.w600);
}
