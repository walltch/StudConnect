import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/answer.dart';
import '../models/question.dart';
import '../models/tag.dart';
import '../models/user.dart';

/// Mirrors src/lib/mock-data.ts from the web app: same 4 base users, same
/// 4 base questions (q1-q4) with the same denormalized answers (a1-a4),
/// plus 3 teammates (Anis, Samy, Charles) added as a nod to the group
/// working on this project. All of them are real local accounts you can
/// log into from the welcome screen — none is hardcoded as "the" user
/// anymore (see AppRepository.logIn/signUp).
class SeedData {
  SeedData._();

  /// Same demo password for every seed account (`"password"`), documented
  /// on the login screen — this is a local-only account system, not a
  /// secured multi-device one.
  static String _hash(String raw) => sha256.convert(utf8.encode(raw)).toString();
  static final String demoPasswordHash = _hash('password');

  static final alice = User(
    id: 'alice',
    name: 'Alice Moreau',
    avatar: 'AM',
    avatarColor: 0xFF7C3AED, // violet
    school: 'ESGI Bordeaux',
    field: 'Mastère IA & Big Data',
    year: 'M2',
    skills: const ['Python', 'Machine Learning', 'React', 'Docker'],
    reputation: 1240,
    answersCount: 47,
    questionsCount: 12,
    joinedAt: DateTime.parse('2024-09-01'),
    username: 'alice',
    passwordHash: demoPasswordHash,
  );

  static final bob = User(
    id: 'bob',
    name: 'Bob Lefevre',
    avatar: 'BL',
    avatarColor: 0xFF0891B2, // cyan
    school: 'ESGI Paris',
    field: 'Bachelor Développement Web',
    year: 'B2',
    skills: const ['HTML/CSS', 'JavaScript', 'Git'],
    reputation: 340,
    answersCount: 8,
    questionsCount: 23,
    joinedAt: DateTime.parse('2025-09-15'),
    username: 'bob',
    passwordHash: demoPasswordHash,
  );

  static final clara = User(
    id: 'clara',
    name: 'Clara Dupuis',
    avatar: 'CD',
    avatarColor: 0xFF10B981, // emerald
    school: 'Université Lyon 2',
    field: 'Mastère Data Science',
    year: 'M1',
    skills: const ['R', 'Python', 'SQL', 'Tableau'],
    reputation: 870,
    answersCount: 31,
    questionsCount: 9,
    joinedAt: DateTime.parse('2024-09-01'),
    username: 'clara',
    passwordHash: demoPasswordHash,
  );

  static final wall = User(
    id: 'wall',
    name: 'Wall Fatah T.',
    avatar: 'WF',
    avatarColor: 0xFF4F46E5, // brand
    school: 'ESGI Bordeaux',
    field: 'Mastère IA & Big Data',
    year: 'M1',
    skills: const ['Python', 'Next.js', 'RAG', 'NLP'],
    reputation: 520,
    answersCount: 18,
    questionsCount: 6,
    joinedAt: DateTime.parse('2025-12-20'),
    username: 'wall',
    passwordHash: demoPasswordHash,
  );

  static final anis = User(
    id: 'anis',
    name: 'Anis Boix',
    avatar: 'AB',
    avatarColor: 0xFFD97706, // amber
    school: 'ESGI Bordeaux',
    field: 'Mastère Cybersécurité',
    year: 'M1',
    skills: const ['Réseaux', 'Pentest', 'Linux'],
    reputation: 410,
    answersCount: 6,
    questionsCount: 1,
    joinedAt: DateTime.parse('2025-09-08'),
    username: 'anis',
    passwordHash: demoPasswordHash,
  );

  static final samy = User(
    id: 'samy',
    name: 'Samy Berrari',
    avatar: 'SB',
    avatarColor: 0xFF0F766E, // teal
    school: 'ESGI Bordeaux',
    field: 'Bachelor DevOps & Cloud',
    year: 'B3',
    skills: const ['Docker', 'Kubernetes', 'CI/CD'],
    reputation: 265,
    answersCount: 4,
    questionsCount: 2,
    joinedAt: DateTime.parse('2025-09-08'),
    username: 'samy',
    passwordHash: demoPasswordHash,
  );

  static final charles = User(
    id: 'charles',
    name: 'Charles Keita',
    avatar: 'CK',
    avatarColor: 0xFFE11D48, // rose
    school: 'ESGI Bordeaux',
    field: 'Mastère Ingénierie Informatique',
    year: 'M1',
    skills: const ['Rust', 'PowerShell', 'DevOps', 'Réseaux'],
    reputation: 380,
    answersCount: 5,
    questionsCount: 0,
    joinedAt: DateTime.parse('2025-09-08'),
    username: 'charles',
    passwordHash: demoPasswordHash,
  );

  static List<User> get users => [alice, bob, clara, wall, anis, samy, charles];

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
        Answer(
          id: 'a6',
          questionId: 'q2',
          authorId: charles.id,
          author: charles,
          content:
              "Pareil en stage : j'ai fini par lui envoyer un mini cahier des "
              "charges que je rédigeais moi-même à partir de ses phrases "
              "vagues, en lui demandant juste de valider par 'ok' ou 'non'. "
              "Ça prend 5 min à son niveau à lui, et toi t'as un vrai cadre "
              "écrit à montrer si jamais ça part en confusion plus tard.",
          upvotes: 9,
          isValidated: false,
          createdAt: DateTime.parse('2026-01-16T10:20:00Z'),
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
      [
        Answer(
          id: 'a5',
          questionId: 'q4',
          authorId: samy.id,
          author: samy,
          content:
              "Chez nous c'était 30-40 pages hors annexes. Pas de code brut "
              "dans le corps du rapport (mets-le en annexe ou en lien GitHub), "
              "le jury veut lire ton raisonnement pas ton code. Structure qui "
              "a bien marché : contexte entreprise (court) → problématique → "
              "missions/méthode → résultats → bilan personnel.",
          upvotes: 6,
          isValidated: false,
          createdAt: DateTime.parse('2026-03-10T13:10:00Z'),
          hasUpvoted: false,
        ),
      ],
    ),
    (
      Question(
        id: 'q5',
        title:
            'Authentification par email universitaire : OTP ou lien magique, lequel implémenter en premier ?',
        content:
            "Pour un projet d'entraide étudiante, on doit restreindre "
            "l'inscription aux emails de l'école. Entre un code OTP envoyé "
            "par email et un lien magique cliquable, lequel est le plus "
            "simple et sûr à mettre en place pour un projet de cours (pas de "
            "vrai budget infra) ?",
        authorId: anis.id,
        author: anis,
        tag: Tag.informatique,
        answers: const [],
        upvotes: 12,
        hasUpvoted: false,
        isSolved: false,
        views: 87,
        createdAt: DateTime.parse('2026-06-30T09:30:00Z'),
      ),
      [],
    ),
  ];
}
