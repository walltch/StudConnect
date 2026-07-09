const PALETTE = [
  { bg: 'bg-indigo-100', text: 'text-indigo-700', dot: 'bg-indigo-500' },
  { bg: 'bg-coral-100', text: 'text-coral-600', dot: 'bg-coral-500' },
  { bg: 'bg-mint-100', text: 'text-mint-600', dot: 'bg-mint-500' },
  { bg: 'bg-amber-100', text: 'text-amber-500', dot: 'bg-amber-500' },
];

export function tagColor(tag: string) {
  let hash = 0;
  for (let i = 0; i < tag.length; i++) hash = tag.charCodeAt(i) + ((hash << 5) - hash);
  return PALETTE[Math.abs(hash) % PALETTE.length];
}

export default function TagPill({ tag, onClick }: { tag: string; onClick?: () => void }) {
  const c = tagColor(tag);
  return (
    <button
      onClick={onClick}
      className={`tag-pill ${c.bg} ${c.text} ${onClick ? 'cursor-pointer hover:-translate-y-0.5 transition-transform' : 'cursor-default'}`}
    >
      <span className={`w-1.5 h-1.5 rounded-full ${c.dot} mr-1.5`} />
      {tag}
    </button>
  );
}
