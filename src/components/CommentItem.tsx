'use client';

import { useState } from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import ReputationRing from './ReputationRing';
import { ArrowBigUp, CheckCircle2, CornerDownRight, Trash2 } from 'lucide-react';
import type { Comment } from '@/types/database';

export default function CommentItem({
  comment,
  currentUserId,
  isQuestionAuthor,
  acceptedCommentId,
  depth = 0,
  onUpvote,
  onReply,
  onAccept,
  onDelete,
}: {
  comment: Comment;
  currentUserId?: string;
  isQuestionAuthor: boolean;
  acceptedCommentId: string | null;
  depth?: number;
  onUpvote: (id: string) => void;
  onReply: (parentId: string, content: string) => void;
  onAccept: (id: string) => void;
  onDelete: (id: string) => void;
}) {
  const [replying, setReplying] = useState(false);
  const [replyText, setReplyText] = useState('');
  const isAccepted = acceptedCommentId === comment.id;

  return (
    <div className={depth > 0 ? 'ml-6 sm:ml-10 mt-3' : ''}>
      <div
        className={`card-pop p-4 ${isAccepted ? 'border-mint-500 bg-mint-100/40' : ''}`}
      >
        <div className="flex items-start gap-3">
          <button
            onClick={() => onUpvote(comment.id)}
            className={`flex flex-col items-center gap-0.5 shrink-0 rounded-lg border-2 border-ink px-2 py-1 font-bold text-sm transition-colors ${comment.has_upvoted ? 'bg-indigo text-white' : 'bg-white hover:bg-indigo-100'}`}
          >
            <ArrowBigUp size={16} />
            {comment.upvote_count ?? 0}
          </button>

          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-1.5 flex-wrap">
              <ReputationRing
                reputation={comment.author?.reputation ?? 0}
                initials={comment.author?.full_name?.slice(0, 1)?.toUpperCase() ?? '?'}
                avatarUrl={comment.author?.avatar_url}
                size={24}
              />
              <span className="text-xs font-bold">{comment.author?.full_name ?? 'Étudiant'}</span>
              {isAccepted && (
                <span className="tag-pill bg-mint-100 text-mint-600">
                  <CheckCircle2 size={12} className="mr-1" /> Solution validée
                </span>
              )}
            </div>

            <div className="prose prose-sm max-w-none">
              <ReactMarkdown remarkPlugins={[remarkGfm]}>{comment.content}</ReactMarkdown>
            </div>

            <div className="flex items-center gap-3 mt-2 text-xs font-bold text-ink/60">
              <button onClick={() => setReplying((r) => !r)} className="flex items-center gap-1 hover:text-indigo">
                <CornerDownRight size={14} /> Répondre
              </button>
              {isQuestionAuthor && !isAccepted && (
                <button onClick={() => onAccept(comment.id)} className="flex items-center gap-1 hover:text-mint-600">
                  <CheckCircle2 size={14} /> Valider comme solution
                </button>
              )}
              {currentUserId === comment.author_id && (
                <button onClick={() => onDelete(comment.id)} className="flex items-center gap-1 hover:text-coral-600">
                  <Trash2 size={14} /> Supprimer
                </button>
              )}
            </div>

            {replying && (
              <div className="mt-3 flex gap-2">
                <input
                  autoFocus
                  value={replyText}
                  onChange={(e) => setReplyText(e.target.value)}
                  placeholder="Ta remarque sur cette réponse…"
                  className="flex-1 border-2 border-ink rounded-lg px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo"
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' && replyText.trim()) {
                      onReply(comment.id, replyText);
                      setReplyText('');
                      setReplying(false);
                    }
                  }}
                />
                <button
                  onClick={() => {
                    if (replyText.trim()) {
                      onReply(comment.id, replyText);
                      setReplyText('');
                      setReplying(false);
                    }
                  }}
                  className="btn-pop bg-indigo text-white px-3 text-sm"
                >
                  Envoyer
                </button>
              </div>
            )}
          </div>
        </div>
      </div>

      {comment.children?.map((child) => (
        <CommentItem
          key={child.id}
          comment={child}
          currentUserId={currentUserId}
          isQuestionAuthor={isQuestionAuthor}
          acceptedCommentId={acceptedCommentId}
          depth={depth + 1}
          onUpvote={onUpvote}
          onReply={onReply}
          onAccept={onAccept}
          onDelete={onDelete}
        />
      ))}
    </div>
  );
}
