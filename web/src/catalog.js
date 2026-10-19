// Convierte la respuesta de /api/catalogo en la lista de tableros que pinta el portal.

// La API solo entrega tableros en producción.
export const STATUS = {
  produccion: { label: 'En producción', icon: 'check' },
};

export const plural = (n, one, many) => `${n} ${n === 1 ? one : many}`;

// El portal solo guarda enlaces: cada tablero se abre en Looker en una pestaña nueva.
// Se fuerza la vista normal: sin /edit (o /preview), sin /embed/ y sin el /u/0/ de la cuenta.
export function viewUrl(url) {
  try {
    const u = new URL(url);
    u.pathname = u.pathname
      .replace(/\/(edit|preview)\/?$/, '')
      .replace(/^\/u\/\d+\//, '/')
      .replace(/^\/embed\//, '/');
    return u.toString();
  } catch {
    return url;
  }
}

const isPending = (url) => !url || /REEMPLAZAR|TU-INSTANCIA/i.test(url);
export const toolOf = (url) =>
  /lookerstudio\.google\.com|datastudio\.google\.com/.test(url) ? 'Looker Studio' : 'Looker';

export function normalize(catalog) {
  const modules = new Map((catalog.modules || []).map((m) => [m.id, m]));
  const order = [...modules.keys()];
  const rank = (r) => (order.includes(r.module) ? order.indexOf(r.module) : order.length);
  const reports = [];

  for (const country of catalog.countries) {
    const list = catalog.reports.filter((r) => r.country === country.id).sort((x, y) => rank(x) - rank(y));
    const seen = {};
    list.forEach((r, i) => {
      const m = modules.get(r.module) || { id: r.module || `r${i + 1}`, name: r.title || 'Reporte', icon: 'grid' };
      const same = list.filter((x) => x.module === r.module).length;
      seen[m.id] = (seen[m.id] || 0) + 1;
      reports.push({
        id: `${country.id}.${m.id}${same > 1 ? '.' + seen[m.id] : ''}`,
        country,
        module: m,
        name: r.title && modules.has(r.module) ? `${m.name} · ${r.title}` : r.title || m.name,
        tab: r.title || m.name,
        description: r.description || m.description || '',
        url: viewUrl(r.url || ''),
        pending: isPending(r.url),
        refresh: r.refresh || '',
        hojas: r.hojas || [],
        status: 'produccion',
      });
    });
  }
  return { ...catalog, reports, byId: new Map(reports.map((r) => [r.id, r])) };
}

// "Recientes" se guarda solo en el navegador de cada persona.
export const recents = {
  get() {
    try {
      return JSON.parse(localStorage.getItem('hub.recents')) ?? [];
    } catch {
      return [];
    }
  },
  push(id) {
    const next = [id, ...recents.get().filter((x) => x !== id)].slice(0, 10);
    try {
      localStorage.setItem('hub.recents', JSON.stringify(next));
    } catch {
      /* almacenamiento bloqueado */
    }
    return next;
  },
};
