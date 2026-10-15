import { useEffect, useRef, useState } from 'react';
import { Flags, Icon } from './brand.jsx';
import { plural, STATUS } from './catalog.js';

const norm = (s) => s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();

// Primero los países que coinciden, después los tableros. Ctrl/Cmd K enfoca el buscador.
export default function Search({ catalog, onOpen }) {
  const [query, setQuery] = useState('');
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState(0);
  const box = useRef(null);
  const input = useRef(null);
  const list = useRef(null);

  const terms = norm(query).split(/\s+/).filter(Boolean);
  const match = (s) => terms.every((t) => norm(s).includes(t));
  const countries = catalog.countries.filter((c) => match(`${c.name} ${c.code} ${c.subtitle || ''}`));
  const reports = terms.length
    ? catalog.reports.filter((r) =>
        match(`${r.name} ${r.module.name} ${r.country.name} ${r.country.code} ${(r.module.keywords || []).join(' ')}`),
      )
    : [];
  const results = [...countries, ...reports].slice(0, 12);

  useEffect(() => {
    const onDoc = (e) => !box.current?.contains(e.target) && setOpen(false);
    const onKey = (e) => {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault();
        input.current?.focus();
        input.current?.select();
      }
    };
    document.addEventListener('click', onDoc);
    document.addEventListener('keydown', onKey);
    return () => {
      document.removeEventListener('click', onDoc);
      document.removeEventListener('keydown', onKey);
    };
  }, []);

  const close = () => {
    setOpen(false);
    setQuery('');
  };
  const openActive = () => list.current?.querySelectorAll('a')[active]?.click();

  const onKeyDown = (e) => {
    if (!open) return;
    if (e.key === 'ArrowDown') { setActive((a) => Math.min(a + 1, results.length - 1)); e.preventDefault(); }
    if (e.key === 'ArrowUp') { setActive((a) => Math.max(a - 1, 0)); e.preventDefault(); }
    if (e.key === 'Enter') openActive();
    if (e.key === 'Escape') { setOpen(false); input.current?.blur(); }
  };

  return (
    <div className="search" ref={box}>
      <Icon name="search" className="icon search-icon" />
      <input
        ref={input}
        type="search"
        placeholder="Busca un tablero o un país"
        autoComplete="off"
        aria-label="Buscar tableros o países"
        value={query}
        onChange={(e) => { setQuery(e.target.value); setActive(0); setOpen(Boolean(e.target.value.trim())); }}
        onKeyDown={onKeyDown}
      />
      <button
        className="search-btn"
        type="button"
        title="Buscar (Ctrl K)"
        onClick={() => (open && query.trim() ? openActive() : (setOpen(true), input.current?.focus()))}
      >
        Buscar
      </button>
      {open && (
        <ul className="search-results" role="listbox" ref={list} onClick={close}>
          {results.length === 0 && (
            <li className="empty">No encontramos tableros ni países con ese nombre. Prueba con el tema o el país.</li>
          )}
          {results.map((x, i) =>
            x.module ? (
              <li key={x.id}>
                <a
                  href={x.pending ? `#${x.country.id}` : x.url}
                  {...(x.pending ? {} : { target: '_blank', rel: 'noopener' })}
                  className={i === active ? 'active' : ''}
                  onClick={() => onOpen(x)}
                >
                  <Icon name={x.module.icon} />
                  <span className="grow">
                    {x.name}
                    <small>{x.country.name} · {STATUS[x.status].label}{x.pending ? ' · enlace pendiente' : ''}</small>
                  </span>
                  <Flags country={x.country} size="sm" />
                  <span className="tag">{x.country.code}</span>
                </a>
              </li>
            ) : (
              <li key={x.id}>
                <a href={`#${x.id}`} className={i === active ? 'active' : ''}>
                  <Flags country={x} />
                  <span className="grow">
                    {x.name}
                    <small>País · {plural(catalog.reports.filter((r) => r.country.id === x.id).length, 'reporte', 'reportes')}</small>
                  </span>
                  <span className="tag">{x.code}</span>
                </a>
              </li>
            ),
          )}
        </ul>
      )}
    </div>
  );
}
