'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import PostCard from '@/components/PostCard';
import TagPill from '@/components/TagPill';
import type { PostWithCounts } from '@/types/database';
import { Search, PlusCircle } from 'lucide-react';

export default function QuestionsPage() {
  const [posts, setPosts] = useState<PostWithCounts[]>([]);
  const [allTags, setAllTags] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [activeTag, setActiveTag] = useState<string | null>(null);

  useEffect(() => {
    (async () => {
      const res = await fetch('/api/posts', { cache: 'no-store' });
      const { data } = await res.json();
      const tags = Array.from(new Set((data ?? []).flatMap((p: PostWithCounts) => p.tags))).slice(0, 12);
      setAllTags(tags as string[]);
    })();
  }, []);

  useEffect(() => {
    const t = setTimeout(async () => {
      setLoading(true);
      const params = new URLSearchParams();
      if (search) params.set('search', search);
      if (activeTag) params.set('tag', activeTag);
      const res = await fetch(`/api/posts?${params.toString()}`, { cache: 'no-store' });
      const { data } = await res.json();
      setPosts(data ?? []);
      setLoading(false);
    }, 250);
    return () => clearTimeout(t);
  }, [search, activeTag]);

  function toggleTag(tag: string) {
    setActiveTag((current) => (current === tag ? null : tag));
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6 flex-wrap gap-3">
        <h1 className="font-display text-3xl font-extrabold">Toutes les questions</h1>
        <Link href="/questions/create" className="btn-pop bg-coral text-white px-4 py-2 text-sm flex items-center gap-1.5">
          <PlusCircle size={16} /> Nouvelle question
        </Link>
      </div>

      <div className="relative mb-4">
        <Search size={18} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink/40" />
        <input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Rechercher dans l'historique des discussions…"
          className="w-full border-2 border-ink rounded-xl pl-10 pr-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo bg-white"
        />
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
          <p className="font-display text-xl font-bold">Aucun résultat</p>
          <p className="text-ink/60 text-sm mt-1">Essaie un autre mot-clé ou un autre tag, ou pose la question toi-même.</p>
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
