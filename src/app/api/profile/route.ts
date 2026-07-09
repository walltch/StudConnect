import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

// GET /api/profile — profil de l'utilisateur connecté
export async function GET() {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Non authentifié' }, { status: 401 });

  let { data, error } = await supabase.from('profiles').select('*').eq('id', user.id).maybeSingle();
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  // Filet de sécurité : si le trigger on_auth_user_created n'a pas tourné
  // (ex. compte créé avant la pose du trigger), on crée le profil à la volée.
  if (!data) {
    const { data: created, error: createError } = await supabase
      .from('profiles')
      .insert({
        id: user.id,
        email: user.email ?? '',
        full_name: (user.user_metadata?.full_name as string) || user.email?.split('@')[0] || 'Étudiant',
      })
      .select()
      .single();
    if (createError) return NextResponse.json({ error: createError.message }, { status: 500 });
    data = created;
  }

  // Contributions + score
  const { data: posts } = await supabase.from('posts').select('id').eq('author_id', user.id);
  const { data: comments } = await supabase.from('comments').select('id').eq('author_id', user.id);
  const { data: solved } = await supabase.from('posts').select('id').eq('author_id', user.id).eq('is_solved', true);

  return NextResponse.json({
    data: {
      ...data,
      stats: {
        questions_posted: posts?.length ?? 0,
        answers_posted: comments?.length ?? 0,
        questions_solved: solved?.length ?? 0,
      },
    },
  });
}

// PUT /api/profile — édition (onboarding + dashboard)
export async function PUT(request: NextRequest) {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: 'Non authentifié' }, { status: 401 });

  const body = await request.json();
  const { full_name, institution, filiere, annee_etude, skills, avatar_url } = body;

  const { data, error } = await supabase
    .from('profiles')
    .upsert(
      {
        id: user.id,
        email: user.email ?? '',
        ...(full_name !== undefined && { full_name }),
        ...(institution !== undefined && { institution }),
        ...(filiere !== undefined && { filiere }),
        ...(annee_etude !== undefined && { annee_etude }),
        ...(skills !== undefined && { skills }),
        ...(avatar_url !== undefined && { avatar_url }),
      },
      { onConflict: 'id' }
    )
    .select()
    .single();

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ data });
}
