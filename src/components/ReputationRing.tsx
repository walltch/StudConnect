'use client';

function tierColor(rep: number) {
  if (rep >= 200) return '#F5A623'; // or — expert
  if (rep >= 80) return '#FF6B4A'; // corail — confirmé
  if (rep >= 20) return '#1FA97D'; // menthe — actif
  return '#5B4FE8'; // indigo — débutant
}

export default function ReputationRing({
  reputation,
  initials,
  size = 48,
  avatarUrl,
}: {
  reputation: number;
  initials: string;
  size?: number;
  avatarUrl?: string | null;
}) {
  const radius = 45;
  const circumference = 2 * Math.PI * radius;
  const pct = Math.min(1, reputation / 300);
  const offset = circumference * (1 - pct);
  const color = tierColor(reputation);

  return (
    <div className="relative inline-flex items-center justify-center" style={{ width: size, height: size }}>
      <svg viewBox="0 0 100 100" className="absolute inset-0 -rotate-90" width={size} height={size}>
        <circle cx="50" cy="50" r={radius} fill="none" stroke="#E5E5F0" strokeWidth="8" />
        <circle
          cx="50"
          cy="50"
          r={radius}
          fill="none"
          stroke={color}
          strokeWidth="8"
          strokeLinecap="round"
          strokeDasharray={circumference}
          strokeDashoffset={offset}
          style={{ transition: 'stroke-dashoffset 0.8s ease' }}
        />
      </svg>
      <div
        className="flex items-center justify-center rounded-full bg-ink text-white font-display font-bold overflow-hidden"
        style={{ width: size * 0.74, height: size * 0.74, fontSize: size * 0.28 }}
      >
        {avatarUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={avatarUrl} alt={initials} className="w-full h-full object-cover" />
        ) : (
          initials
        )}
      </div>
    </div>
  );
}
