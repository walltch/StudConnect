import '../models/answer.dart';
import '../models/question.dart';
import '../models/tag.dart';
import '../models/user.dart';

/// Mirrors src/lib/mock-data.ts from the web app: same 4 users, same 4
/// questions (q1-q4) with the same denormalized answers (a1-a4). `wall`
/// is the current/logged-in user on both clients.
class SeedData {
  SeedData._();

  static const currentUserId = 'wall';

  static final alice = User(
    id: 'alice',
    name: 'Alice Moreau',
    avatar: 'AM',
    school: 'ESGI Bordeaux',
    field: 'Mastère IA & Big Data',
    year: 'M2',
    skills: const ['Python', 'Machine Learning', 'React', 'Docker'],
    reputation: 1240,
    answersCount: 47,
    questionsCount: 12,
    joinedAt: DateTime.parse('2024-09-01'),
  );

  static final bob = User(
    id: 'bob',
    name: 'Bob Lefevre',
    avatar: 'BL',
    school: 'ESGI Paris',
    field: 'Bachelor Développement Web',
    year: 'B2',
    skills: const ['HTML/CSS', 'JavaScript', 'Git'],
    reputation: 340,
    answersCount: 8,
    questionsCount: 23,
    joinedAt: DateTime.parse('2025-09-15'),
  );

  static final clara = User(
    id: 'clara',
    name: 'Clara Dupuis',
    avatar: 'CD',
    school: 'Université Lyon 2',
    field: 'Mastère Data Science',
    year: 'M1',
    skills: const ['R', 'Python', 'SQL', 'Tableau'],
    reputation: 870,
    answersCount: 31,
    questionsCount: 9,
    joinedAt: DateTime.parse('2024-09-01'),
  );

  static final wall = User(
    id: 'wall',
    name: 'Wall Fatah T.',
    avatar: 'WF',
    school: 'ESGI Bordeaux',
    field: 'Mastère IA & Big Data',
    year: 'M1',
    skills: const ['Python', 'Next.js', 'RAG', 'NLP'],
    reputation: 520,
    answersCount: 18,
    questionsCount: 6,
    joinedAt: DateTime.parse('2025-12-20'),
  );

  static List<User> get users => [alice, bob, clara, wall];

  /// Each entry pairs a seed Question with its seed Answers (the join is
  /// done here, once, instead of scattering FK wiring across the file).
  static List<(Question, List<Answer>)> get questionsWithAnswers => [
    (
      Question(
        id: 'q1',
        title: 'Comment organiser un projet de groupe avec Git quand on débute ?',
        content:
            "On est 4 dans le groupe et personne ne maîtrise vraiment Git. "
            "On a eu plusieurs conflits de merge qui nous ont bloqués pendant "
            "des heures. Vous avez des conseils pour un workflow simple qui "
            "marche pour des débutants ? On a 3 semaines pour rendre le projet.",
        authorId: bob.id,
        author: bob,
        tag: Tag.gestionDeProjet,
        answers: const [],
        upvotes: 34,
        hasUpvoted: false,
        isSolved: true,
        views: 412,
        createdAt: DateTime.parse('2025-11-03T10:00:00Z'),
      ),
      [
        Answer(
          id: 'a1',
          questionId: 'q1',
          authorId: alice.id,
          author: alice,
          content:
              "J'ai eu exactement le même projet en B2. La règle d'or : une "
              "branche par personne, on ne touche JAMAIS à `main` directement.\n\n"
              "Voici le workflow qu'on a utilisé :\n\n"
              "1. `main` = version stable, personne ne push dessus directement\n"
              "2. Chaque personne crée sa branche : `feature/prenom-fonctionnalite`\n"
              "3. Pour intégrer, on fait une Pull Request et **quelqu'un d'autre** la review\n\n"
              "Ça prend 10 min à mettre en place et ça évite 90% des conflits. "
              "Le truc qui nous a sauvés : on faisait un `git pull origin main` "
              "chaque matin avant de commencer à coder.",
          upvotes: 28,
          isValidated: true,
          createdAt: DateTime.parse('2025-11-03T14:30:00Z'),
          hasUpvoted: false,
        ),
        Answer(
          id: 'a2',
          questionId: 'q1',
          authorId: clara.id,
          author: clara,
          content:
              "Ajout à la réponse d'Alice : installez l'extension GitLens sur "
              "VSCode. Elle visualise qui a modifié quoi et ça rend les "
              "conflits beaucoup moins stressants. Aussi, faites des commits "
              "petits et fréquents, pas un gros commit à la fin de la journée.",
          upvotes: 14,
          isValidated: false,
          createdAt: DateTime.parse('2025-11-04T09:15:00Z'),
          hasUpvoted: false,
        ),
      ],
    ),
    (
      Question(
        id: 'q2',
        title:
            'Alternance : comment gérer quand le tuteur ne donne pas de missions claires ?',
        content:
            "Je suis en première année de mastère en alternance depuis 2 mois. "
            "Mon tuteur me donne des missions très vagues du genre 'fais "
            "quelque chose avec l'IA pour nous'. Je me retrouve à improviser "
            "sans savoir si ce que je fais correspond à ce qu'on attend.",
        authorId: wall.id,
        author: wall,
        tag: Tag.stageAlternance,
        answers: const [],
        upvotes: 52,
        hasUpvoted: true,
        isSolved: false,
        views: 678,
        createdAt: DateTime.parse('2026-01-15T08:30:00Z'),
      ),
      [
        Answer(
          id: 'a3',
          questionId: 'q2',
          authorId: alice.id,
          author: alice,
          content:
              "Propose-lui un point hebdo de 15 min avec un compte-rendu écrit "
              "de ce que tu as fait + ce que tu comptes faire ensuite. Ça "
              "l'oblige à réagir et à cadrer, même s'il n'a pas le temps de "
              "préparer des missions détaillées en amont.",
          upvotes: 41,
          isValidated: false,
          createdAt: DateTime.parse('2026-01-15T11:00:00Z'),
          hasUpvoted: false,
        ),
      ],
    ),
    (
      Question(
        id: 'q3',
        title:
            'Différence entre Random Forest et XGBoost — lequel choisir pour un projet ML ?',
        content:
            "Dans le cadre d'un projet de classification, j'hésite entre "
            "Random Forest et XGBoost. Mon dataset a environ 50k lignes et 30 "
            "features. Quels sont les critères pour choisir l'un ou l'autre ? "
            "Et est-ce que l'un est plus facile à expliquer pour un rapport ?",
        authorId: wall.id,
        author: wall,
        tag: Tag.iaMl,
        answers: const [],
        upvotes: 67,
        hasUpvoted: false,
        isSolved: true,
        views: 923,
        createdAt: DateTime.parse('2026-02-20T14:00:00Z'),
      ),
      [
        Answer(
          id: 'a4',
          questionId: 'q3',
          authorId: clara.id,
          author: clara,
          content:
              "**Random Forest** : plus simple à expliquer (moyenne d'arbres "
              "indépendants), moins sensible au sur-apprentissage, bon défaut "
              "solide.\n\n**XGBoost** : généralement plus performant sur ce "
              "genre de volume, mais plus de hyperparamètres à régler et plus "
              "dur à justifier simplement dans un rapport.\n\nPour 50k lignes/30 "
              "features je partirais sur Random Forest d'abord comme baseline, "
              "puis XGBoost si tu as le temps de tuner et que tu dois "
              "maximiser la perf.",
          upvotes: 55,
          isValidated: true,
          createdAt: DateTime.parse('2026-02-20T16:45:00Z'),
          hasUpvoted: false,
        ),
      ],
    ),
    (
      Question(
        id: 'q4',
        title:
            'Comment structurer mon rapport de stage de M1 — quelle longueur attendue ?',
        content:
            "Mon école demande un rapport de stage mais les consignes sont "
            "très floues. Combien de pages généralement pour un rapport de "
            "M1 ? Est-ce qu'il faut inclure du code ? Comment équilibrer la "
            "partie entreprise et la partie missions ?",
        authorId: bob.id,
        author: bob,
        tag: Tag.stageAlternance,
        answers: const [],
        upvotes: 29,
        hasUpvoted: false,
        isSolved: false,
        views: 344,
        createdAt: DateTime.parse('2026-03-10T09:00:00Z'),
      ),
      [],
    ),
  ];
}
