"""FinanceHub: un solo servicio. /api/* es la API del catálogo y / sirve el build de React."""

from typing import Annotated

from fastapi import Depends, FastAPI
from fastapi.staticfiles import StaticFiles

from .auth import User, current_user
from .catalog import load_catalog
from .config import settings

CurrentUser = Annotated[User, Depends(current_user)]

app = FastAPI(title="FinanceHub", docs_url="/api/docs", openapi_url="/api/openapi.json")


@app.get("/api/health")
def health() -> dict:
    return {"ok": True}


@app.get("/api/me")
def me(user: CurrentUser) -> dict:
    return {"email": user.email, "name": user.name}


@app.get("/api/catalogo")
def catalogo(user: CurrentUser) -> dict:
    # Fase 2: filtrar los tableros según los grupos de Google del usuario.
    return load_catalog()


# Va al final para que no tape las rutas /api.
if settings.static_dir.is_dir():
    app.mount("/", StaticFiles(directory=settings.static_dir, html=True), name="web")
