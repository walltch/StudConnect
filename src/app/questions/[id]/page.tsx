'use client';

import { useEffect, useState, useCallback } from 'react';
import { useParams, useRouter } from 'next/navigation';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { createClient } from '@/lib/supabase/client';
import ReputationRing from '@/components/ReputationRing';
import TagPill from '@/components/TagPill';
import CommentItem from '@/components/CommentItem';
import type { Comment, PostWithCounts } from '@/types/database';
import { ArrowBigUp, CheckCircle2, Trash2, Pencil, Send } from 'lucide-react';

type PostDetail = PostWithCounts & { comments: Comment[]; has_upvoted: boolean };

function buildTree(flat: Comment[], acceptedId: string | null): Comment[] {
  const map = new Map<string, Comment>();
  flat.forEach((c) => map.set(c.id, { ...c, children: [] }));
  const roots: Comment[] = [];
  flat.forEach((c) => {
    const node = map.get(c.id)!;
    if (c.parent_comment_id && map.has(c.parent_comment_id)) {
      map.get(c.parent_comment_id)!.children!.push(node);
    } else {
      roots.push(node);
    }
  });

  // La réponse validée est épinglée en tête, puis tri par score (upvotes),
  // puis par date — comme un vrai forum d'entraide.
  roots.sort((a, b) => {
    if (a.id === acceptedId) return -1;
    if (b.id === acceptedId) return 1;
    const diff = (b.upvote_count ?? 0) - (a.upvote_count ?? 0);
    if (diff !== 0) return diff;
    return new Date(a.created_at).getTime() - new Date(b.created_at).getTime();
  });

  return roots;
}

export default function QuestionDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const supabase = createClient();

  const [post, setPost] = useState<PostDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [userId, setUserId] = useState<string | undefined>();
  const [answerText, setAnswerText] = useState('');
  const [answerError, setAnswerError] = useState('');
  const [posting, setPosting] = useState(false);
  const [editing, setEditing] = useState(false);
  const [editTitle, setEditTitle] = useState('');
  const [editContent, setEditContent] = useState('');

  const load = useCallback(async () => {
    const res = await fetch(`/api/posts/${id}`, { cache: 'no-store' });
    if (!res.ok) {
      setPost(null);
      setLoading(false);
      return;
    }
    const { data } = await res.json();
    setPost(data);
    setEditTitle(data.title);
    setEditContent(data.content);
    setLoading(false);
  }, [id]);

  useEffect(() => {
    (async () => {
      const {
        data: { user },
      } = await supabase.auth.getUser();
      setUserId(user?.id);
    })();
    load();
  }, [load]);

  async function toggleUpvote() {
    if (!userId) return router.push('/login');
    const res = await fetch(`/api/posts/${id}/upvote`, { method: 'POST' });
    if (!res.ok) {
      const { error } = await res.json().catch(() => ({ error: 'Erreur inconnue' }));
      alert(error || "Impossible d'enregistrer le vote");
      return;
    }
    load();
  }

  async function submitAnswer(e: React.FormEvent) {
    e.preventDefault();
    setAnswerError('');
    if (!userId) return router.push('/login');
    if (!answerText.trim()) return;
    setPosting(true);
    const res = await fetch('/api/comments', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ post_id: id, content: answerText }),
    });
    setPosting(false);
    if (!res.ok) {
      const { error } = await res.json().catch(() => ({ error: 'Erreur inconnue' }));
      setAnswerError(error || "Impossible d'envoyer la réponse");
      return;
    }
    setAnswerText('');
    load();
  }

  async function handleReply(parentId: string, content: string) {
    if (!userId) return router.push('/login');
    const res = await fetch('/api/comments', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ post_id: id, content, parent_comment_id: parentId }),
    });
    if (!res.ok) {
      const { error } = await res.json().catch(() => ({ error: 'Erreur inconnue' }));
      alert(error || "Impossible d'envoyer la réponse");
      return;
    }
    load();
  }

  async function handleCommentUpvote(commentId: string) {
    if (!userId) return router.push('/login');
    const res = await fetch(`/api/comments/${commentId}/upvote`, { method: 'POST' });
    if (!res.ok) {
      const { error } = await res.json().catch(() => ({ error: 'Erreur inconnue' }));
      alert(error || "Impossible d'enregistrer le vote");
      return;
    }
    load();
  }

  async function handleAccept(commentId: string) {
    const res = await fetch(`/api/posts/${id}/accept`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ comment_id: commentId }),
    });
    if (!res.ok) {
      const { error } = await res.json().catch(() => ({ error: 'Erreur inconnue' }));
      alert(error || 'Impossible de valider cette réponse comme solution');
      return;
    }
    const { data } = await res.json();
    // Mise à jour optimiste immédiate, en plus du rechargement complet ci-dessous
    setPost((p) => (p ? { ...p, is_solved: true, accepted_comment_id: data.accepted_comment_id } : p));
    load();
  }

  async function handleDeleteComment(commentId: string) {
    if (!confirm('Supprimer cette réponse ?')) return;
    const res = await fetch(`/api/comments/${commentId}`, { method: 'DELETE' });
    if (!res.ok) {
      const { error } = await res.json().catch(() => ({ error: 'Erreur inconnue' }));
      alert(error || 'Impossible de supprimer cette réponse');
      return;
    }
    load();
  }

  async function handleDeletePost() {
    if (!confirm('Supprimer définitivement cette question et toutes ses réponses ?')) return;
    const res = await fetch(`/api/posts/${id}`, { method: 'DELETE' });
    if (!res.ok) {
      const { error } = await res.json().catch(() => ({ error: 'Erreur inconnue' }));
      alert(error || 'Impossible de supprimer cette question');
      return;
    }
    router.push('/questions');
  }

  async function saveEdit() {
    await fetch(`/api/posts/${id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: editTitle, content: editContent }),
    });
    setEditing(false);
    load();
  }

  if (loading) return <div className="card-pop h-40 animate-pulse bg-ink/5" />;
  if (!post) return <div className="card-pop p-10 text-center font-display text-xl font-bold">Question introuvable</div>;

  const isAuthor = userId === post.author_id;
  const tree = buildTree(post.comments, post.accepted_comment_id);

  return (
    <div className="max-w-3xl mx-auto">
      <article className="card-pop p-6 mb-6">
        {editing ? (
          <div className="space-y-3">
            <input
              value={editTitle}
              onChange={(e) => setEditTitle(e.target.value)}
              className="w-full border-2 border-ink rounded-lg px-3 py-2 font-display font-bold text-xl"
            />
            <textarea
              value={editContent}
              onChange={(e) => setEditContent(e.target.value)}
              rows={8}
              className="w-full border-2 border-ink rounded-lg px-3 py-2 font-mono text-sm"
            />
            <div className="flex gap-2">
              <button onClick={saveEdit} className="btn-pop bg-indigo text-white px-4 py-1.5 text-sm">
                Enregistrer
              </button>
              <button onClick={() => setEditing(false)} className="btn-pop bg-white px-4 py-1.5 text-sm">
                Annuler
              </button>
            </div>
          </div>
        ) : (
          <>
            <div className="flex items-start justify-between gap-3 flex-wrap">
              <h1 className="font-display text-2xl sm:text-3xl font-extrabold">{post.title}</h1>
              {post.is_solved && (
                <span className="tag-pill bg-mint-100 text-mint-600 shrink-0">
                  <CheckCircle2 size={12} className="mr-1" /> Résolu
                </span>
              )}
            </div>

            <div className="flex items-center gap-2 mt-3 mb-4 flex-wrap">
              {post.tags.map((t) => (
                <TagPill key={t} tag={t} />
              ))}
            </div>

            <div className="prose max-w-none prose-pre:bg-ink prose-pre:text-white prose-pre:rounded-xl">
              <ReactMarkdown remarkPlugins={[remarkGfm]}>{post.content}</ReactMarkdown>
            </div>

            <div className="flex items-center justify-between mt-6 pt-4 border-t-2 border-dashed border-ink/20">
              <div className="flex items-center gap-2">
                <ReputationRing
                  reputation={post.author?.reputation ?? 0}
                  initials={post.author?.full_name?.slice(0, 1)?.toUpperCase() ?? '?'}
                  avatarUrl={post.author?.avatar_url}
                  size={36}
                />
                <div>
                  <p className="text-sm font-bold">{post.author?.full_name}</p>
                  <p className="text-xs text-ink/50">{post.author?.filiere}</p>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <button
                  onClick={toggleUpvote}
                  className={`btn-pop px-3 py-1.5 text-sm flex items-center gap-1.5 ${post.has_upvoted ? 'bg-indigo text-white' : 'bg-white'}`}
                >
                  <ArrowBigUp size={16} /> {post.upvote_count}
                </button>
                {isAuthor && (
                  <>
                    <button onClick={() => setEditing(true)} className="p-2 rounded-lg border-2 border-ink hover:bg-ink/5">
                      <Pencil size={16} />
                    </button>
                    <button onClick={handleDeletePost} className="p-2 rounded-lg border-2 border-ink hover:bg-coral-100">
                      <Trash2 size={16} />
                    </button>
                  </>
                )}
              </div>
            </div>
          </>
        )}
      </article>

      <h2 className="font-display text-xl font-extrabold mb-3">
        {post.comment_count} {post.comment_count > 1 ? 'réponses' : 'réponse'}
      </h2>

      <div className="space-y-3 mb-6">
        {tree.map((c) => (
          <CommentItem
            key={c.id}
            comment={c}
            currentUserId={userId}
            isQuestionAuthor={isAuthor}
            acceptedCommentId={post.accepted_comment_id}
            onUpvote={handleCommentUpvote}
            onReply={handleReply}
            onAccept={handleAccept}
            onDelete={handleDeleteComment}
          />
        ))}
      </div>

      <form onSubmit={submitAnswer} className="card-pop p-4">
        <label className="text-xs font-bold uppercase tracking-wide text-ink/60">Ta réponse / REX</label>
        <textarea
          value={answerText}
          onChange={(e) => setAnswerText(e.target.value)}
          rows={4}
          placeholder="Partage ton retour d'expérience, avec du code si utile…"
          className="w-full mt-1 border-2 border-ink rounded-lg px-3 py-2 font-mono text-sm focus:outline-none focus:ring-2 focus:ring-indigo"
        />
        {answerError && (
          <p className="text-sm font-semibold text-coral-600 bg-coral-100 rounded-lg px-3 py-2 mt-3">{answerError}</p>
        )}
        <button disabled={posting} type="submit" className="btn-pop bg-coral text-white px-4 py-2 text-sm mt-3 flex items-center gap-1.5">
          <Send size={14} /> {posting ? 'Envoi…' : 'Publier ma réponse'}
        </button>
      </form>
    </div>
  );
}
