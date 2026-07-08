import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repository.dart';
import '../../models/tag.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/questions/question_card.dart';
import '../../widgets/questions/tag_pill.dart';

/// Home feed (US6: voir/parcourir les demandes des autres). Unlike the
/// web prototype, the sort pills and tag filter row are real and
/// actually filter [AppRepository.sortedAndFiltered], and the stat tiles
/// are computed live instead of hardcoded strings.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  SortMode _sort = SortMode.recent;
  Tag? _tagFilter;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final list = repo.sortedAndFiltered(_sort, tag: _tagFilter);

    return Scaffold(
      appBar: AppBar(title: const Text('StudConnect')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _HeroBanner(onAsk: () => context.push('/questions/new')),
          const SizedBox(height: 16),
          _StatsRow(repo: repo),
          const SizedBox(height: 16),
          _SortBar(
            sort: _sort,
            onChanged: (mode) => setState(() => _sort = mode),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: Tag.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final tag = Tag.values[i];
                final selected = _tagFilter == tag;
                return TagPill(
                  tag: tag,
                  selected: selected,
                  onTap: () => setState(() {
                    _tagFilter = selected ? null : tag;
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${list.length} question${list.length > 1 ? 's' : ''}',
            style: TextStyle(
              color: AppColors.slate600,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          if (list.isEmpty)
            const _EmptyFeed()
          else
            for (final q in list) ...[
              QuestionCard(
                question: q,
                onTap: () => context.push('/questions/${q.id}'),
                onUpvote: () => repo.toggleQuestionUpvote(q.id),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onAsk});

  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'La mémoire collective étudiante',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bienvenue sur StudConnect 👋',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Pose ta question et reçois des réponses d'étudiants qui "
            "étaient à ta place il y a 6 mois.",
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onAsk,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.brand700,
            ),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('Poser une question'),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.repo});

  final AppRepository repo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: '${repo.questionsCount}',
            label: 'Questions posées',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: '${repo.answersCount}',
            label: 'Réponses partagées',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: '${repo.resolvedPercent}%',
            label: 'Questions résolues',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.brand700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: AppColors.slate600),
          ),
        ],
      ),
    );
  }
}

class _SortBar extends StatelessWidget {
  const _SortBar({required this.sort, required this.onChanged});

  final SortMode sort;
  final ValueChanged<SortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget pill(SortMode mode, String label, IconData icon) {
      final selected = sort == mode;
      return ChoiceChip(
        selected: selected,
        onSelected: (_) => onChanged(mode),
        avatar: Icon(
          icon,
          size: 16,
          color: selected ? Colors.white : AppColors.slate600,
        ),
        label: Text(label),
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.slate800,
          fontSize: 12,
        ),
        selectedColor: AppColors.brand600,
        backgroundColor: AppColors.surface2,
      );
    }

    return Wrap(
      spacing: 8,
      children: [
        pill(SortMode.recent, 'Récentes', Icons.schedule),
        pill(SortMode.popular, 'Populaires', Icons.local_fire_department),
        pill(SortMode.unsolved, 'Non résolues', Icons.check_circle_outline),
      ],
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          'Aucune question pour ce filtre.',
          style: TextStyle(color: AppColors.slate600),
        ),
      ),
    );
  }
}
