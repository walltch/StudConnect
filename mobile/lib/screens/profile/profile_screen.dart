import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repository.dart';
import '../../models/question.dart';
import '../../models/user.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/questions/question_card.dart';
import '../../widgets/shared/avatar_color_picker.dart';
import '../../widgets/shared/user_avatar.dart';

enum _ProfileTab { questions, answers }

/// US2 (renseigner infos profil), US5 (modifier infos profil), US4
/// (modifier/supprimer mes questions — point d'entrée), US8 (voir mes
/// demandes en cours + savoir s'il y a eu des interactions).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  _ProfileTab _tab = _ProfileTab.questions;

  Future<void> _editProfile(AppRepository repo) async {
    final user = repo.currentUser;
    final nameController = TextEditingController(text: user.name);
    final fieldController = TextEditingController(text: user.field);
    final yearController = TextEditingController(text: user.year);
    final schoolController = TextEditingController(text: user.school);
    var avatarColor = user.avatarColor;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modifier mon profil',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              AvatarColorPicker(
                selected: avatarColor,
                onChanged: (c) => setModalState(() => avatarColor = c),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: fieldController,
                decoration: const InputDecoration(labelText: 'Filière'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: yearController,
                decoration: const InputDecoration(labelText: 'Année'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: schoolController,
                decoration: const InputDecoration(labelText: 'École'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (saved == true) {
      await repo.updateProfile(
        name: nameController.text.trim(),
        field: fieldController.text.trim(),
        year: yearController.text.trim(),
        school: schoolController.text.trim(),
        avatarColor: avatarColor,
      );
    }
  }

  Future<void> _addSkill(AppRepository repo) async {
    final controller = TextEditingController();
    final skill = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter une compétence'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    if (skill != null && skill.trim().isNotEmpty) {
      await repo.addSkill(skill.trim());
    }
  }

  Future<void> _confirmDelete(AppRepository repo, Question question) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette question ?'),
        content: Text(question.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await repo.deleteQuestion(question.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final user = repo.currentUserOrNull;
    if (user == null) {
      // Briefly true between repo.logOut() notifying listeners and the
      // router's redirect actually navigating away from this screen.
      return const Scaffold(body: SizedBox.shrink());
    }
    final myQuestions = repo.myQuestions;
    final myAnswered = repo.myAnsweredQuestions;
    final list = _tab == _ProfileTab.questions ? myQuestions : myAnswered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            onPressed: () => repo.logOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _ProfileHeader(user: user, onEdit: () => _editProfile(repo)),
          const SizedBox(height: 16),
          _SkillsSection(
            user: user,
            onAddSkill: () => _addSkill(repo),
            onRemoveSkill: (s) => repo.removeSkill(s),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _TabButton(
                label: 'Mes questions (${myQuestions.length})',
                selected: _tab == _ProfileTab.questions,
                onTap: () => setState(() => _tab = _ProfileTab.questions),
              ),
              const SizedBox(width: 20),
              _TabButton(
                label: 'Mes réponses (${myAnswered.length})',
                selected: _tab == _ProfileTab.answers,
                onTap: () => setState(() => _tab = _ProfileTab.answers),
              ),
            ],
          ),
          const Divider(height: 24),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  _tab == _ProfileTab.questions
                      ? "Tu n'as pas encore posé de question."
                      : "Tu n'as pas encore répondu à une question.",
                  style: TextStyle(color: AppColors.slate600),
                ),
              ),
            )
          else
            for (final q in list) ...[
              QuestionCard(
                question: q,
                onTap: () => context.push('/questions/${q.id}'),
                onUpvote: () => repo.toggleQuestionUpvote(q.id),
              ),
              if (_tab == _ProfileTab.questions)
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: () =>
                            context.push('/questions/new?questionId=${q.id}'),
                        icon: const Icon(Icons.edit_outlined, size: 14),
                        label: const Text('Modifier'),
                      ),
                      TextButton.icon(
                        onPressed: () => _confirmDelete(repo, q),
                        icon: const Icon(Icons.delete_outline, size: 14),
                        label: const Text('Supprimer'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.onEdit});

  final User user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(user: user, radius: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 14,
                          color: AppColors.slate600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${user.year} · ${user.field} · ${user.school}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.slate600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Modifier',
              ),
            ],
          ),
          const Divider(height: 28),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.star_outline,
                  value: '${user.reputation}',
                  label: 'Points',
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.chat_bubble_outline,
                  value: '${user.answersCount}',
                  label: 'Réponses',
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.help_outline,
                  value: '${user.questionsCount}',
                  label: 'Questions',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppColors.brand600),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.slate600),
        ),
      ],
    );
  }
}

class _SkillsSection extends StatelessWidget {
  const _SkillsSection({
    required this.user,
    required this.onAddSkill,
    required this.onRemoveSkill,
  });

  final User user;
  final VoidCallback onAddSkill;
  final ValueChanged<String> onRemoveSkill;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COMPÉTENCES', style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.slate600,
          )),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final skill in user.skills)
                Chip(
                  label: Text(skill),
                  onDeleted: () => onRemoveSkill(skill),
                  deleteIconColor: AppColors.slate600,
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: const Text('Ajouter'),
                onPressed: onAddSkill,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.brand600 : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.brand700 : AppColors.slate600,
          ),
        ),
      ),
    );
  }
}
