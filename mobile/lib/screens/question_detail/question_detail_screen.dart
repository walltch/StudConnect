import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repository.dart';
import '../../models/answer.dart';
import '../../models/question.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_ago.dart';
import '../../widgets/questions/tag_pill.dart';
import '../../widgets/shared/user_avatar.dart';

/// US3 (voir les discussions) + US7 (répondre / indiquer qu'on ne peut
/// pas aider), contribue aussi à US4 (l'auteur peut marquer une réponse
/// comme solution, ce qui résout la question) et US6.
class QuestionDetailScreen extends StatefulWidget {
  const QuestionDetailScreen({super.key, required this.questionId});

  final String questionId;

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  final _answerController = TextEditingController();
  final _composerKey = GlobalKey();
  final _composerFocus = FocusNode();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppRepository>().markQuestionSeen(widget.questionId);
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    _composerFocus.dispose();
    super.dispose();
  }

  void _focusComposer() {
    final ctx = _composerKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
      );
    }
    _composerFocus.requestFocus();
  }

  Future<void> _submitAnswer(AppRepository repo) async {
    final content = _answerController.text.trim();
    if (content.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    await repo.addAnswer(widget.questionId, content);
    _answerController.clear();
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final question = repo.questionById(widget.questionId);

    if (question == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Question introuvable')),
      );
    }

    final isAuthor = question.authorId == repo.currentUser.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Question')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _QuestionHeader(
            question: question,
            onUpvote: () => repo.toggleQuestionUpvote(question.id),
          ),
          if (!isAuthor) ...[
            const SizedBox(height: 12),
            _ResponseActions(
              isDismissed: question.isDismissed,
              onWillAnswer: _focusComposer,
              onCantHelp: () => repo.toggleDismissal(question.id),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            '${question.answers.length} réponse${question.answers.length > 1 ? 's' : ''}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          for (final answer in question.answers) ...[
            _AnswerTile(
              answer: answer,
              canValidate: isAuthor && !answer.isValidated,
              onUpvote: () =>
                  repo.toggleAnswerUpvote(question.id, answer.id),
              onValidate: () =>
                  repo.validateAnswer(question.id, answer.id),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          _AnswerComposer(
            key: _composerKey,
            controller: _answerController,
            focusNode: _composerFocus,
            submitting: _submitting,
            onSubmit: () => _submitAnswer(repo),
          ),
        ],
      ),
    );
  }
}

class _QuestionHeader extends StatelessWidget {
  const _QuestionHeader({required this.question, required this.onUpvote});

  final Question question;
  final VoidCallback onUpvote;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              if (question.isSolved) const _SolvedPill(),
              TagPill(tag: question.tag),
            ],
          ),
          const SizedBox(height: 10),
          Hero(
            tag: 'question-title-${question.id}',
            child: Material(
              type: MaterialType.transparency,
              child: Text(
                question.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            question.content,
            style: TextStyle(color: AppColors.slate800, height: 1.4),
          ),
          const Divider(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                onTap: onUpvote,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.keyboard_arrow_up,
                        size: 20,
                        color: question.hasUpvoted
                            ? AppColors.brand600
                            : AppColors.slate600,
                      ),
                      Text(
                        '${question.upvotes}',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.visibility_outlined,
                size: 14,
                color: AppColors.slate600,
              ),
              const SizedBox(width: 4),
              Text(
                '${question.views} vues',
                style: TextStyle(color: AppColors.slate600, fontSize: 12),
              ),
              const Spacer(),
              UserAvatar(user: question.author, radius: 12),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${question.author.name} · ${question.author.school} · ${timeAgo(question.createdAt)}',
                  style: TextStyle(color: AppColors.slate600, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResponseActions extends StatelessWidget {
  const _ResponseActions({
    required this.isDismissed,
    required this.onWillAnswer,
    required this.onCantHelp,
  });

  final bool isDismissed;
  final VoidCallback onWillAnswer;
  final VoidCallback onCantHelp;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onWillAnswer,
            icon: const Icon(Icons.chat_bubble_outline, size: 16),
            label: const Text('Je réponds'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCantHelp,
            icon: Icon(
              isDismissed ? Icons.undo : Icons.block,
              size: 16,
            ),
            label: Text(
              isDismissed ? 'Annuler' : 'Je ne peux pas aider',
            ),
          ),
        ),
      ],
    );
  }
}

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.answer,
    required this.canValidate,
    required this.onUpvote,
    required this.onValidate,
  });

  final Answer answer;
  final bool canValidate;
  final VoidCallback onUpvote;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface0,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (answer.isValidated)
            Container(width: 4, decoration: const BoxDecoration(
              color: Color(0xFF10B981),
            )),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (answer.isValidated) ...[
                    const _ValidatedBadge(),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    answer.content,
                    style: const TextStyle(height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      InkWell(
                        onTap: onUpvote,
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.keyboard_arrow_up,
                              size: 18,
                              color: answer.hasUpvoted
                                  ? AppColors.brand600
                                  : AppColors.slate600,
                            ),
                            Text('${answer.upvotes}'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      UserAvatar(user: answer.author, radius: 10),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${answer.author.name} · ${timeAgo(answer.createdAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.slate600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${answer.author.reputation} pts',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate600,
                        ),
                      ),
                    ],
                  ),
                  if (canValidate) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onValidate,
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Marquer comme solution'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerComposer extends StatelessWidget {
  const _AnswerComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.submitting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Partager mon retour d\'expérience',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Ton REX peut débloquer quelqu\'un rapidement.',
            style: TextStyle(fontSize: 12, color: AppColors.slate600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            focusNode: focusNode,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Décris ta réponse ici...',
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: submitting ? null : onSubmit,
              icon: const Icon(Icons.send, size: 16),
              label: Text(submitting ? 'Envoi...' : 'Publier ma réponse'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SolvedPill extends StatelessWidget {
  const _SolvedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Résolu',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF047857),
        ),
      ),
    );
  }
}

class _ValidatedBadge extends StatelessWidget {
  const _ValidatedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 12, color: Color(0xFF047857)),
          SizedBox(width: 4),
          Text(
            'Solution validée',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF047857),
            ),
          ),
        ],
      ),
    );
  }
}
