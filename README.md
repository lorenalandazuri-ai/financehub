# financehub-portal

Portal interno FinanceHub: reúne en un solo lugar los tableros de Looker Studio de Finanzas por país.
El portal **no guarda datos**, solo enlaces; los permisos sobre los datos los sigue controlando Looker.

## Cómo está armado

Dos servicios de Cloud Run detrás de un balanceador HTTPS con IAP (plan de Lorena, 8 oct):

```
Usuario ──► Balanceador HTTPS + IAP (grupo financehub-usuarios@xertica.com)
              ├── /        ──► Cloud Run "financehub-web"   React (build de Vite) servido por nginx
              └── /api/*   ──► Cloud Run "api-catalogo"     FastAPI
                                 ├── /api/me        quién es el usuario (JWT de IAP verificado)
                                 └── /api/catalogo  países, módulos y tableros
                                                    (catalog.json en local, BigQuery en dev/prd)
```

El navegador llama a la API por el mismo dominio y con la misma sesión de IAP: sin CORS ni tokens
entre servicios. Los dos servicios solo aceptan tráfico del balanceador.

| Carpeta | Qué hay |
|---|---|
| `web/` | React + Vite (pantallas portadas del artefacto aprobado), `Dockerfile` y `nginx.conf`. |
| `api/` | api-catalogo en FastAPI y su `Dockerfile`. |
| `catalog/` | Catálogo de prueba con los 8 tableros de Cobranzas, esquema de la tabla de BigQuery y script de carga. |
| `infra/terraform/` | Módulo `portal`: balanceador, IAP, Cloud Run, cuentas de servicio, IAM, BigQuery, Artifact Registry y triggers de Cloud Build. Ambientes `dev`, `hml` y `prd`. |
| `docker-compose.yml` | Los dos servicios + un nginx que enruta igual que el balanceador. |
| `cloudbuild.yaml` | Construye y despliega los dos servicios. |

## Correr en local

Requisitos: Python 3.12+, Node 20+.

```bash
# api-catalogo (puerto 8080)
cd api
python3 -m venv .venv && .venv/bin/pip install -r requirements-dev.txt
DEV_USER_EMAIL=tu.nombre@xertica.com .venv/bin/uvicorn app.main:app --reload --port 8080

# Web con recarga en caliente (puerto 5173; Vite le pasa /api a :8080, como el balanceador)
cd web
npm install
npm run dev
```

Abrir http://localhost:5173.

Con Docker, igual que en GCP (dos contenedores y el enrutamiento por ruta):

```bash
DEV_USER_EMAIL=tu.nombre@xertica.com docker compose up --build
```

Abrir http://localhost:8080. Pruebas de la API: `cd api && .venv/bin/pytest -q`.

## Catálogo

- **Local:** `catalog/catalog.json`. Países y módulos + un registro por tablero (`reports`).
- **dev/prd:** la tabla `financehub.reports` en BigQuery (mismo esquema, `catalog/reports_schema.json`).
  Así Finanzas cambia o agrega un enlace sin volver a desplegar. Carga inicial:
  `./catalog/load_to_bigquery.sh xertica-financehub-dev`.
- Solo se publica lo que está en producción en Looker.
- **Pendiente:** el enlace de Cobranzas USA es el mismo de Argentina (campo `note`).

## Desplegar (cuando TI entregue los proyectos)

Quién hace qué: João crea los proyectos dev, hml y prd; Davy conecta este repo con Cloud Build en dev.

1. Crear el bucket del estado de Terraform y descomentar el `backend "gcs"` en `infra/terraform/envs/dev/main.tf`.
2. Completar los `TODO` de `terraform.tfvars` (dominio, repositorio de Cloud Build; en hml y prd, el correo de quien aprueba).
3. `terraform -chdir=infra/terraform/envs/dev init && terraform -chdir=infra/terraform/envs/dev apply`
4. Pedir a TI un registro DNS A del dominio hacia la salida `lb_ip`. El certificado se activa solo
   cuando el DNS apunta bien (puede tardar hasta ~1 hora).
5. Cargar el catálogo a BigQuery: `./catalog/load_to_bigquery.sh xertica-financehub-dev`.
6. Desplegar: dev despliega con cada push a `main`. **hml y prd despliegan solo por Cloud Build, con un tag
   `v*` y la aprobación de Lorena.**

## Forma de trabajo

- `main` está protegida: todo cambio entra por PR, con 1 aprobación de otra persona y los checks de CI en verde.
- Una rama por tarea: `feat/…`, `fix/…`, `infra/…`.
