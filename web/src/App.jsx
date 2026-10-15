import { useCallback, useEffect, useState } from 'react';
import { Figure, Flags, Icon, pairOf } from './brand.jsx';
import { normalize, plural, recents, STATUS, toolOf } from './catalog.js';
import Search from './Search.jsx';

// No hay pantalla de ingreso: IAP pide la cuenta de Google antes de que cargue la página.
export default function App() {
  const [user, setUser] = useState(null);
  const [catalog, setCatalog] = useState(null);
  const [error, setError] = useState('');
  const [hash, setHash] = useState(() => decodeURIComponent(location.hash.slice(1)));
  const [recentIds, setRecentIds] = useState(recents.get);

  useEffect(() => {
    Promise.all([fetch('/api/me'), fetch('/api/catalogo', { cache: 'no-store' })])
      .then(async ([meRes, catRes]) => {
        if (meRes.status === 403) throw new Error('forbidden');
        if (!meRes.ok || !catRes.ok) throw new Error(`HTTP ${meRes.ok ? catRes.status : meRes.status}`);
        setUser(await meRes.json());
        setCatalog(normalize(await catRes.json()));
      })
      .catch((err) => setError(err.message));
  }, []);

  useEffect(() => {
    const onHash = () => {
      setHash(decodeURIComponent(location.hash.slice(1)));
      window.scrollTo(0, 0);
    };
    window.addEventListener('hashchange', onHash);
    return () => window.removeEventListener('hashchange', onHash);
  }, []);

  // Guarda en "recientes" cada tablero que se abre.
  const onOpen = useCallback((r) => !r.pending && setRecentIds(recents.push(r.id)), []);

  if (error) return <ErrorState error={error} />;
  if (!catalog) return <div className="state"><p>Cargando tableros…</p></div>;

  const country = catalog.countries.find((c) => c.id === hash);
  return (
    <>
      <Topbar user={user} catalog={catalog} onOpen={onOpen} />
      <main>
        {country ? (
          <CountryPage catalog={catalog} country={country} onOpen={onOpen} />
        ) : (
          <Home catalog={catalog} user={user} recentIds={recentIds} onOpen={onOpen} />
        )}
      </main>
    </>
  );
}

function ErrorState({ error }) {
  const forbidden = error === 'forbidden';
  return (
    <div className="state">
      <h1>{forbidden ? 'Sin acceso' : 'No se pudo cargar el portal'}</h1>
      <p>
        {forbidden
          ? 'Esta cuenta no pertenece a la compañía. Ingresa con tu correo @xertica.com.'
          : `No se pudo cargar el catálogo de tableros (${error}).`}
      </p>
      {!forbidden && (
        <button className="btn dark" type="button" onClick={() => location.reload()}>
          Intentar de nuevo
        </button>
      )}
    </div>
  );
}

function Topbar({ user, catalog, onOpen }) {
  const initials = (user.name || user.email).split(' ').map((p) => p[0]).slice(0, 2).join('').toUpperCase();
  return (
    <header className="topbar">
      <a className="brand" href="#inicio" aria-label="FinanceHub, inicio">
        <img className="brand-logo" src="/assets/logo-xertica.png" alt="Xertica.ai" width="660" height="121" />
        <span className="product">FinanceHub</span>
      </a>
      <Search catalog={catalog} onOpen={onOpen} />
      <div className="user">
        <div className="user-text">
          <span className="user-name">{user.name}</span>
          <span className="user-email">{user.email}</span>
        </div>
        <span className="avatar" aria-hidden="true">{initials}</span>
      </div>
    </header>
  );
}

export function ReportLink({ report, className, children, onOpen }) {
  return (
    <a className={className} href={report.url} target="_blank" rel="noopener" onClick={() => onOpen(report)}>
      {children}
    </a>
  );
}

const reportsOf = (catalog, id) => catalog.reports.filter((r) => r.country.id === id);

function Home({ catalog, user, recentIds, onOpen }) {
  const first = (user.name || '').split(' ')[0];
  const recent = recentIds.map((id) => catalog.byId.get(id)).filter((r) => r && !r.pending).slice(0, 6);
  return (
    <>
      <section className="hero">
        <div className="hero-text">
          <span className="eyebrow">{catalog.app?.org || 'Finanzas y Operaciones'}</span>
          <h1>
            {first ? `Hola, ${first}.` : 'Hola.'}
            <br />
            <span className="light">¿Qué país quieres revisar?</span>
          </h1>
          <p>
            Elige un país para ver sus reportes. Hay {plural(catalog.reports.length, 'reporte', 'reportes')} en{' '}
            {plural(catalog.countries.length, 'país', 'países')}, y los permisos los sigue controlando Looker.
          </p>
        </div>
        <div className="hero-figure">
          <img src="/assets/figura-cuadrados.png" alt="" />
        </div>
      </section>
      <section className="section crema">
        <div className="section-head"><h2>Países</h2></div>
        <div className="country-grid">
          {catalog.countries.map((c, i) => (
            <CountryCard key={c.id} country={c} index={i} reports={reportsOf(catalog, c.id)} />
          ))}
        </div>
      </section>
      {recent.length > 0 && (
        <section className="section">
          <div className="section-head"><h2>Abiertos recientemente</h2></div>
          <div className="pills">
            {recent.map((r) => (
              <ReportLink key={r.id} report={r} className="pill-card" onOpen={onOpen}>
                <Icon name={r.module.icon} />
                <span>{r.name}</span>
                <Flags country={r.country} size="sm" />
                <span className="tag">{r.country.code}</span>
              </ReportLink>
            ))}
          </div>
        </section>
      )}
    </>
  );
}

function CountryCard({ country: c, index, reports }) {
  const pend = reports.filter((r) => r.pending).length;
  return (
    <a className="country-card" href={`#${c.id}`} style={{ '--accent': pairOf(c, index).a }}>
      <span className="country-fig"><Figure country={c} /></span>
      <span className={`country-code ${c.code.length > 3 ? 'long' : ''}`}>{c.code}</span>
      <span className="country-name"><Flags country={c} />{c.name}</span>
      <span className="accent-line" />
      <span className="country-meta">
        {c.subtitle ? `${c.subtitle} · ` : ''}
        {plural(reports.length, 'reporte', 'reportes')}
        {pend ? ` · ${plural(pend, 'pendiente', 'pendientes')}` : ''}
      </span>
      <span className="country-go">Ver reportes <Icon name="arrow" /></span>
    </a>
  );
}

function CountryPage({ catalog, country: c, onOpen }) {
  const list = reportsOf(catalog, c.id);
  const p = pairOf(c);
  const modules = new Set(list.map((r) => r.module.id)).size;
  const who = catalog.app?.access;
  return (
    <>
      <section className="country-hero">
        <div className="country-hero-text">
          <div className="crumbs"><a href="#inicio"><Icon name="back" />Países</a></div>
          <span className="eyebrow">{c.code}{c.subtitle ? ` · ${c.subtitle}` : ''}</span>
          <div className="country-title"><Flags country={c} size="lg" /><h1>{c.name}</h1></div>
          <p>{plural(list.length, 'reporte', 'reportes')} en {plural(modules, 'módulo', 'módulos')}.</p>
          <div className="switch">
            <span>Cambiar de país</span>
            <div className="seg">
              {catalog.countries.map((o) => (
                <a
                  key={o.id}
                  className={`seg-opt ${o.id === c.id ? 'current' : ''}`}
                  href={`#${o.id}`}
                  title={o.name}
                  aria-current={o.id === c.id ? 'page' : undefined}
                >
                  <Icon name="check" className="icon check" />
                  <Flags country={o} size="sm" />
                  {o.code}
                </a>
              ))}
            </div>
          </div>
        </div>
        <div className="country-hero-fig"><Figure country={c} /></div>
      </section>
      <section className="section crema">
        {list.length ? (
          <div className="report-grid">
            {list.map((r, i) => (
              <ReportCard key={r.id} report={r} color={i % 2 ? p.b : p.a} onOpen={onOpen} />
            ))}
          </div>
        ) : (
          <p>{c.name} aún no tiene reportes.</p>
        )}
        {who?.name && (
          // Looker no le avisa al portal si alguien no tiene permiso, así que el aviso queda siempre visible.
          <div className="access-note" role="note">
            <Icon name="lock" />
            <div className="access-text">
              <b>¿Te aparece que no tienes permiso?</b>
              <p>
                Pide acceso a <b>{who.name}</b>
                {who.email && <> (<a href={`mailto:${who.email}`}>{who.email}</a>)</>} indicando el país y el
                tablero que necesitas. Cuando te lo den en Looker, vuelve a abrir el tablero.
              </p>
            </div>
          </div>
        )}
        <p className="note">
          Cada reporte se abre en Looker en una pestaña nueva, con tu misma cuenta de Google. Si un reporte dice
          "Pendiente", todavía no tiene su enlace cargado.
        </p>
      </section>
    </>
  );
}

function ReportCard({ report: r, color, onOpen }) {
  return (
    <article className="report-card" style={{ '--accent': color }}>
      {r.tab !== r.module.name && <span className="eyebrow-sm">{r.module.name}</span>}
      <div className="head">
        <Icon name={r.module.icon} />
        <h3>{r.tab}</h3>
        <span className={`status ${r.status}`}>
          <Icon name={STATUS[r.status].icon} />
          {STATUS[r.status].label}
        </span>
      </div>
      <span className="accent-line" />
      {r.description && <p>{r.description}</p>}
      {r.hojas.length > 0 && (
        <ul className="hojas" aria-label="Hojas del reporte">
          {r.hojas.map((h) => <li key={h}>{h}</li>)}
        </ul>
      )}
      <div className="report-foot">
        <span className="report-meta">
          {r.pending ? 'Sin enlace todavía' : toolOf(r.url)}
          {r.refresh && !r.pending ? ` · ${r.refresh}` : ''}
        </span>
        {r.pending ? (
          <span className="btn small pending">Pendiente</span>
        ) : (
          <ReportLink report={r} className="btn small dark" onOpen={onOpen}>
            Abrir en Looker <Icon name="external" />
          </ReportLink>
        )}
      </div>
    </article>
  );
}
