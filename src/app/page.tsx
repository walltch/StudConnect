'use client';

import { useEffect, useState } from 'react';
import PostCard from '@/components/PostCard';
import TagPill from '@/components/TagPill';
import type { PostWithCounts } from '@/types/database';
import { Search, Sparkles } from 'lucide-react';

export default function FeedPage() {
  const [posts, setPosts] = useState<PostWithCounts[]>([]);
  const [allTags, setAllTags] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [activeTag, setActiveTag] = useState<string | null>(null);
  const [filter, setFilter] = useState<'all' | 'open' | 'solved'>('all');

  async function load() {
    setLoading(true);
    const params = new URLSearchParams();
    if (search) params.set('search', search);
    if (activeTag) params.set('tag', activeTag);
    if (filter === 'open') params.set('solved', 'false');
    if (filter === 'solved') params.set('solved', 'true');
    const res = await fetch(`/api/posts?${params.toString()}`, { cache: 'no-store' });
    const { data } = await res.json();
    setPosts(data ?? []);
    setLoading(false);
  }

  // Liste de tags chargée une seule fois, indépendamment des filtres actifs,
  // pour que les pastilles restent toutes cliquables même après avoir filtré.
  useEffect(() => {
    (async () => {
      const res = await fetch('/api/posts', { cache: 'no-store' });
      const { data } = await res.json();
      const tags = Array.from(new Set((data ?? []).flatMap((p: PostWithCounts) => p.tags))).slice(0, 12);
      setAllTags(tags as string[]);
    })();
  }, []);

  useEffect(() => {
    const t = setTimeout(load, 250);
    return () => clearTimeout(t);
  }, [search, activeTag, filter]);

  function toggleTag(tag: string) {
    setActiveTag((current) => (current === tag ? null : tag));
  }

  return (
    <div>
      <div className="mb-8">
        <div className="flex items-center gap-2 text-coral font-bold text-sm mb-2">
          <Sparkles size={16} /> MÉMOIRE COLLECTIVE
        </div>
        <h1 className="font-display text-4xl font-extrabold leading-tight">
          Ce que ta promo a appris, <span className="text-indigo">ça ne se perd plus.</span>
        </h1>
      </div>

      <div className="flex flex-col sm:flex-row gap-3 mb-4">
        <div className="relative flex-1">
          <Search size={18} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink/40" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Rechercher une question, un mot-clé…"
            className="w-full border-2 border-ink rounded-xl pl-10 pr-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo bg-white"
          />
        </div>
        <div className="flex rounded-xl border-2 border-ink overflow-hidden shrink-0">
          {(['all', 'open', 'solved'] as const).map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`px-4 py-2 text-sm font-bold ${filter === f ? 'bg-ink text-white' : 'bg-white hover:bg-ink/5'} ${f !== 'all' ? 'border-l-2 border-ink' : ''}`}
            >
              {f === 'all' ? 'Tout' : f === 'open' ? 'Ouvertes' : 'Résolues'}
            </button>
          ))}
        </div>
      </div>

      {allTags.length > 0 && (
        <div className="flex flex-wrap items-center gap-2 mb-6">
          {allTags.map((t) => (
            <div key={t} className={activeTag === t ? 'ring-2 ring-ink rounded-full' : ''}>
              <TagPill tag={t} onClick={() => toggleTag(t)} />
            </div>
          ))}
          {activeTag && (
            <button onClick={() => setActiveTag(null)} className="text-xs font-bold text-ink/50 hover:text-coral-600 underline">
              Effacer le filtre
            </button>
          )}
        </div>
      )}

      {loading ? (
        <div className="space-y-4">
          {[1, 2, 3].map((i) => (
            <div key={i} className="card-pop h-28 animate-pulse bg-ink/5" />
          ))}
        </div>
      ) : posts.length === 0 ? (
        <div className="card-pop p-10 text-center">
          <p className="font-display text-xl font-bold mb-1">Aucune question pour l'instant</p>
          <p className="text-ink/60 text-sm">Sois le premier à lancer une discussion et à nourrir la mémoire collective.</p>
        </div>
      ) : (
        <div className="space-y-4">
          {posts.map((p) => (
            <PostCard key={p.id} post={p} />
          ))}
        </div>
      )}
    </div>
  );
}
