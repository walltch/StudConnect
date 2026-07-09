'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import ReputationRing from '@/components/ReputationRing';
import { Award, MessageCircleQuestion, MessagesSquare, CheckCircle2, Save } from 'lucide-react';

type ProfileData = {
  id: string;
  full_name: string;
  institution: string;
  filiere: string;
  annee_etude: string;
  skills: string[];
  reputation: number;
  avatar_url: string | null;
  stats: { questions_posted: number; answers_posted: number; questions_solved: number };
};

export default function ProfilePage() {
  const router = useRouter();
  const [profile, setProfile] = useState<ProfileData | null>(null);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState(false);
  const [form, setForm] = useState({ full_name: '', institution: '', filiere: '', annee_etude: '' });
  const [skillInput, setSkillInput] = useState('');
  const [skills, setSkills] = useState<string[]>([]);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    (async () => {
      const res = await fetch('/api/profile');
      if (res.status === 401) {
        router.push('/login');
        return;
      }
      const { data } = await res.json();
      setProfile(data);
      setForm({
        full_name: data.full_name,
        institution: data.institution,
        filiere: data.filiere,
        annee_etude: data.annee_etude,
      });
      setSkills(data.skills ?? []);
      setLoading(false);
    })();
  }, []);

  async function handleSave() {
    setSaving(true);
    const res = await fetch('/api/profile', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ ...form, skills }),
    });
    setSaving(false);
    if (res.ok) {
      const { data } = await res.json();
      setProfile((p) => (p ? { ...p, ...data } : p));
      setEditing(false);
    }
  }

  if (loading || !profile) return <div className="card-pop h-40 animate-pulse bg-ink/5" />;

  const tier =
    profile.reputation >= 200 ? 'Expert reconnu' : profile.reputation >= 80 ? 'Contributeur confirmé' : profile.reputation >= 20 ? 'Membre actif' : 'Nouveau membre';

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      <div className="card-pop p-6 flex items-center gap-4 flex-wrap">
        <ReputationRing reputation={profile.reputation} initials={profile.full_name.slice(0, 1).toUpperCase()} avatarUrl={profile.avatar_url} size={72} />
        <div className="flex-1 min-w-[160px]">
          <h1 className="font-display text-2xl font-extrabold">{profile.full_name}</h1>
          <p className="text-ink/60 text-sm">{profile.filiere} · {profile.annee_etude} · {profile.institution}</p>
          <span className="tag-pill bg-amber-100 text-amber-500 mt-2">
            <Award size={12} className="mr-1" /> {tier} — {profile.reputation} pts
          </span>
        </div>
        <button onClick={() => setEditing((e) => !e)} className="btn-pop bg-white px-4 py-1.5 text-sm">
          {editing ? 'Annuler' : 'Modifier mon profil'}
        </button>
      </div>

      <div className="grid grid-cols-3 gap-3">
        <div className="card-pop p-4 text-center">
          <MessageCircleQuestion className="mx-auto text-indigo mb-1" size={22} />
          <p className="font-display text-2xl font-extrabold">{profile.stats.questions_posted}</p>
          <p className="text-xs text-ink/60 font-semibold">Questions posées</p>
        </div>
        <div className="card-pop p-4 text-center">
          <MessagesSquare className="mx-auto text-coral mb-1" size={22} />
          <p className="font-display text-2xl font-extrabold">{profile.stats.answers_posted}</p>
          <p className="text-xs text-ink/60 font-semibold">Réponses données</p>
        </div>
        <div className="card-pop p-4 text-center">
          <CheckCircle2 className="mx-auto text-mint-600 mb-1" size={22} />
          <p className="font-display text-2xl font-extrabold">{profile.stats.questions_solved}</p>
          <p className="text-xs text-ink/60 font-semibold">Résolues</p>
        </div>
      </div>

      {editing && (
        <div className="card-pop p-6 space-y-4">
          <h2 className="font-display text-lg font-extrabold">Modifier mes informations</h2>
          {(['full_name', 'institution', 'filiere', 'annee_etude'] as const).map((field) => (
            <div key={field}>
              <label className="text-xs font-bold uppercase tracking-wide text-ink/60">
                {{ full_name: 'Nom complet', institution: 'Établissement', filiere: 'Filière', annee_etude: "Année d'étude" }[field]}
              </label>
              <input
                value={form[field]}
                onChange={(e) => setForm({ ...form, [field]: e.target.value })}
                className="w-full mt-1 border-2 border-ink rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-indigo"
              />
            </div>
          ))}

          <div>
            <label className="text-xs font-bold uppercase tracking-wide text-ink/60">Compétences</label>
            <div className="flex gap-2 mt-1">
              <input
                value={skillInput}
                onChange={(e) => setSkillInput(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    e.preventDefault();
                    if (skillInput.trim()) setSkills([...skills, skillInput.trim()]);
                    setSkillInput('');
                  }
                }}
                className="flex-1 border-2 border-ink rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-indigo"
              />
              <button
                type="button"
                onClick={() => {
                  if (skillInput.trim()) setSkills([...skills, skillInput.trim()]);
                  setSkillInput('');
                }}
                className="btn-pop bg-mint text-white px-4"
              >
                Ajouter
              </button>
            </div>
            <div className="flex flex-wrap gap-2 mt-3">
              {skills.map((s) => (
                <span key={s} onClick={() => setSkills(skills.filter((x) => x !== s))} className="tag-pill bg-indigo-100 text-indigo-700 cursor-pointer">
                  {s} ✕
                </span>
              ))}
            </div>
          </div>

          <button disabled={saving} onClick={handleSave} className="btn-pop bg-indigo text-white px-5 py-2 text-sm flex items-center gap-1.5">
            <Save size={16} /> {saving ? 'Enregistrement…' : 'Enregistrer les modifications'}
          </button>
        </div>
      )}

      {!editing && skills.length > 0 && (
        <div className="card-pop p-6">
          <h2 className="font-display text-lg font-extrabold mb-3">Compétences</h2>
          <div className="flex flex-wrap gap-2">
            {skills.map((s) => (
              <span key={s} className="tag-pill bg-indigo-100 text-indigo-700">
                {s}
              </span>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
