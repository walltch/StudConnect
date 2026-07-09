-- ============================================================
-- Patch : droits d'accès explicites + reload du cache API
-- À lancer dans le SQL Editor Supabase si les nouvelles questions
-- n'apparaissent pas dans le fil / la liste alors qu'elles sont
-- bien visibles dans Table Editor.
-- ============================================================

grant usage on schema public to anon, authenticated;

grant select, insert, update, delete on
  public.profiles,
  public.posts,
  public.comments,
  public.post_upvotes,
  public.comment_upvotes
to anon, authenticated;

-- La vue posts_with_counts n'hérite pas toujours des default privileges
grant select on public.posts_with_counts to anon, authenticated;

-- S'assurer que les futures tables/vues auront aussi ces droits
alter default privileges in schema public
  grant select, insert, update, delete on tables to anon, authenticated;

-- Force PostgREST à relire immédiatement le schéma (tables + vues)
notify pgrst, 'reload schema';

-- ------------------------------------------------------------
-- Policy manquante : permet à un utilisateur de créer SA PROPRE
-- ligne dans profiles (nécessaire pour le filet de sécurité côté
-- API qui recrée le profil si le trigger n'a pas tourné, et pour
-- l'upsert de /api/profile PUT).
-- ------------------------------------------------------------
drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles
  for insert
  with check (auth.uid() = id);
