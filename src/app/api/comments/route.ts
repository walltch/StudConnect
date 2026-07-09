import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

// POST /api/comments — { post_id, content, parent_comment_id? }
export async function POST(request: NextRequest) {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Non authentifié' }, { status: 401 });

  const { post_id, content, parent_comment_id } = await request.json();
  if (!post_id || !content?.trim()) {
    return NextResponse.json({ error: 'post_id et content requis' }, { status: 400 });
  }

  const { data, error } = await supabase
    .from('comments')
    .insert({
      post_id,
      content: content.trim(),
      parent_comment_id: parent_comment_id ?? null,
      author_id: user.id,
    })
    .select('*, author:profiles!author_id(id, full_name, avatar_url, reputation)')
    .single();

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ data }, { status: 201 });
}

// PATCH pour upvote d'un commentaire — voir /api/comments/[id]/upvote (route séparée ci-dessous)
