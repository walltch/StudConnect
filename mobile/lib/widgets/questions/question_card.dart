import 'package:flutter/material.dart';

import '../../models/question.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_ago.dart';
import 'tag_pill.dart';

/// Reused identically on Feed, Profile (both tabs) and Search — mirrors
/// the web's QuestionCard.tsx.
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.question,
    required this.onTap,
    required this.onUpvote,
  });

  final Question question;
  final VoidCallback onTap;
  final VoidCallback onUpvote;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VoteColumn(
            upvotes: question.upvotes,
            hasUpvoted: question.hasUpvoted,
            onTap: onUpvote,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (question.isSolved)
                      const _SolvedBadge()
                    else if (question.hasNewActivitySince)
                      const _NewActivityBadge(),
                    TagPill(tag: question.tag),
                  ],
                ),
                const SizedBox(height: 6),
                Hero(
                  tag: 'question-title-${question.id}',
                  child: Material(
                    type: MaterialType.transparency,
                    child: Text(
                      question.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  question.content,
                  style: TextStyle(color: AppColors.slate600, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 14,
                      color: AppColors.slate600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${question.answers.length} réponse${question.answers.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: AppColors.slate600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Icon(
                      Icons.visibility_outlined,
                      size: 14,
                      color: AppColors.slate600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${question.views}',
                      style: TextStyle(
                        color: AppColors.slate600,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: AppColors.brand100,
                      child: Text(
                        question.author.avatar,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brand700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${question.author.name} · ${question.author.year} · ${timeAgo(question.createdAt)}',
                        style: TextStyle(
                          color: AppColors.slate600,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoteColumn extends StatelessWidget {
  const _VoteColumn({
    required this.upvotes,
    required this.hasUpvoted,
    required this.onTap,
  });

  final int upvotes;
  final bool hasUpvoted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = hasUpvoted ? AppColors.brand600 : AppColors.slate600;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(Icons.keyboard_arrow_up, size: 20, color: color),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: Text(
            '$upvotes',
            key: ValueKey(upvotes),
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
        ),
      ],
    );
  }
}

class _SolvedBadge extends StatelessWidget {
  const _SolvedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.check_circle, size: 12, color: Color(0xFF047857)),
          SizedBox(width: 4),
          Text(
            'Résolu',
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

class _NewActivityBadge extends StatelessWidget {
  const _NewActivityBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.brand100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Nouveau',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.brand700,
        ),
      ),
    );
  }
}
