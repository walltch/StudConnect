'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { createClient } from '@/lib/supabase/client';

export default function OnboardingPage() {
  const supabase = createClient();
  const router = useRouter();
  const [institution, setInstitution] = useState('');
  const [filiere, setFiliere] = useState('');
  const [annee, setAnnee] = useState('L1');
  const [skillInput, setSkillInput] = useState('');
  const [skills, setSkills] = useState<string[]>([]);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    (async () => {
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (!user) return router.push('/login');

      const { data: profile } = await supabase
        .from('profiles')
        .select('institution, filiere, annee_etude, skills')
        .eq('id', user.id)
        .maybeSingle();

      if (profile?.institution) {
        // Profil déjà complété : pas besoin de repasser par l'onboarding
        router.push('/');
        return;
      }

      if (profile) {
        setInstitution(profile.institution ?? '');
        setFiliere(profile.filiere ?? '');
        setAnnee(profile.annee_etude || 'L1');
        setSkills(profile.skills ?? []);
      }
    })();
  }, []);

  function addSkill() {
    const v = skillInput.trim();
    if (v && !skills.includes(v)) setSkills([...skills, v]);
    setSkillInput('');
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError('');
    const res = await fetch('/api/profile', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ institution, filiere, annee_etude: annee, skills }),
    });
    setSaving(false);
    if (!res.ok) {
      const { error } = await res.json();
      setError(error || 'Une erreur est survenue');
      return;
    }
    router.push('/');
    router.refresh();
  }

  return (
    <div className="max-w-lg mx-auto">
      <h1 className="font-display text-3xl font-extrabold mb-2">Bienvenue ! Un dernier détail 🎓</h1>
      <p className="text-ink/60 mb-6">
        Ces informations personnalisent ton fil d'actualité et t'aident à recevoir de l'aide adaptée à ton niveau.
      </p>

      <form onSubmit={handleSubmit} className="card-pop p-6 space-y-5">
        <div>
          <label className="text-xs font-bold uppercase tracking-wide text-ink/60">Établissement</label>
          <input
            required
            value={institution}
            onChange={(e) => setInstitution(e.target.value)}
            className="w-full mt-1 border-2 border-ink rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-indigo"
            placeholder="Université Paris-Saclay"
          />
        </div>

        <div>
          <label className="text-xs font-bold uppercase tracking-wide text-ink/60">Filière</label>
          <input
            required
            value={filiere}
            onChange={(e) => setFiliere(e.target.value)}
            className="w-full mt-1 border-2 border-ink rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-indigo"
            placeholder="Informatique — Génie Logiciel"
          />
        </div>

        <div>
          <label className="text-xs font-bold uppercase tracking-wide text-ink/60">Année d'étude</label>
          <select
            value={annee}
            onChange={(e) => setAnnee(e.target.value)}
            className="w-full mt-1 border-2 border-ink rounded-lg px-3 py-2 bg-white focus:outline-none focus:ring-2 focus:ring-indigo"
          >
            {['L1', 'L2', 'L3', 'M1', 'M2', 'Doctorat'].map((a) => (
              <option key={a} value={a}>
                {a}
              </option>
            ))}
          </select>
        </div>

        <div>
          <label className="text-xs font-bold uppercase tracking-wide text-ink/60">
            Modules / technologies maîtrisées ou recherchées
          </label>
          <div className="flex gap-2 mt-1">
            <input
              value={skillInput}
              onChange={(e) => setSkillInput(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  e.preventDefault();
                  addSkill();
                }
              }}
              className="flex-1 border-2 border-ink rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-indigo"
              placeholder="React, Algèbre linéaire, SQL…"
            />
            <button type="button" onClick={addSkill} className="btn-pop bg-mint text-white px-4">
              Ajouter
            </button>
          </div>
          {skills.length > 0 && (
            <div className="flex flex-wrap gap-2 mt-3">
              {skills.map((s) => (
                <span
                  key={s}
                  onClick={() => setSkills(skills.filter((x) => x !== s))}
                  className="tag-pill bg-indigo-100 text-indigo-700 cursor-pointer"
                  title="Cliquer pour retirer"
                >
                  {s} ✕
                </span>
              ))}
            </div>
          )}
        </div>

        {error && <p className="text-sm font-semibold text-coral-600 bg-coral-100 rounded-lg px-3 py-2">{error}</p>}

        <button disabled={saving} type="submit" className="btn-pop bg-indigo text-white w-full py-2.5">
          {saving ? 'Enregistrement…' : 'Accéder à StudConnect'}
        </button>
      </form>
    </div>
  );
}
