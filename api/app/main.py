"""api-catalogo: la API del portal FinanceHub.

El balanceador enruta /api/* a este servicio y todo lo demás al servicio web, en el mismo dominio
y detrás de la misma sesión de IAP, así que no hace falta CORS ni tokens entre servicios.
"""

from typing import Annotated

from fastapi import Depends, FastAPI

from .auth import User, current_user
from .catalog import load_catalog

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
