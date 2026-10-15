"""Catálogo de tableros.

El portal no guarda datos: solo enlaces a Looker Studio. Países y módulos vienen del archivo;
los tableros vienen del archivo (local) o de una tabla de BigQuery (dev/prd), con el mismo
esquema (catalog/reports_schema.json). Así Finanzas cambia un enlace sin volver a desplegar.
"""

import json
import time
from functools import lru_cache

from .config import settings

STATUSES = {"produccion", "desarrollo", "por-iniciar"}
CACHE_SECONDS = 300
PUBLIC_FIELDS = ("country", "module", "url", "status", "title", "description", "refresh")

_cache: dict = {"at": 0.0, "data": None}


@lru_cache
def _base() -> dict:
    return json.loads(settings.catalog_file.read_text(encoding="utf-8"))


def _reports_from_bigquery() -> list[dict]:
    from google.cloud import bigquery  # import diferido: en local no hace falta

    client = bigquery.Client()
    query = f"SELECT * FROM `{settings.bq_reports_table}`"
    return [dict(row) for row in client.query(query).result()]


def _clean(report: dict) -> dict:
    out = {k: report[k] for k in PUBLIC_FIELDS if report.get(k)}
    if out.get("status") not in STATUSES:
        out["status"] = "por-iniciar"
    return out


def load_catalog() -> dict:
    if _cache["data"] and time.time() - _cache["at"] < CACHE_SECONDS:
        return _cache["data"]
    base = _base()
    raw = _reports_from_bigquery() if settings.catalog_source == "bigquery" else base["reports"]
    data = {**base, "reports": [_clean(r) for r in raw]}
    _cache.update(at=time.time(), data=data)
    return data
