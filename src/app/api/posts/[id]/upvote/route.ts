import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

// POST /api/posts/:id/upvote — bascule le vote de l'utilisateur courant
export async function POST(_req: NextRequest, { params }: { params: { id: string } }) {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Non authentifié' }, { status: 401 });

  const { data: existing } = await supabase
    .from('post_upvotes')
    .select('*')
    .eq('post_id', params.id)
    .eq('user_id', user.id)
    .maybeSingle();

  if (existing) {
    const { error } = await supabase
      .from('post_upvotes')
      .delete()
      .eq('post_id', params.id)
      .eq('user_id', user.id);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ upvoted: false });
  }

  const { error } = await supabase.from('post_upvotes').insert({ post_id: params.id, user_id: user.id });
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ upvoted: true });
}
