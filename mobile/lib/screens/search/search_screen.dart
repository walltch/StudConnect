import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repository.dart';
import '../../models/tag.dart';
import '../../theme/app_colors.dart';
import '../../widgets/questions/question_card.dart';
import '../../widgets/questions/tag_pill.dart';

/// US6 (parcourir/trouver les demandes des autres). Même logique de
/// correspondance que le site web : sous-chaîne insensible à la casse
/// sur titre/contenu/tag (AppRepository.search).
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Tag? _tagFilter;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final results = repo.search(_controller.text, tag: _tagFilter);

    return Scaffold(
      appBar: AppBar(title: const Text('Recherche')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          TextField(
            controller: _controller,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Rechercher une question...',
              prefixIcon: Icon(Icons.search),
            ),
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
            '${results.length} résultat${results.length > 1 ? 's' : ''}',
            style: TextStyle(
              color: AppColors.slate600,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          if (results.isEmpty)
            _EmptyResults(query: _controller.text)
          else
            for (final q in results) ...[
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

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 32, color: AppColors.slate600),
          const SizedBox(height: 8),
          Text(
            'Aucun résultat',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.slate800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            query.trim().isEmpty
                ? 'Essaie un autre filtre de matière.'
                : 'Essaie un autre mot-clé ou un autre filtre.',
            style: TextStyle(fontSize: 12, color: AppColors.slate600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
