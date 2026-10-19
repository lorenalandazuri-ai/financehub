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
                                                    (catalog/catalog.json, dentro de la imagen)
```

El navegador llama a la API por el mismo dominio y con la misma sesión de IAP: sin CORS ni tokens
entre servicios. Los dos servicios solo aceptan tráfico del balanceador.

La API verifica la firma del JWT de IAP con `IAP_AUDIENCE` (la pone Terraform). Sin esa variable solo
funciona en local, con `DEV_USER_EMAIL`: en Cloud Run (`K_SERVICE` definida) rechaza toda petición con 503.

| Carpeta | Qué hay |
|---|---|
| `web/` | React + Vite (pantallas portadas del artefacto aprobado), `Dockerfile` y `nginx.conf`. |
| `api/` | api-catalogo en FastAPI y su `Dockerfile`. |
| `catalog/` | `catalog.json`: países, módulos y los 8 tableros de Cobranzas. |
| `infra/terraform/` | Módulo `portal`: balanceador, IAP, Cloud Run, cuentas de servicio, IAM, Artifact Registry y triggers de Cloud Build. Ambientes `dev`, `hml` y `prd`. |
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

Para el MVP todo el catálogo vive en `catalog/catalog.json` y va dentro de la imagen de api-catalogo
(sin base de datos). **Cambiar o agregar un enlace es un PR y un despliegue.**

- `app`, `modules` y `countries`: textos del portal, módulos y países.
- `reports`: un registro por tablero.

| Campo | Obligatorio | Qué es |
|---|---|---|
| `country` | sí | ID del país (`latam`, `co`, `mx`, `br`, `ar`, `pe`, `ec-cl`, `us`) |
| `module` | sí | ID del módulo (`cobranzas`…) |
| `url` | sí | Enlace de vista del tablero en Looker Studio |
| `status` | sí | `produccion`, `desarrollo` o `por-iniciar` |
| `title` | no | Título si un país tiene más de un tablero del mismo módulo |
| `description` | no | Descripción propia; si falta se usa la del módulo |
| `refresh` | no | Frecuencia de actualización (Diario, Semanal…) |
| `note` | no | Nota interna: la API no la entrega |

- **La API solo entrega los tableros con `status: "produccion"`.** Los que están en `desarrollo` o
  `por-iniciar` pueden quedar en el archivo, pero no salen en el portal.
- **Pendiente:** el enlace de Cobranzas USA es el mismo de Argentina (campo `note`).

## Desplegar (cuando TI entregue los proyectos)

Quién hace qué: João crea los proyectos dev, hml y prd; Davy conecta este repo con Cloud Build en dev.

1. Crear el bucket del estado de Terraform y descomentar el `backend "gcs"` en `infra/terraform/envs/dev/main.tf`.
2. Completar los `TODO` de `terraform.tfvars` (dominio, repositorio de Cloud Build; en hml y prd, el correo de quien aprueba).
3. `terraform -chdir=infra/terraform/envs/dev init && terraform -chdir=infra/terraform/envs/dev apply`
4. Pedir a TI un registro DNS A del dominio hacia la salida `lb_ip`. El certificado se activa solo
   cuando el DNS apunta bien (puede tardar hasta ~1 hora).
5. Desplegar: dev despliega con cada push a `main`. **hml y prd despliegan solo por Cloud Build, con un tag
   `v*` y la aprobación de Lorena.**

## Forma de trabajo

- `main` está protegida: todo cambio entra por PR, con 1 aprobación de otra persona y los checks de CI en verde.
- Una rama por tarea: `feat/…`, `fix/…`, `infra/…`.
