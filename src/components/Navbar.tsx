'use client';

import Link from 'next/link';
import { useEffect, useState } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import { createClient } from '@/lib/supabase/client';
import ReputationRing from './ReputationRing';
import { PlusCircle, LogOut, Home } from 'lucide-react';

export default function Navbar() {
  const supabase = createClient();
  const router = useRouter();
  const pathname = usePathname();
  const [profile, setProfile] = useState<{ full_name: string; reputation: number; avatar_url: string | null } | null>(
    null
  );
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let active = true;
    async function load() {
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (!user) {
        if (active) {
          setProfile(null);
          setLoading(false);
        }
        return;
      }
      const { data } = await supabase
        .from('profiles')
        .select('full_name, reputation, avatar_url')
        .eq('id', user.id)
        .maybeSingle();
      if (active) {
        setProfile(data);
        setLoading(false);
      }
    }
    load();
    const { data: sub } = supabase.auth.onAuthStateChange(() => load());
    return () => {
      active = false;
      sub.subscription.unsubscribe();
    };
  }, [pathname]);

  async function handleLogout() {
    await supabase.auth.signOut();
    router.push('/login');
    router.refresh();
  }

  return (
    <header className="sticky top-0 z-50 border-b-2 border-ink bg-paper/90 backdrop-blur">
      <div className="max-w-5xl mx-auto px-4 h-16 flex items-center justify-between">
        <Link href="/" className="flex items-center gap-2 font-display font-extrabold text-xl">
          <span className="w-8 h-8 rounded-lg bg-indigo grid place-items-center text-white border-2 border-ink shadow-pop-sm">
            S
          </span>
          Stud<span className="text-indigo">Connect</span>
        </Link>

        <nav className="hidden sm:flex items-center gap-1">
          <Link
            href="/"
            className={`px-3 py-1.5 rounded-lg text-sm font-semibold flex items-center gap-1.5 ${pathname === '/' ? 'bg-ink text-white' : 'hover:bg-ink/5'}`}
          >
            <Home size={16} /> Fil d'actualité
          </Link>
          <Link
            href="/questions"
            className={`px-3 py-1.5 rounded-lg text-sm font-semibold ${pathname?.startsWith('/questions') ? 'bg-ink text-white' : 'hover:bg-ink/5'}`}
          >
            Questions
          </Link>
        </nav>

        <div className="flex items-center gap-3">
          {!loading && profile && (
            <Link
              href="/questions/create"
              className="btn-pop bg-coral text-white px-3 py-1.5 text-sm flex items-center gap-1.5"
            >
              <PlusCircle size={16} /> Demander de l'aide
            </Link>
          )}

          {!loading && profile && (
            <Link href="/profile" className="flex items-center gap-2">
              <ReputationRing
                reputation={profile.reputation}
                initials={profile.full_name?.slice(0, 1)?.toUpperCase() || '?'}
                avatarUrl={profile.avatar_url}
                size={40}
              />
            </Link>
          )}

          {!loading && profile && (
            <button onClick={handleLogout} className="p-2 rounded-lg hover:bg-ink/5" title="Se déconnecter">
              <LogOut size={18} />
            </button>
          )}

          {!loading && !profile && (
            <Link href="/login" className="btn-pop bg-indigo text-white px-4 py-1.5 text-sm">
              Se connecter
            </Link>
          )}
        </div>
      </div>
    </header>
  );
}
