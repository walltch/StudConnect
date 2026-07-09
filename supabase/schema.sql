-- ============================================================
-- StudConnect — Schéma Supabase (Postgres)
-- À exécuter dans Supabase > SQL Editor
-- ============================================================

create extension if not exists "uuid-ossp";

-- ------------------------------------------------------------
-- 1. PROFILES (1-1 avec auth.users)
-- ------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text not null default '',
  institution text default '',
  filiere text default '',
  annee_etude text default '',
  skills text[] default '{}',
  reputation int not null default 0,
  avatar_url text,
  created_at timestamptz not null default now()
);

-- Création automatique du profil à l'inscription
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email,'@',1)));
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ------------------------------------------------------------
-- 2. POSTS (questions)
-- ------------------------------------------------------------
create table if not exists public.posts (
  id uuid primary key default uuid_generate_v4(),
  title text not null,
  content text not null,
  author_id uuid not null references public.profiles(id) on delete cascade,
  tags text[] not null default '{}',
  is_solved boolean not null default false,
  accepted_comment_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists posts_tags_idx on public.posts using gin (tags);
create index if not exists posts_search_idx on public.posts
  using gin (to_tsvector('french', title || ' ' || content));

-- ------------------------------------------------------------
-- 3. COMMENTS (réponses + threads imbriqués niveau 2)
-- ------------------------------------------------------------
create table if not exists public.comments (
  id uuid primary key default uuid_generate_v4(),
  post_id uuid not null references public.posts(id) on delete cascade,
  parent_comment_id uuid references public.comments(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now()
);

alter table public.posts
  add constraint fk_accepted_comment
  foreign key (accepted_comment_id) references public.comments(id) on delete set null;

-- ------------------------------------------------------------
-- 4. UPVOTES
-- ------------------------------------------------------------
create table if not exists public.post_upvotes (
  post_id uuid references public.posts(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table if not exists public.comment_upvotes (
  comment_id uuid references public.comments(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (comment_id, user_id)
);

-- ------------------------------------------------------------
-- 5. RÉPUTATION — triggers automatiques
-- ------------------------------------------------------------
create or replace function public.bump_reputation(target uuid, delta int)
returns void as $$
begin
  update public.profiles set reputation = greatest(0, reputation + delta) where id = target;
end;
$$ language plpgsql security definer;

-- +5 quand un commentaire est upvoté, -5 si retiré
create or replace function public.on_comment_upvote()
returns trigger as $$
declare owner uuid;
begin
  select author_id into owner from public.comments where id = coalesce(new.comment_id, old.comment_id);
  if tg_op = 'INSERT' then
    perform public.bump_reputation(owner, 5);
  elsif tg_op = 'DELETE' then
    perform public.bump_reputation(owner, -5);
  end if;
  return null;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_comment_upvote on public.comment_upvotes;
create trigger trg_comment_upvote
  after insert or delete on public.comment_upvotes
  for each row execute procedure public.on_comment_upvote();

-- +15 quand une réponse est acceptée comme solution
create or replace function public.on_post_solved()
returns trigger as $$
begin
  if new.accepted_comment_id is not null and (old.accepted_comment_id is null or old.accepted_comment_id != new.accepted_comment_id) then
    perform public.bump_reputation(
      (select author_id from public.comments where id = new.accepted_comment_id), 15
    );
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_post_solved on public.posts;
create trigger trg_post_solved
  after update of accepted_comment_id on public.posts
  for each row execute procedure public.on_post_solved();

-- ------------------------------------------------------------
-- 6. ROW LEVEL SECURITY
-- ------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.posts enable row level security;
alter table public.comments enable row level security;
alter table public.post_upvotes enable row level security;
alter table public.comment_upvotes enable row level security;

-- Profiles : lecture publique, écriture par le propriétaire
create policy "profiles_select_all" on public.profiles for select using (true);
create policy "profiles_insert_own" on public.profiles for insert with check (auth.uid() = id);
create policy "profiles_update_own" on public.profiles for update using (auth.uid() = id);

-- Posts : lecture publique, écriture par auteur authentifié
create policy "posts_select_all" on public.posts for select using (true);
create policy "posts_insert_own" on public.posts for insert with check (auth.uid() = author_id);
create policy "posts_update_own" on public.posts for update using (auth.uid() = author_id);
create policy "posts_delete_own" on public.posts for delete using (auth.uid() = author_id);

-- Comments : lecture publique, écriture par auteur authentifié
create policy "comments_select_all" on public.comments for select using (true);
create policy "comments_insert_own" on public.comments for insert with check (auth.uid() = author_id);
create policy "comments_update_own" on public.comments for update using (auth.uid() = author_id);
create policy "comments_delete_own" on public.comments for delete using (auth.uid() = author_id);

-- Upvotes : chacun gère les siens, lecture publique (pour compter)
create policy "post_upvotes_select_all" on public.post_upvotes for select using (true);
create policy "post_upvotes_insert_own" on public.post_upvotes for insert with check (auth.uid() = user_id);
create policy "post_upvotes_delete_own" on public.post_upvotes for delete using (auth.uid() = user_id);

create policy "comment_upvotes_select_all" on public.comment_upvotes for select using (true);
create policy "comment_upvotes_insert_own" on public.comment_upvotes for insert with check (auth.uid() = user_id);
create policy "comment_upvotes_delete_own" on public.comment_upvotes for delete using (auth.uid() = user_id);

-- ------------------------------------------------------------
-- 7. VUE pratique : posts enrichis (compteurs)
-- ------------------------------------------------------------
create or replace view public.posts_with_counts as
select
  p.*,
  (select count(*) from public.post_upvotes u where u.post_id = p.id) as upvote_count,
  (select count(*) from public.comments c where c.post_id = p.id) as comment_count
from public.posts p;
