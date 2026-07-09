-- ============================================================
-- StudConnect — Seed de démonstration
-- Pré-requis : crée d'abord ces 2 comptes via l'app (/login → Inscription) :
--   - alice.martin@universite.fr  (Alice = étudiante confirmée, M1)
--   - bob.dupont@universite.fr    (Bob   = étudiant, L3, pose les questions)
-- Si tu utilises d'autres emails, remplace-les dans les 2 lignes "select id into"
-- ci-dessous puis relance tout le script.
-- ============================================================

do $$
declare
  v_alice uuid;
  v_bob   uuid;
  v_post  uuid;
  v_c1    uuid;
  v_c2    uuid;
  v_c3    uuid;
begin
  select id into v_alice from auth.users where email = 'alice.martin@universite.fr';
  select id into v_bob   from auth.users where email = 'bob.dupont@universite.fr';

  if v_alice is null or v_bob is null then
    raise exception 'Comptes introuvables. Crée d''abord alice.martin@universite.fr et bob.dupont@universite.fr via /login, puis relance ce script.';
  end if;

  -- --------------------------------------------------------
  -- Profils enrichis (onboarding)
  -- --------------------------------------------------------
  update public.profiles set
    full_name = 'Alice Martin',
    institution = 'Université Paris-Saclay',
    filiere = 'Informatique — Génie Logiciel',
    annee_etude = 'M1',
    skills = array['Next.js','MongoDB','Supabase','TypeScript','Architecture']
  where id = v_alice;

  update public.profiles set
    full_name = 'Bob Dupont',
    institution = 'Université Paris-Saclay',
    filiere = 'Informatique',
    annee_etude = 'L3',
    skills = array['Algorithmique','SQL','React']
  where id = v_bob;

  -- ==========================================================
  -- FIL 1 — Bob demande, Alice répond, solution validée, Bob relance en sous-thread
  -- ==========================================================
  insert into public.posts (title, content, author_id, tags)
  values (
    'Comment gérer les Server Actions avec un formulaire imbriqué ?',
    E'Je galère avec un formulaire qui contient un sous-formulaire dynamique (ajout de lignes). Dès que je soumets, la Server Action ne reçoit que le premier champ.\n\n```tsx\n<form action={createItem}>\n  <input name="title" />\n  {/* champs dynamiques ici */}\n</form>\n```\n\nQuelqu''un a déjà eu ce souci ?',
    v_bob, array['nextjs','server-actions']
  ) returning id into v_post;

  insert into public.comments (post_id, author_id, content)
  values (
    v_post, v_alice,
    E'Classique ! Le souci vient du fait que `FormData` ne sérialise pas bien les tableaux d''objets sans convention de nommage. Utilise plutôt des noms indexés :\n\n```tsx\n<input name={`items[${i}].title`} />\n```\n\nPuis côté Server Action, reconstruis le tableau à partir de `formData.entries()`. Ça évite de passer par du state client complexe.'
  ) returning id into v_c1;

  update public.posts set accepted_comment_id = v_c1, is_solved = true where id = v_post;

  insert into public.comments (post_id, parent_comment_id, author_id, content)
  values (v_post, v_c1, v_bob, 'Ça fonctionne nickel, merci ! Je ne savais pas qu''on pouvait indexer les name comme ça 🙏')
  returning id into v_c2;

  insert into public.post_upvotes (post_id, user_id) values (v_post, v_alice);
  insert into public.comment_upvotes (comment_id, user_id) values (v_c1, v_bob);

  -- ==========================================================
  -- FIL 2 — Bob demande (MongoDB/Supabase), Alice répond, pas encore résolu
  -- ==========================================================
  insert into public.posts (title, content, author_id, tags)
  values (
    'Timeout de connexion MongoDB Atlas en local, ça vient d''où ?',
    E'Depuis ce matin j''ai `MongooseServerSelectionError: connection timed out` en local, alors que ça marchait hier. J''ai vérifié ma connexion internet, rien de spécial.\n\n```\nMongooseServerSelectionError: connect ETIMEDOUT\n```\n\nDes pistes ?',
    v_bob, array['mongodb','atlas','debug']
  ) returning id into v_post;

  insert into public.comments (post_id, author_id, content)
  values (
    v_post, v_alice,
    E'99% du temps c''est l''IP whitelist sur Atlas qui a changé (box qui redémarre = nouvelle IP publique). Va dans **Network Access** sur Atlas et ajoute ton IP actuelle, ou mets `0.0.0.0/0` en dev (jamais en prod !).'
  ) returning id into v_c1;

  insert into public.comments (post_id, parent_comment_id, author_id, content)
  values (v_post, v_c1, v_bob, 'Ah oui carrément, ma box a rebooté cette nuit. Je regarde ça tout de suite.')
  returning id into v_c2;

  insert into public.comment_upvotes (comment_id, user_id) values (v_c1, v_bob);

  -- ==========================================================
  -- FIL 3 — Alice demande, Bob répond, question ouverte
  -- ==========================================================
  insert into public.posts (title, content, author_id, tags)
  values (
    'Bonnes pratiques pour un Full-Text Search avec Atlas Search ?',
    E'Je veux indexer `title` et `content` de mes posts pour une recherche pertinente (pas juste un `LIKE`). J''hésite entre un index Atlas Search classique et une approche full-text native Postgres avec `to_tsvector`.\n\nQuelqu''un a comparé les deux en prod ?',
    v_alice, array['mongodb','search','postgres']
  ) returning id into v_post;

  insert into public.comments (post_id, author_id, content)
  values (
    v_post, v_bob,
    E'Perso je suis passé sur Postgres (via Supabase) avec un index GIN sur `to_tsvector('' french'', title || '' '' || content)`. C''est largement suffisant pour un volume de posts étudiant, et ça évite un service externe en plus à gérer.'
  ) returning id into v_c1;

  insert into public.post_upvotes (post_id, user_id) values (v_post, v_bob);
  insert into public.comment_upvotes (comment_id, user_id) values (v_c1, v_alice);

  -- ==========================================================
  -- FIL 4 — Bob demande (architecture Next.js), Alice répond, validée, thread niveau 2
  -- ==========================================================
  insert into public.posts (title, content, author_id, tags)
  values (
    'Server Components vs Client Components : comment vous tranchez ?',
    E'J''ai du mal à savoir quand mettre `''use client''`. Ma règle actuelle : dès qu''il y a un `useState` je mets client, mais j''ai l''impression de sur-utiliser le client du coup.\n\nVous avez une heuristique plus fine ?',
    v_bob, array['nextjs','react','architecture']
  ) returning id into v_post;

  insert into public.comments (post_id, author_id, content)
  values (
    v_post, v_alice,
    E'Ma règle : je pars du principe que **tout est Server Component par défaut**, et je descends le `''use client''` le plus bas possible dans l''arbre — uniquement sur le composant qui a réellement besoin d''interactivité (bouton, formulaire, etc.), jamais sur un layout entier.\n\nÇa réduit le JS envoyé au client et garde les fetch de données côté serveur.'
  ) returning id into v_c1;

  update public.posts set accepted_comment_id = v_c1, is_solved = true where id = v_post;

  insert into public.comments (post_id, parent_comment_id, author_id, content)
  values (v_post, v_c1, v_bob, 'Donc en gros je devrais isoler juste le bouton "upvote" en client component, pas toute la carte de la question ?')
  returning id into v_c2;

  insert into public.comments (post_id, parent_comment_id, author_id, content)
  values (v_post, v_c2, v_alice, 'Exactement, c''est le pattern "îlots interactifs". Le reste de la carte reste statique côté serveur.')
  returning id into v_c3;

  insert into public.comment_upvotes (comment_id, user_id) values (v_c1, v_bob);
  insert into public.comment_upvotes (comment_id, user_id) values (v_c3, v_bob);

  -- ==========================================================
  -- FIL 5 — Alice demande (REX stage), Bob répond, question ouverte (discussion sociale)
  -- ==========================================================
  insert into public.posts (title, content, author_id, tags)
  values (
    'REX : conseils pour un entretien technique dev full-stack ?',
    E'Je passe un entretien la semaine prochaine pour un stage full-stack (Next.js/Postgres). Ils annoncent "1h de live coding + questions d''archi".\n\nCeux qui sont déjà passés par là, vous recommandez de réviser quoi en priorité ?',
    v_alice, array['stage','entretien','conseils']
  ) returning id into v_post;

  insert into public.comments (post_id, author_id, content)
  values (
    v_post, v_bob,
    E'Pour le live coding, entraîne-toi surtout à **verbaliser ton raisonnement** à voix haute, c''est souvent plus noté que le résultat final. Pour l''archi, sois capable de justifier un choix (pourquoi Server Actions plutôt qu''une API REST, par exemple) plutôt que de réciter une définition.'
  ) returning id into v_c1;

  insert into public.comments (post_id, parent_comment_id, author_id, content)
  values (v_post, v_c1, v_alice, 'Merci, ça rejoint ce qu''on disait sur le fil Server vs Client Components tiens, je vais relire ça avant l''entretien 😄')
  returning id into v_c2;

  insert into public.post_upvotes (post_id, user_id) values (v_post, v_bob);
  insert into public.comment_upvotes (comment_id, user_id) values (v_c1, v_alice);

  -- ==========================================================
  -- FIL 6 — Bob demande (modélisation), Alice répond, validée
  -- ==========================================================
  insert into public.posts (title, content, author_id, tags)
  values (
    'Comment modéliser des upvotes proprement en base relationnelle ?',
    E'Sur mon ancien projet MongoDB j''avais un tableau `upvotes: ObjectId[]` directement dans le document Post. En passant sur Postgres/Supabase, je fais quoi ? Je garde un tableau, ou une vraie table de jointure ?',
    v_bob, array['modelisation','sql','mongodb']
  ) returning id into v_post;

  insert into public.comments (post_id, author_id, content)
  values (
    v_post, v_alice,
    E'Table de jointure clairement : `post_upvotes(post_id, user_id)` avec une clé primaire composite. Ça te donne gratuitement l''unicité (un seul vote par user), des index performants, et tu peux compter avec un simple `count(*)` ou une vue matérialisée si le volume grossit. Le tableau JSON, c''est pratique tant que tu ne veux pas contraindre l''unicité côté base.'
  ) returning id into v_c1;

  update public.posts set accepted_comment_id = v_c1, is_solved = true where id = v_post;

  insert into public.comment_upvotes (comment_id, user_id) values (v_c1, v_bob);

  raise notice 'Seed terminé : 6 fils de discussion créés pour Alice (%) et Bob (%)', v_alice, v_bob;
end $$;
