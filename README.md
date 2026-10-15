# financehub-portal

Portal interno FinanceHub: reúne en un solo lugar los tableros de Looker Studio de Finanzas por país.
El portal **no guarda datos**, solo enlaces; los permisos sobre los datos los sigue controlando Looker.

## Cómo está armado

Un solo servicio de Cloud Run con IAP directo (sin balanceador):

```
Usuario ──► IAP (pide cuenta @xertica.com) ──► Cloud Run "financehub"
                                                ├── /            React (build de Vite)
                                                └── /api/*       FastAPI
                                                      ├── /api/me        quién es el usuario (JWT de IAP)
                                                      └── /api/catalogo  países, módulos y tableros
                                                                         (catalog.json en local, BigQuery en dev/prd)
```

| Carpeta | Qué hay |
|---|---|
| `web/` | React + Vite. Pantallas portadas del artefacto aprobado (inicio, país, buscador). |
| `api/` | FastAPI: verifica el usuario de IAP, entrega el catálogo y sirve el build de React. |
| `catalog/` | Catálogo de prueba con los 8 tableros de Cobranzas, esquema de la tabla de BigQuery y script de carga. |
| `infra/terraform/` | Módulo `portal` (APIs, Artifact Registry, cuenta de servicio, BigQuery, Cloud Run con IAP) y ambientes `dev` y `prd`. |
| `Dockerfile` | Una imagen: compila React con Node y la sirve con FastAPI. |
| `cloudbuild.yaml` | Construye, publica y despliega en Cloud Run (cuando existan los proyectos). |

## Correr en local

Requisitos: Python 3.12+, Node 20+.

```bash
# API (puerto 8080)
cd api
python3 -m venv .venv && .venv/bin/pip install -r requirements-dev.txt
DEV_USER_EMAIL=tu.nombre@xertica.com .venv/bin/uvicorn app.main:app --reload --port 8080

# Web con recarga en caliente (puerto 5173, le pasa /api a :8080)
cd web
npm install
npm run dev
```

Abrir http://localhost:5173. Para ver lo mismo que en Cloud Run: `npm run build` en `web/` y abrir http://localhost:8080.

Con Docker:

```bash
docker build -t financehub .
docker run -p 8080:8080 -e DEV_USER_EMAIL=tu.nombre@xertica.com financehub
```

Pruebas: `cd api && .venv/bin/pytest -q`.

## Catálogo

- **Local:** `catalog/catalog.json`. Países y módulos + un registro por tablero (`reports`).
- **dev/prd:** la tabla `financehub.reports` en BigQuery (mismo esquema, `catalog/reports_schema.json`).
  Así Finanzas cambia o agrega un enlace sin volver a desplegar. Carga inicial:
  `./catalog/load_to_bigquery.sh co-xertica-financehub-dev`.
- Solo se publica lo que está en producción en Looker.
- **Pendiente:** el enlace de Cobranzas USA es el mismo de Argentina (campo `note`).

## Desplegar (cuando TI entregue los proyectos)

1. Crear el bucket del estado de Terraform y descomentar el `backend "gcs"` en `infra/terraform/envs/dev/main.tf`.
2. `terraform -chdir=infra/terraform/envs/dev init && terraform -chdir=infra/terraform/envs/dev apply`
3. Cargar el catálogo a BigQuery (ver arriba).
4. `gcloud builds submit --config cloudbuild.yaml --project co-xertica-financehub-dev`
5. Cambiar `access_members` en `terraform.tfvars` por el grupo que cree TI.

## Forma de trabajo

- `main` está protegida: todo cambio entra por PR, con 1 aprobación de otra persona y los checks de CI en verde.
- Una rama por tarea: `feat/…`, `fix/…`, `infra/…`.
