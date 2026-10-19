"""Catálogo de tableros.

El portal no guarda datos: solo enlaces a Looker Studio. Para el MVP todo el catálogo (países,
módulos y tableros) vive en catalog/catalog.json, que va dentro de la imagen: cambiar o agregar un
enlace es un PR y un despliegue.
Solo se publican los tableros en producción; los que están en desarrollo o por iniciar se quedan
en el archivo pero no salen de la API.
"""

import json
import logging
import unicodedata
from functools import lru_cache

from .config import settings

PUBLISHED_STATUS = "produccion"
KNOWN_STATUSES = {PUBLISHED_STATUS, "desarrollo", "por-iniciar"}
log = logging.getLogger(__name__)
PUBLIC_FIELDS = ("country", "module", "url", "status", "title", "description", "refresh")


def _status(report: dict) -> str:
    # "Producción" y "produccion" son lo mismo: sin tildes, en minúsculas.
    raw = unicodedata.normalize("NFKD", str(report.get("status") or ""))
    status = "".join(c for c in raw if not unicodedata.combining(c)).strip().lower()
    if status not in KNOWN_STATUSES:
        log.warning(
            "Tablero con estado desconocido %r: no se publica (%s)",
            report.get("status"),
            report.get("url"),
        )
    return status


def _public(report: dict) -> dict:
    # Quita los campos internos (p. ej. "note") y los vacíos.
    return {k: report[k] for k in PUBLIC_FIELDS if report.get(k)}


@lru_cache
def load_catalog() -> dict:
    # El archivo no cambia mientras corre el servicio: se lee una sola vez.
    data = json.loads(settings.catalog_file.read_text(encoding="utf-8"))
    reports = [
        {**_public(r), "status": PUBLISHED_STATUS}
        for r in data["reports"]
        if _status(r) == PUBLISHED_STATUS
    ]
    return {**data, "reports": reports}
