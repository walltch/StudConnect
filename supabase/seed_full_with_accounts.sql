-- ============================================================
-- StudConnect — Seed complet et autonome
-- Crée directement 2 comptes (Alice + Bob) SANS passer par l'inscription
-- de l'app, puis alimente plusieurs fils de discussion.
--
-- Pré-requis : l'OTP / confirmation email doit être désactivé
-- (Authentication → Providers → Email → décoche "Confirm email"),
-- ce que tu as déjà fait.
--
-- Comptes créés :
--   alice.martin@universite.fr / Password123!
--   bob.dupont@universite.fr   / Password123!
--
-- Le script est rejouable sans risque (ON CONFLICT DO NOTHING).
-- ============================================================

create extension if not exists pgcrypto;

do $$
declare
  v_alice uuid := 'a1111111-1111-1111-1111-111111111111';
  v_bob   uuid := 'b2222222-2222-2222-2222-222222222222';
  v_post  uuid;
  v_c1    uuid;
  v_c2    uuid;
  v_c3    uuid;
begin
  -- --------------------------------------------------------
  -- 1. Comptes auth.users (mot de passe : Password123!)
  -- --------------------------------------------------------
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change
  ) values
    ('00000000-0000-0000-0000-000000000000', v_alice, 'authenticated', 'authenticated',
     'alice.martin@universite.fr', crypt('Password123!', gen_salt('bf')), now(),
     '{"provider":"email","providers":["email"]}', '{"full_name":"Alice Martin"}',
     now(), now(), '', '', '', ''),
    ('00000000-0000-0000-0000-000000000000', v_bob, 'authenticated', 'authenticated',
     'bob.dupont@universite.fr', crypt('Password123!', gen_salt('bf')), now(),
     '{"provider":"email","providers":["email"]}', '{"full_name":"Bob Dupont"}',
     now(), now(), '', '', '', '')
  on conflict (id) do nothing;

  insert into auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
  values
    (gen_random_uuid(), v_alice,
     jsonb_build_object('sub', v_alice::text, 'email', 'alice.martin@universite.fr'),
     'email', v_alice::text, now(), now(), now()),
    (gen_random_uuid(), v_bob,
     jsonb_build_object('sub', v_bob::text, 'email', 'bob.dupont@universite.fr'),
     'email', v_bob::text, now(), now(), now())
  on conflict do nothing;

  -- Le trigger on_auth_user_created crée normalement le profil tout seul.
  -- On complète/écrase quand même les infos d'onboarding par sécurité :
  insert into public.profiles (id, email, full_name, institution, filiere, annee_etude, skills)
  values
    (v_alice, 'alice.martin@universite.fr', 'Alice Martin', 'Université Paris-Saclay',
     'Informatique — Génie Logiciel', 'M1', array['Next.js','MongoDB','Supabase','TypeScript','Architecture']),
    (v_bob, 'bob.dupont@universite.fr', 'Bob Dupont', 'Université Paris-Saclay',
     'Informatique', 'L3', array['Algorithmique','SQL','React'])
  on conflict (id) do update set
    full_name = excluded.full_name,
    institution = excluded.institution,
    filiere = excluded.filiere,
    annee_etude = excluded.annee_etude,
    skills = excluded.skills;

  -- ==========================================================
  -- FIL 1 — Bob demande, Alice répond, solution validée, Bob relance
  -- ==========================================================
  insert into public.posts (title, content, author_id, tags)
  values (
    'Comment gérer les Server Actions avec un formulaire imbriqué ?',
    E'Je galère avec un formulaire qui contient un sous-formulaire dynamique (ajout de lignes). Dès que je soumets, la Server Action ne reçoit que le premier champ.\n\n```tsx\n<form action={createItem}>\n  <input name="title" />\n</form>\n```\n\nQuelqu''un a déjà eu ce souci ?',
    v_bob, array['nextjs','server-actions']
  ) returning id into v_post;

  insert into public.comments (post_id, author_id, content)
  values (v_post, v_alice, E'Classique ! Utilise des noms indexés : `items[${i}].title`, puis reconstruis le tableau côté serveur à partir de `formData.entries()`.')
  returning id into v_c1;

  update public.posts set accepted_comment_id = v_c1, is_solved = true where id = v_post;

  insert into public.comments (post_id, parent_comment_id, author_id, content)
  values (v_post, v_c1, v_bob, 'Ça fonctionne nickel, merci ! 🙏')
  returning id into v_c2;

  insert into public.post_upvotes (post_id, user_id) values (v_post, v_alice) on conflict do nothing;
  insert into public.comment_upvotes (comment_id, user_id) values (v_c1, v_bob) on conflict do nothing;

  -- ==========================================================
  -- FIL 2 — Bob demande (MongoDB/Atlas), Alice répond, ouvert
  -- ==========================================================
  insert into public.posts (title, content, author_id, tags)
  values (
    'Timeout de connexion MongoDB Atlas en local, ça vient d''où ?',
    E'`MongooseServerSelectionError: connect ETIMEDOUT` depuis ce matin, alors que ça marchait hier. Des pistes ?',
    v_bob, array['mongodb','atlas','debug']
  ) returning id into v_post;

  insert into public.comments (post_id, author_id, content)
  values (v_post, v_alice, 'Vérifie l''IP whitelist sur Atlas (Network Access) — ta box a peut-être changé d''IP publique cette nuit.')
  returning id into v_c1;

  insert into public.comments (post_id, parent_comment_id, author_id, content)
  values (v_post, v_c1, v_bob, 'Vu, c''était bien ça, ma box avait rebooté cette nuit.')
  returning id into v_c2;

  insert into public.comment_upvotes (comment_id, user_id) values (v_c1, v_bob) on conflict do nothing;

  -- ==========================================================
  -- FIL 3 — Alice demande (recherche), Bob répond, ouvert
  -- ==========================================================
  insert into public.posts (title, content, author_id, tags)
  values (
    'Bonnes pratiques pour un Full-Text Search avec Atlas Search ?',
    'Atlas Search vs recherche full-text native Postgres/Supabase : lequel choisir en prod ?',
    v_alice, array['mongodb','search','postgres']
  ) returning id into v_post;

  insert into public.comments (post_id, author_id, content)
  values (v_post, v_bob, 'Je suis passé sur Postgres avec un index GIN sur `to_tsvector`. Largement suffisant pour un volume étudiant, et un service en moins à gérer.')
  returning id into v_c1;

  insert into public.post_upvotes (post_id, user_id) values (v_post, v_bob) on conflict do nothing;
  insert into public.comment_upvotes (comment_id, user_id) values (v_c1, v_alice) on conflict do nothing;

  -- ==========================================================
  -- FIL 4 — Bob demande (architecture), Alice répond, validée, thread niveau 2
  -- ==========================================================
  insert into public.posts (title, content, author_id, tags)
  values (
    'Server Components vs Client Components : comment vous tranchez ?',
    'Ma règle actuelle : dès qu''il y a un useState je mets client. J''ai l''impression de sur-utiliser le client du coup. Une heuristique plus fine ?',
    v_bob, array['nextjs','react','architecture']
  ) returning id into v_post;

  insert into public.comments (post_id, author_id, content)
  values (v_post, v_alice, 'Server Component par défaut partout, et je descends le "use client" le plus bas possible dans l''arbre — uniquement sur ce qui a vraiment besoin d''interactivité.')
  returning id into v_c1;

  update public.posts set accepted_comment_id = v_c1, is_solved = true where id = v_post;

  insert into public.comments (post_id, parent_comment_id, author_id, content)
  values (v_post, v_c1, v_bob, 'Donc isoler juste le bouton "upvote" en client component, pas toute la carte ?')
  returning id into v_c2;

  insert into public.comments (post_id, parent_comment_id, author_id, content)
  values (v_post, v_c2, v_alice, 'Exactement, le pattern "îlots interactifs".')
  returning id into v_c3;

  insert into public.comment_upvotes (comment_id, user_id) values (v_c1, v_bob) on conflict do nothing;
  insert into public.comment_upvotes (comment_id, user_id) values (v_c3, v_bob) on conflict do nothing;

  -- ==========================================================
  -- FIL 5 — Alice demande (REX stage), Bob répond, ouvert
  -- ==========================================================
  insert into public.posts (title, content, author_id, tags)
  values (
    'REX : conseils pour un entretien technique dev full-stack ?',
    'Entretien la semaine prochaine : 1h de live coding + questions d''archi. Vous recommandez de réviser quoi en priorité ?',
    v_alice, array['stage','entretien','conseils']
  ) returning id into v_post;

  insert into public.comments (post_id, author_id, content)
  values (v_post, v_bob, 'Entraîne-toi à verbaliser ton raisonnement à voix haute, c''est souvent plus noté que le résultat final.')
  returning id into v_c1;

  insert into public.post_upvotes (post_id, user_id) values (v_post, v_bob) on conflict do nothing;
  insert into public.comment_upvotes (comment_id, user_id) values (v_c1, v_alice) on conflict do nothing;

  -- ==========================================================
  -- FIL 6 — Bob demande (modélisation), Alice répond, validée
  -- ==========================================================
  insert into public.posts (title, content, author_id, tags)
  values (
    'Comment modéliser des upvotes proprement en base relationnelle ?',
    'Sur MongoDB j''avais un tableau upvotes[] dans le document Post. En passant sur Postgres/Supabase, tableau ou vraie table de jointure ?',
    v_bob, array['modelisation','sql','mongodb']
  ) returning id into v_post;

  insert into public.comments (post_id, author_id, content)
  values (v_post, v_alice, 'Table de jointure : `post_upvotes(post_id, user_id)` avec clé primaire composite. Unicité garantie et index performants.')
  returning id into v_c1;

  update public.posts set accepted_comment_id = v_c1, is_solved = true where id = v_post;

  insert into public.comment_upvotes (comment_id, user_id) values (v_c1, v_bob) on conflict do nothing;

  raise notice 'Seed terminé : comptes Alice (%) et Bob (%) créés avec 6 fils de discussion.', v_alice, v_bob;
end $$;

notify pgrst, 'reload schema';
