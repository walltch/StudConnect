import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

// POST /api/posts/:id/accept — { comment_id } — réservé à l'auteur de la question
export async function POST(request: NextRequest, { params }: { params: { id: string } }) {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Non authentifié' }, { status: 401 });

  const { comment_id } = await request.json();
  if (!comment_id) return NextResponse.json({ error: 'comment_id requis' }, { status: 400 });

  const { data, error } = await supabase
    .from('posts')
    .update({ accepted_comment_id: comment_id, is_solved: true })
    .eq('id', params.id)
    .eq('author_id', user.id)
    .select()
    .single();

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  if (!data) return NextResponse.json({ error: "Seul l'auteur de la question peut valider une réponse" }, { status: 403 });
  return NextResponse.json({ data });
}
