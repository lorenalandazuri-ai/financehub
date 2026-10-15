// Iconos lineales, banderas y figuras de marca (portados del artefacto aprobado).

const ICONS = {
  receipt: '<rect x="5" y="3" width="14" height="18"/><line x1="8.5" y1="8" x2="15.5" y2="8"/><line x1="8.5" y1="12" x2="15.5" y2="12"/><line x1="8.5" y1="16" x2="12.5" y2="16"/>',
  trendDown: '<polyline points="3,7 10,14 14,10 21,17"/><polyline points="15,17 21,17 21,11"/>',
  apps: '<rect x="4" y="4" width="4" height="4"/><rect x="10" y="4" width="4" height="4"/><rect x="16" y="4" width="4" height="4"/><rect x="4" y="10" width="4" height="4"/><rect x="10" y="10" width="4" height="4"/><rect x="16" y="10" width="4" height="4"/><rect x="4" y="16" width="4" height="4"/><rect x="10" y="16" width="4" height="4"/><rect x="16" y="16" width="4" height="4"/>',
  grid: '<rect x="4" y="4" width="7" height="7"/><rect x="13" y="4" width="7" height="7"/><rect x="4" y="13" width="7" height="7"/><rect x="13" y="13" width="7" height="7"/>',
  external: '<path d="M14 4h6v6"/><line x1="20" y1="4" x2="11" y2="13"/><path d="M18 14v6H4V6h6"/>',
  arrow: '<line x1="5" y1="12" x2="19" y2="12"/><polyline points="13,6 19,12 13,18"/>',
  back: '<line x1="19" y1="12" x2="5" y2="12"/><polyline points="11,6 5,12 11,18"/>',
  progress: '<rect x="3" y="8" width="18" height="8"/><line x1="7" y1="12" x2="12.5" y2="12"/>',
  idle: '<rect x="5" y="5" width="14" height="14" stroke-dasharray="3 2.6"/>',
  lock: '<rect x="5" y="11" width="14" height="10"/><path d="M8 11V7.5a4 4 0 0 1 8 0V11"/>',
  check: '<polyline points="5,12.5 10,17 19,7"/>',
  search: '<circle cx="11" cy="11" r="6.5"/><line x1="16" y1="16" x2="21" y2="21"/>',
};

export function Icon({ name, className = 'icon' }) {
  return (
    <svg
      className={className}
      viewBox="0 0 24 24"
      aria-hidden="true"
      dangerouslySetInnerHTML={{ __html: ICONS[name] || ICONS.grid }}
    />
  );
}

// Banderas en SVG 3:2. Windows no muestra emojis de bandera.
const stripesH = (cs) => cs.map((c, i) => `<rect y="${(20 / cs.length) * i}" width="30" height="${20 / cs.length + 0.05}" fill="${c}"/>`).join('');
const stripesV = (cs) => cs.map((c, i) => `<rect x="${(30 / cs.length) * i}" width="${30 / cs.length + 0.05}" height="20" fill="${c}"/>`).join('');
const FLAGS = {
  co: stripesH(['#FCD116', '#FCD116', '#003893', '#CE1126']),
  ec: stripesH(['#FFDD00', '#FFDD00', '#034EA2', '#ED1C24']) + '<ellipse cx="15" cy="10" rx="2.3" ry="2.9" fill="#8C6A2B"/>',
  mx: stripesV(['#006847', '#FFFFFF', '#CE1126']) + '<circle cx="15" cy="10" r="2.4" fill="#8C5A2B"/>',
  pe: stripesV(['#D91023', '#FFFFFF', '#D91023']),
  ar: stripesH(['#74ACDF', '#FFFFFF', '#74ACDF']) + '<circle cx="15" cy="10" r="2.3" fill="#F6B40E"/>',
  br: '<rect width="30" height="20" fill="#009C3B"/><polygon points="15,2.5 27,10 15,17.5 3,10" fill="#FFDF00"/><circle cx="15" cy="10" r="4.4" fill="#002776"/><path d="M10.8 9.3 Q15 7.9 19.2 10.7" stroke="#FFFFFF" stroke-width="0.9" fill="none"/>',
  cl: '<rect width="30" height="10" fill="#FFFFFF"/><rect y="10" width="30" height="10" fill="#D52B1E"/><rect width="10" height="10" fill="#0039A6"/><polygon points="5,2.3 5.7,4.3 7.7,4.3 6.1,5.5 6.7,7.5 5,6.3 3.3,7.5 3.9,5.5 2.3,4.3 4.3,4.3" fill="#FFFFFF"/>',
  us: stripesH(Array.from({ length: 13 }, (_, i) => (i % 2 ? '#FFFFFF' : '#B22234'))) + '<rect width="12" height="10.77" fill="#3C3B6E"/>',
};

// Un país puede tener varias banderas (EC-CL).
export function Flags({ country, size = '' }) {
  const ids = (country.flags || [country.id]).filter((id) => FLAGS[id]);
  if (!ids.length) return null;
  const svgs = ids.map((id) => (
    <svg
      key={id}
      className={`flag ${size}`}
      viewBox="0 0 30 20"
      preserveAspectRatio="none"
      role="img"
      aria-label={`Bandera de ${country.name}`}
      dangerouslySetInnerHTML={{ __html: FLAGS[id] }}
    />
  ));
  return ids.length > 1 ? <span className="flags">{svgs}</span> : svgs[0];
}

// Cada país lleva un par de colores aprobado y su tercer color de intersección (efecto serigrafía).
const PAIRS = {
  co: { a: '#C45BAA', b: '#1899AF', mix: '#5A4A96' },
  mx: { a: '#3D63AC', b: '#DE5B48', mix: '#5A4A96' },
  br: { a: '#2E8B5A', b: '#DE5B48', mix: '#2A1A12' },
  pe: { a: '#1899AF', b: '#FAF338', mix: '#2E9A3A' },
  'ec-cl': { a: '#1899AF', b: '#C45BAA', mix: '#5A4A96' },
  ar: { a: '#FAF338', b: '#1899AF', mix: '#2E9A3A' },
  us: { a: '#DE5B48', b: '#2E8B5A', mix: '#2A1A12' },
  latam: { a: '#C45BAA', b: '#1899AF', mix: '#5A4A96' },
};
const FALLBACK = Object.values(PAIRS);
export const pairOf = (c, index = 0) => c.colors || PAIRS[c.id] || FALLBACK[index % FALLBACK.length];

// Mosaico aprobado: diagonal a 45°, cuadrícula al 25/50/75 %.
function Mosaico() {
  return (
    <svg viewBox="0 0 100 100" preserveAspectRatio="xMidYMid slice" aria-hidden="true">
      <rect x="0" y="0" width="25.2" height="25.2" fill="#5A4A96" />
      <polygon points="25,0 100,0 75,25.2 25,25.2" fill="#1899AF" />
      <polygon points="100,0 100,75.2 74.8,75.2 74.8,25" fill="#2E8B5A" />
      <polygon points="0,25 25.2,25 25.2,75 0,100" fill="#C45BAA" />
      <polygon points="25,25 75,25 25,75" fill="#E9E6DC" />
      <polygon points="75,25 75,75 25,75" fill="#FAF338" />
      <polygon points="25,74.8 75,74.8 75,100 0,100" fill="#DE5B48" />
      <rect x="74.8" y="74.8" width="25.2" height="25.2" fill="#2A1A12" />
    </svg>
  );
}

export function Figure({ country }) {
  if (country.id === 'latam') return <Mosaico />;
  const p = pairOf(country);
  return (
    <svg viewBox="0 0 100 100" preserveAspectRatio="xMaxYMin slice" aria-hidden="true" shapeRendering="crispEdges">
      <rect x="0" y="0" width="64" height="64" fill={p.a} />
      <rect x="36" y="36" width="64" height="64" fill={p.b} />
      <rect x="36" y="36" width="28" height="28" fill={p.mix} />
    </svg>
  );
}
