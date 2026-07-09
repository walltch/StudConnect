'use client';

import Link from 'next/link';
import { ArrowBigUp, MessageSquare, CheckCircle2 } from 'lucide-react';
import TagPill, { tagColor } from './TagPill';
import ReputationRing from './ReputationRing';
import type { PostWithCounts } from '@/types/database';

function timeAgo(dateStr: string) {
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return "à l'instant";
  if (mins < 60) return `il y a ${mins} min`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `il y a ${hrs} h`;
  const days = Math.floor(hrs / 24);
  return `il y a ${days} j`;
}

export default function PostCard({ post }: { post: PostWithCounts }) {
  const stripeColor = post.tags[0] ? tagColor(post.tags[0]) : tagColor('général');

  return (
    <Link href={`/questions/${post.id}`} className="block group">
      <article className="card-pop flex overflow-hidden hover:-translate-y-1 transition-transform">
        <div className={`w-2 shrink-0 ${stripeColor.dot}`} />
        <div className="flex-1 p-4 sm:p-5">
          <div className="flex items-start justify-between gap-3">
            <h3 className="font-display font-bold text-lg group-hover:text-indigo transition-colors">
              {post.title}
            </h3>
            {post.is_solved && (
              <span className="tag-pill bg-mint-100 text-mint-600 shrink-0 whitespace-nowrap">
                <CheckCircle2 size={12} className="mr-1" /> Résolu
              </span>
            )}
          </div>

          <p className="text-ink/60 text-sm mt-1.5 line-clamp-2">{post.content.replace(/[#*`>_-]/g, ' ')}</p>

          <div className="flex flex-wrap items-center gap-2 mt-3">
            {post.tags.slice(0, 4).map((t) => (
              <TagPill key={t} tag={t} />
            ))}
          </div>

          <div className="flex items-center justify-between mt-4">
            <div className="flex items-center gap-2">
              <ReputationRing
                reputation={post.author?.reputation ?? 0}
                initials={post.author?.full_name?.slice(0, 1)?.toUpperCase() ?? '?'}
                avatarUrl={post.author?.avatar_url}
                size={28}
              />
              <span className="text-xs font-semibold text-ink/70">{post.author?.full_name ?? 'Étudiant'}</span>
              <span className="text-xs text-ink/40">· {timeAgo(post.created_at)}</span>
            </div>

            <div className="flex items-center gap-3 text-ink/60 text-sm font-semibold">
              <span className="flex items-center gap-1">
                <ArrowBigUp size={16} /> {post.upvote_count}
              </span>
              <span className="flex items-center gap-1">
                <MessageSquare size={16} /> {post.comment_count}
              </span>
            </div>
          </div>
        </div>
      </article>
    </Link>
  );
}
