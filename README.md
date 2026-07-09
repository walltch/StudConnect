# StudConnect — POC (Next.js 14 + Supabase + REST API)

La mémoire collective étudiante : forum d'entraide (à la StackOverflow) + fil
d'actualité social (à la Facebook), avec réputation, badges et threads imbriqués.

## Stack

- **Next.js 14** (App Router, Route Handlers pour l'API REST)
- **Supabase** (Postgres + Auth + Row Level Security) au lieu de MongoDB
- **TypeScript** + **Tailwind CSS**
- Aucun ORM : appels directs via `@supabase/supabase-js` / `@supabase/ssr`

## 1. Créer le projet Supabase

1. Va sur [supabase.com](https://supabase.com) → **New project**.
2. Une fois créé, ouvre **SQL Editor** → colle le contenu de
   [`supabase/schema.sql`](./supabase/schema.sql) → **Run**.
   Cela crée les tables (`profiles`, `posts`, `comments`, `post_upvotes`,
   `comment_upvotes`), les triggers de réputation automatique, et les
   policies RLS (chacun ne peut modifier que son propre contenu).
3. Dans **Project Settings → API**, récupère `Project URL` et `anon public key`.

> Optionnel (comme dans le cahier des charges) : active la vérification par email dans
> **Authentication → Providers → Email → Confirm email**, pour reproduire l'OTP académique.

## 2. Configurer le projet local

```bash
cp .env.local.example .env.local
# renseigne NEXT_PUBLIC_SUPABASE_URL et NEXT_PUBLIC_SUPABASE_ANON_KEY

npm install
npm run dev
```

Ouvre [http://localhost:3000](http://localhost:3000).

## 3. Parcours fonctionnels couverts

| Parcours | Pages | API REST |
|---|---|---|
| A — Inscription / Onboarding | `/login`, `/onboarding`, `/profile` | `GET/PUT /api/profile` |
| B — Demande d'aide (forum) | `/questions`, `/questions/create`, `/questions/[id]` | `GET/POST /api/posts`, `PUT/DELETE /api/posts/[id]` |
| C — Engagement (réseau social) | `/` (feed), threads imbriqués sur `/questions/[id]` | `POST /api/comments`, `PUT/DELETE /api/comments/[id]`, `POST /api/comments/[id]/upvote` |
| Gamification | anneau de réputation, badges, validation de solution | `POST /api/posts/[id]/upvote`, `POST /api/posts/[id]/accept` (déclenche les triggers SQL de réputation) |

## 4. CRUD — récapitulatif

- **Create** : inscription, création de question, réponse, sous-commentaire.
- **Read** : feed filtré, recherche plein texte, détail d'une question avec threads.
- **Update** : édition de question/réponse/profil, toggle upvote, validation de solution.
- **Delete** : suppression de question (cascade sur réponses/votes), suppression de réponse.

## 5. Design

Palette "campus électrique" (indigo `#5B4FE8`, corail `#FF6B4A`, menthe `#1FA97D`,
ambre `#F5A623`) sur fond pointillé clair, typographie Space Grotesk / Inter /
JetBrains Mono, cartes à ombre "pop" (offset 4px). Signature visuelle : l'anneau
de réputation animé autour de chaque avatar, dont la couleur change de palier
selon le score (indigo → menthe → corail → ambre).

## 6. Notes de déploiement

- Déployable tel quel sur **Vercel** (ajoute les 2 variables d'env dans les
  Project Settings).
- Le `middleware.ts` rafraîchit automatiquement la session Supabase à chaque requête.
- Pour aller plus loin sur le fil "à la Facebook" : brancher les
  **Supabase Realtime / Postgres Changes** sur les tables `comments` et
  `post_upvotes` pour des notifications live (mentionné dans le cahier des
  charges initial comme piste "RÉSEAU SOCIAL").
