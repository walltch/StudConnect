import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/shared/avatar_color_picker.dart';

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
  final _schoolController = TextEditingController(text: 'ESGI Bordeaux');
  final _fieldController = TextEditingController();
  final _yearController = TextEditingController();
  int _avatarColor = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _avatarColor = AppColors.avatarPalette.first.toARGB32();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    _fieldController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
      _schoolController.text.trim().isNotEmpty &&
      _fieldController.text.trim().isNotEmpty &&
      _yearController.text.trim().isNotEmpty;

  Future<void> _submit(AppRepository repo) async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);
    await repo.signUp(
      name: _nameController.text.trim(),
      school: _schoolController.text.trim(),
      field: _fieldController.text.trim(),
      year: _yearController.text.trim(),
      avatarColor: _avatarColor,
    );
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text('Ton avatar', style: _labelStyle),
          const SizedBox(height: 8),
          AvatarColorPicker(
            selected: _avatarColor,
            onChanged: (c) => setState(() => _avatarColor = c),
          ),
          const SizedBox(height: 18),
          Text('Nom complet *', style: _labelStyle),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Ex : Léa Martin'),
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
            decoration: const InputDecoration(hintText: 'Ex : M1'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isValid && !_submitting
                  ? () => _submit(repo)
                  : null,
              child: Text(_submitting ? 'Création...' : 'Créer mon compte'),
            ),
          ),
        ],
      ),
    );
  }

  static const _labelStyle = TextStyle(fontWeight: FontWeight.w600);
}
