import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

// PUT /api/comments/:id — édition par l'auteur
export async function PUT(request: NextRequest, { params }: { params: { id: string } }) {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Non authentifié' }, { status: 401 });

  const { content } = await request.json();
  if (!content?.trim()) return NextResponse.json({ error: 'content requis' }, { status: 400 });

  const { data, error } = await supabase
    .from('comments')
    .update({ content: content.trim() })
    .eq('id', params.id)
    .eq('author_id', user.id)
    .select()
    .single();

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  if (!data) return NextResponse.json({ error: 'Non autorisé ou introuvable' }, { status: 403 });
  return NextResponse.json({ data });
}

// DELETE /api/comments/:id
export async function DELETE(_req: NextRequest, { params }: { params: { id: string } }) {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Non authentifié' }, { status: 401 });

  const { error, count } = await supabase
    .from('comments')
    .delete({ count: 'exact' })
    .eq('id', params.id)
    .eq('author_id', user.id);

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  if (!count) return NextResponse.json({ error: 'Non autorisé ou introuvable' }, { status: 403 });
  return NextResponse.json({ success: true });
}
