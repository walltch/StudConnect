'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import TagPill from '@/components/TagPill';
import type { PostWithCounts } from '@/types/database';
import { Eye, Code2, AlertTriangle } from 'lucide-react';

export default function CreateQuestionPage() {
  const router = useRouter();
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [tagInput, setTagInput] = useState('');
  const [tags, setTags] = useState<string[]>([]);
  const [preview, setPreview] = useState(false);
  const [similar, setSimilar] = useState<PostWithCounts[]>([]);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  // Aiguillage prédictif : recherche de sujets similaires pendant la saisie du titre
  useEffect(() => {
    if (title.trim().length < 6) {
      setSimilar([]);
      return;
    }
    const t = setTimeout(async () => {
      const res = await fetch(`/api/posts?search=${encodeURIComponent(title)}`);
      const { data } = await res.json();
      setSimilar((data ?? []).slice(0, 3));
    }, 400);
    return () => clearTimeout(t);
  }, [title]);

  function addTag() {
    const v = tagInput.trim().toLowerCase().replace(/\s+/g, '-');
    if (v && !tags.includes(v) && tags.length < 6) setTags([...tags, v]);
    setTagInput('');
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    if (!title.trim() || !content.trim()) {
      setError('Le titre et la description sont obligatoires');
      return;
    }
    setSaving(true);
    const res = await fetch('/api/posts', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title, content, tags }),
    });
    setSaving(false);
    if (!res.ok) {
      const { error } = await res.json();
      setError(error || 'Une erreur est survenue');
      return;
    }
    const { data } = await res.json();
    router.push(`/questions/${data.id}`);
  }

  return (
    <div className="max-w-2xl mx-auto">
      <h1 className="font-display text-3xl font-extrabold mb-1">Formule ta demande d'aide</h1>
      <p className="text-ink/60 mb-6">Sois précis : titre clair, contexte, et blocs de code si besoin.</p>

      {similar.length > 0 && (
        <div className="card-pop p-4 mb-6 bg-amber-100 border-amber-500">
          <p className="flex items-center gap-2 font-bold text-sm mb-2">
            <AlertTriangle size={16} className="text-amber-500" /> Des sujets similaires existent déjà :
          </p>
          <ul className="space-y-1">
            {similar.map((s) => (
              <li key={s.id}>
                <a href={`/questions/${s.id}`} className="text-sm font-semibold text-indigo hover:underline">
                  {s.title}
                </a>
              </li>
            ))}
          </ul>
        </div>
      )}

      <form onSubmit={handleSubmit} className="card-pop p-6 space-y-5">
        <div>
          <label className="text-xs font-bold uppercase tracking-wide text-ink/60">Titre</label>
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="w-full mt-1 border-2 border-ink rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-indigo"
            placeholder="Ex : Comment gérer les Server Actions avec un formulaire imbriqué ?"
          />
        </div>

        <div>
          <div className="flex items-center justify-between">
            <label className="text-xs font-bold uppercase tracking-wide text-ink/60">Description (Markdown)</label>
            <div className="flex rounded-lg border-2 border-ink overflow-hidden text-xs font-bold">
              <button type="button" onClick={() => setPreview(false)} className={`px-2.5 py-1 flex items-center gap-1 ${!preview ? 'bg-ink text-white' : 'bg-white'}`}>
                <Code2 size={12} /> Éditer
              </button>
              <button type="button" onClick={() => setPreview(true)} className={`px-2.5 py-1 flex items-center gap-1 border-l-2 border-ink ${preview ? 'bg-ink text-white' : 'bg-white'}`}>
                <Eye size={12} /> Aperçu
              </button>
            </div>
          </div>
          {!preview ? (
            <textarea
              value={content}
              onChange={(e) => setContent(e.target.value)}
              rows={10}
              className="w-full mt-1 border-2 border-ink rounded-lg px-3 py-2 font-mono text-sm focus:outline-none focus:ring-2 focus:ring-indigo"
              placeholder={'Décris ton problème…\n\n```js\nconst x = 1;\n```'}
            />
          ) : (
            <div className="mt-1 border-2 border-ink rounded-lg px-3 py-2 min-h-[240px] prose prose-sm max-w-none">
              <ReactMarkdown remarkPlugins={[remarkGfm]}>{content || '*Rien à prévisualiser*'}</ReactMarkdown>
            </div>
          )}
        </div>

        <div>
          <label className="text-xs font-bold uppercase tracking-wide text-ink/60">Tags thématiques</label>
          <div className="flex gap-2 mt-1">
            <input
              value={tagInput}
              onChange={(e) => setTagInput(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  e.preventDefault();
                  addTag();
                }
              }}
              className="flex-1 border-2 border-ink rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-indigo"
              placeholder="nextjs, mongodb, algo…"
            />
            <button type="button" onClick={addTag} className="btn-pop bg-mint text-white px-4">
              Ajouter
            </button>
          </div>
          {tags.length > 0 && (
            <div className="flex flex-wrap gap-2 mt-3">
              {tags.map((t) => (
                <span key={t} onClick={() => setTags(tags.filter((x) => x !== t))}>
                  <TagPill tag={t} onClick={() => setTags(tags.filter((x) => x !== t))} />
                </span>
              ))}
            </div>
          )}
        </div>

        {error && <p className="text-sm font-semibold text-coral-600 bg-coral-100 rounded-lg px-3 py-2">{error}</p>}

        <button disabled={saving} type="submit" className="btn-pop bg-indigo text-white w-full py-2.5">
          {saving ? 'Publication…' : 'Publier ma question'}
        </button>
      </form>
    </div>
  );
}
