"""Identidad del usuario.

Detrás del balanceador, IAP ya autenticó a la persona antes de que la petición llegue al servicio y
agrega un JWT firmado en el encabezado x-goog-iap-jwt-assertion. Aquí se verifica esa firma
(no basta con leer el encabezado de correo, que es texto plano).
En local no hay IAP: se usa DEV_USER_EMAIL.
En Cloud Run, si falta IAP_AUDIENCE la petición se rechaza: nunca se cae al usuario de desarrollo.
"""

import logging
from dataclasses import dataclass

from fastapi import HTTPException, Request
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token

from .config import settings

IAP_CERTS_URL = "https://www.gstatic.com/iap/verify/public_key"
_transport = google_requests.Request()
log = logging.getLogger(__name__)


@dataclass
class User:
    email: str

    @property
    def name(self) -> str:
        # sebastian.moseres@xertica.com -> "Sebastian Moseres"
        return " ".join(
            p.capitalize() for p in self.email.split("@")[0].replace("_", ".").split(".") if p
        )


def _email_from_iap(request: Request) -> str:
    token = request.headers.get("x-goog-iap-jwt-assertion")
    if not token:
        raise HTTPException(401, "Falta la cabecera de IAP")
    try:
        claims = id_token.verify_token(
            token, _transport, audience=settings.iap_audience, certs_url=IAP_CERTS_URL
        )
    except ValueError as err:
        raise HTTPException(401, "Token de IAP inválido") from err
    return claims["email"]


def current_user(request: Request) -> User:
    if settings.iap_audience:
        email = _email_from_iap(request)
    elif settings.on_cloud_run:
        # Error de configuración del despliegue: sin audience no se puede verificar a nadie.
        log.error("IAP_AUDIENCE no está definida en Cloud Run: se rechaza la petición")
        raise HTTPException(503, "Servicio mal configurado: falta IAP_AUDIENCE")
    else:
        email = settings.dev_user_email
    email = email.lower()
    if email.rsplit("@", 1)[-1] not in settings.allowed_domains:
        raise HTTPException(403, "Cuenta fuera de la compañía")
    return User(email=email)
