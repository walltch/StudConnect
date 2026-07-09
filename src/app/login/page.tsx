'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { createClient } from '@/lib/supabase/client';
import { GraduationCap, Mail, Lock } from 'lucide-react';

export default function LoginPage() {
  const supabase = createClient();
  const router = useRouter();
  const [mode, setMode] = useState<'signin' | 'signup'>('signin');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [fullName, setFullName] = useState('');
  const [error, setError] = useState('');
  const [info, setInfo] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setInfo('');
    setLoading(true);

    if (mode === 'signup') {
      const { error } = await supabase.auth.signUp({
        email,
        password,
        options: { data: { full_name: fullName } },
      });
      setLoading(false);
      if (error) return setError(error.message);
      setInfo('Compte créé ! Vérifie ta boîte mail académique pour confirmer ton adresse (code OTP), puis connecte-toi.');
      setMode('signin');
      return;
    }

    const { error, data: signInData } = await supabase.auth.signInWithPassword({ email, password });
    if (error) {
      setLoading(false);
      return setError(error.message);
    }

    // On ne renvoie vers l'onboarding que si le profil n'a pas encore été complété
    const { data: profile } = await supabase
      .from('profiles')
      .select('institution')
      .eq('id', signInData.user.id)
      .maybeSingle();

    setLoading(false);
    const needsOnboarding = !profile?.institution;
    router.push(needsOnboarding ? '/onboarding' : '/');
    router.refresh();
  }

  return (
    <div className="max-w-md mx-auto mt-8">
      <div className="text-center mb-8">
        <div className="w-14 h-14 mx-auto rounded-2xl bg-indigo grid place-items-center border-2 border-ink shadow-pop text-white mb-4">
          <GraduationCap size={28} />
        </div>
        <h1 className="font-display text-3xl font-extrabold">
          {mode === 'signin' ? 'Content de te revoir' : 'Rejoins la mémoire collective'}
        </h1>
        <p className="text-ink/60 mt-1">Connecte-toi avec ton adresse académique</p>
      </div>

      <div className="card-pop p-6">
        <div className="flex mb-6 rounded-xl border-2 border-ink overflow-hidden">
          <button
            onClick={() => setMode('signin')}
            className={`flex-1 py-2 text-sm font-bold ${mode === 'signin' ? 'bg-indigo text-white' : 'bg-white'}`}
          >
            Connexion
          </button>
          <button
            onClick={() => setMode('signup')}
            className={`flex-1 py-2 text-sm font-bold border-l-2 border-ink ${mode === 'signup' ? 'bg-coral text-white' : 'bg-white'}`}
          >
            Inscription
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          {mode === 'signup' && (
            <div>
              <label className="text-xs font-bold uppercase tracking-wide text-ink/60">Nom complet</label>
              <input
                required
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                className="w-full mt-1 border-2 border-ink rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-indigo"
                placeholder="Alice Martin"
              />
            </div>
          )}

          <div>
            <label className="text-xs font-bold uppercase tracking-wide text-ink/60 flex items-center gap-1">
              <Mail size={12} /> Adresse académique
            </label>
            <input
              required
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full mt-1 border-2 border-ink rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-indigo"
              placeholder="prenom.nom@universite.fr"
            />
          </div>

          <div>
            <label className="text-xs font-bold uppercase tracking-wide text-ink/60 flex items-center gap-1">
              <Lock size={12} /> Mot de passe
            </label>
            <input
              required
              minLength={6}
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full mt-1 border-2 border-ink rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-indigo"
              placeholder="••••••••"
            />
          </div>

          {error && <p className="text-sm font-semibold text-coral-600 bg-coral-100 rounded-lg px-3 py-2">{error}</p>}
          {info && <p className="text-sm font-semibold text-mint-600 bg-mint-100 rounded-lg px-3 py-2">{info}</p>}

          <button disabled={loading} type="submit" className="btn-pop bg-indigo text-white w-full py-2.5">
            {loading ? 'Chargement…' : mode === 'signin' ? 'Se connecter' : "S'inscrire"}
          </button>
        </form>
      </div>

      <p className="text-xs text-center text-ink/50 mt-4">
        La vérification par OTP est gérée automatiquement par l'email de confirmation Supabase.
      </p>
    </div>
  );
}
