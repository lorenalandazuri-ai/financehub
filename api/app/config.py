"""Configuración por variables de entorno. Los valores por defecto sirven para correr en local."""

import os
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


@dataclass(frozen=True)
class Settings:
    # file: lee catalog/catalog.json. bigquery: lee los tableros de BQ_REPORTS_TABLE.
    catalog_source: str = os.getenv("CATALOG_SOURCE", "file")
    catalog_file: Path = Path(os.getenv("CATALOG_FILE", ROOT / "catalog" / "catalog.json"))
    bq_reports_table: str = os.getenv("BQ_REPORTS_TABLE", "")  # proyecto.dataset.tabla

    # En Cloud Run: /projects/NUMERO_PROYECTO/locations/REGION/services/NOMBRE_SERVICIO
    # Vacío = modo local, sin IAP: se usa DEV_USER_EMAIL.
    iap_audience: str = os.getenv("IAP_AUDIENCE", "")
    dev_user_email: str = os.getenv("DEV_USER_EMAIL", "dev@xertica.com")
    allowed_domains: tuple[str, ...] = field(
        default_factory=lambda: tuple(os.getenv("ALLOWED_DOMAINS", "xertica.com").split(","))
    )

    # Carpeta con el build de React (web/dist). Si no existe, solo se sirve la API.
    static_dir: Path = Path(os.getenv("STATIC_DIR", ROOT / "web" / "dist"))


settings = Settings()
