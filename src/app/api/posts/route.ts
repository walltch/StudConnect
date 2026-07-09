import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export const dynamic = 'force-dynamic';
export const revalidate = 0;

// GET /api/posts?search=...&tag=...&solved=true|false
export async function GET(request: NextRequest) {
  const supabase = createClient();
  const { searchParams } = new URL(request.url);
  const search = searchParams.get('search');
  const tag = searchParams.get('tag');
  const solved = searchParams.get('solved');

  let query = supabase
    .from('posts_with_counts')
    .select('*, author:profiles!author_id(id, full_name, avatar_url, reputation, filiere)')
    .order('created_at', { ascending: false });

  if (search) {
    query = query.or(`title.ilike.%${search}%,content.ilike.%${search}%`);
  }
  if (tag) {
    query = query.contains('tags', [tag]);
  }
  if (solved === 'true') query = query.eq('is_solved', true);
  if (solved === 'false') query = query.eq('is_solved', false);

  const { data, error } = await query;

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ data });
}

// POST /api/posts — crée une nouvelle question
export async function POST(request: NextRequest) {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return NextResponse.json({ error: 'Non authentifié' }, { status: 401 });

  const body = await request.json();
  const { title, content, tags } = body;

  if (!title?.trim() || !content?.trim()) {
    return NextResponse.json({ error: 'Titre et contenu requis' }, { status: 400 });
  }

  const { data, error } = await supabase
    .from('posts')
    .insert({
      title: title.trim(),
      content,
      tags: Array.isArray(tags) ? tags.slice(0, 6) : [],
      author_id: user.id,
    })
    .select()
    .single();

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ data }, { status: 201 });
}
