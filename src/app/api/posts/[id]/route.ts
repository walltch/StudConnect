import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export const dynamic = 'force-dynamic';
export const revalidate = 0;

// GET /api/posts/:id — question + réponses (threads imbriqués)
export async function GET(_req: NextRequest, { params }: { params: { id: string } }) {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { data: post, error } = await supabase
    .from('posts_with_counts')
    .select('*, author:profiles!author_id(id, full_name, avatar_url, reputation, filiere, institution)')
    .eq('id', params.id)
    .single();

  if (error || !post) return NextResponse.json({ error: 'Question introuvable' }, { status: 404 });

  const { data: comments, error: cErr } = await supabase
    .from('comments')
    .select('*, author:profiles!author_id(id, full_name, avatar_url, reputation)')
    .eq('post_id', params.id)
    .order('created_at', { ascending: true });

  if (cErr) return NextResponse.json({ error: cErr.message }, { status: 500 });

  // Compteurs d'upvotes + upvote de l'utilisateur courant
  const { data: upvotes } = await supabase
    .from('comment_upvotes')
    .select('comment_id, user_id')
    .in('comment_id', (comments ?? []).map((c) => c.id));

  const enriched = (comments ?? []).map((c) => ({
    ...c,
    upvote_count: (upvotes ?? []).filter((u) => u.comment_id === c.id).length,
    has_upvoted: user ? (upvotes ?? []).some((u) => u.comment_id === c.id && u.user_id === user.id) : false,
  }));

  const { data: postUpvotes } = await supabase.from('post_upvotes').select('user_id').eq('post_id', params.id);
  const userHasUpvotedPost = user ? (postUpvotes ?? []).some((u) => u.user_id === user.id) : false;

  return NextResponse.json({ data: { ...post, has_upvoted: userHasUpvotedPost, comments: enriched } });
}

// PUT /api/posts/:id — édition par l'auteur uniquement (RLS protège aussi côté DB)
export async function PUT(request: NextRequest, { params }: { params: { id: string } }) {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Non authentifié' }, { status: 401 });

  const body = await request.json();
  const { title, content, tags, is_solved } = body;

  const { data, error } = await supabase
    .from('posts')
    .update({
      ...(title !== undefined && { title }),
      ...(content !== undefined && { content }),
      ...(tags !== undefined && { tags }),
      ...(is_solved !== undefined && { is_solved }),
      updated_at: new Date().toISOString(),
    })
    .eq('id', params.id)
    .eq('author_id', user.id)
    .select()
    .single();

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  if (!data) return NextResponse.json({ error: 'Non autorisé ou introuvable' }, { status: 403 });
  return NextResponse.json({ data });
}

// DELETE /api/posts/:id — suppression par l'auteur (clôture définitive)
export async function DELETE(_req: NextRequest, { params }: { params: { id: string } }) {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Non authentifié' }, { status: 401 });

  const { error, count } = await supabase
    .from('posts')
    .delete({ count: 'exact' })
    .eq('id', params.id)
    .eq('author_id', user.id);

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  if (!count) return NextResponse.json({ error: 'Non autorisé ou introuvable' }, { status: 403 });
  return NextResponse.json({ success: true });
}
