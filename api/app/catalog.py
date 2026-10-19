"""Catálogo de tableros.

El portal no guarda datos: solo enlaces a Looker Studio. Para el MVP todo el catálogo (países,
módulos y tableros) vive en catalog/catalog.json, que va dentro de la imagen: cambiar o agregar un
enlace es un PR y un despliegue.
Solo se publican los tableros en producción; los que están en desarrollo o por iniciar se quedan
en el archivo pero no salen de la API.
"""

import json
from functools import lru_cache

from .config import settings

PUBLISHED_STATUS = "produccion"
PUBLIC_FIELDS = ("country", "module", "url", "status", "title", "description", "refresh")


def _public(report: dict) -> dict:
    # Quita los campos internos (p. ej. "note") y los vacíos.
    return {k: report[k] for k in PUBLIC_FIELDS if report.get(k)}


@lru_cache
def load_catalog() -> dict:
    # El archivo no cambia mientras corre el servicio: se lee una sola vez.
    data = json.loads(settings.catalog_file.read_text(encoding="utf-8"))
    reports = [_public(r) for r in data["reports"] if r.get("status") == PUBLISHED_STATUS]
    return {**data, "reports": reports}
