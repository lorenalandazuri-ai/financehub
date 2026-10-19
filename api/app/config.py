"""Configuración por variables de entorno. Los valores por defecto sirven para correr en local."""

import os
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


@dataclass(frozen=True)
class Settings:
    # Catálogo de tableros (MVP: solo este archivo, sin base de datos).
    catalog_file: Path = Path(os.getenv("CATALOG_FILE", ROOT / "catalog" / "catalog.json"))

    # Detrás del balanceador: /projects/NUMERO_PROYECTO/global/backendServices/ID_BACKEND_API
    # Vacío = modo local, sin IAP: se usa DEV_USER_EMAIL. En Cloud Run nunca puede estar vacío.
    iap_audience: str = os.getenv("IAP_AUDIENCE", "")
    dev_user_email: str = os.getenv("DEV_USER_EMAIL", "dev@xertica.com")
    # Cloud Run siempre define K_SERVICE (nombre del servicio). Sirve para saber que no es local.
    on_cloud_run: bool = bool(os.getenv("K_SERVICE"))
    allowed_domains: tuple[str, ...] = field(
        default_factory=lambda: tuple(os.getenv("ALLOWED_DOMAINS", "xertica.com").split(","))
    )


settings = Settings()
