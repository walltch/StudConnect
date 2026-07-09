import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repository.dart';
import '../../models/tag.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/questions/tag_pill.dart';

/// US1 (créer une demande) et US4 (modifier une question existante,
/// via [questionId]). Contrairement au formulaire web (jamais branché
/// à une vraie action), la soumission ici persiste réellement.
class NewQuestionScreen extends StatefulWidget {
  const NewQuestionScreen({super.key, this.questionId});

  /// Si renseigné, l'écran édite cette question existante au lieu
  /// d'en créer une nouvelle.
  final String? questionId;

  @override
  State<NewQuestionScreen> createState() => _NewQuestionScreenState();
}

class _NewQuestionScreenState extends State<NewQuestionScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  Tag? _tag;
  bool _prefilled = false;
  bool _submitting = false;

  bool get isEdit => widget.questionId != null;

  bool get _isValid =>
      _titleController.text.trim().isNotEmpty &&
      _contentController.text.trim().isNotEmpty &&
      _tag != null;

  void _prefillIfNeeded(AppRepository repo) {
    if (_prefilled || !isEdit) return;
    _prefilled = true;
    final existing = repo.questionById(widget.questionId!);
    if (existing == null) return;
    _titleController.text = existing.title;
    _contentController.text = existing.content;
    _tag = existing.tag;
  }

  Future<void> _submit(AppRepository repo) async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);

    if (isEdit) {
      final existing = repo.questionById(widget.questionId!)!;
      await repo.updateQuestion(
        existing.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          tag: _tag,
        ),
      );
    } else {
      await repo.createQuestion(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        tag: _tag!,
      );
    }

    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    _prefillIfNeeded(repo);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier ma question' : 'Poser une question'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            'Sois précis dans ton contexte — mentionne ta formation, ton '
            'année et ce que tu as déjà essayé.',
            style: TextStyle(color: AppColors.slate600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (!isEdit) ...[
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: Color(0xFFB45309),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Avant de poster',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Cherche si ta question a déjà été résolue. Une '
                          'réponse existante peut te faire gagner des heures.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.slate600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text('Titre de ta question *', style: _labelStyle),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            maxLength: 150,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText:
                  'Ex : Comment organiser un projet de groupe avec Git '
                  'quand on débute ?',
            ),
          ),
          const SizedBox(height: 12),
          Text('Matière / Catégorie *', style: _labelStyle),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Tag.values
                .map(
                  (tag) => TagPill(
                    tag: tag,
                    selected: _tag == tag,
                    onTap: () => setState(() => _tag = tag),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          Text('Décris ton problème *', style: _labelStyle),
          const SizedBox(height: 6),
          TextField(
            controller: _contentController,
            minLines: 6,
            maxLines: 12,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText:
                  'Explique ton contexte (formation, année, outils '
                  'utilisés), ce que tu as déjà essayé, et ce que tu '
                  'cherches exactement...',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les champs * sont obligatoires',
            style: TextStyle(fontSize: 11, color: AppColors.slate600),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isValid && !_submitting
                  ? () => _submit(repo)
                  : null,
              child: Text(
                _submitting
                    ? 'Envoi...'
                    : (isEdit ? 'Enregistrer' : 'Publier ma question'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _labelStyle = TextStyle(fontWeight: FontWeight.w600);
}
