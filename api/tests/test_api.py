from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health():
    assert client.get("/api/health").json() == {"ok": True}


def test_me_uses_dev_user_locally():
    body = client.get("/api/me").json()
    assert body["email"].endswith("@xertica.com")


def test_catalog_has_the_8_cobranzas_dashboards():
    data = client.get("/api/catalogo").json()
    cobranzas = [r for r in data["reports"] if r["module"] == "cobranzas"]
    assert len(cobranzas) == 8
    assert {r["country"] for r in cobranzas} == {c["id"] for c in data["countries"]}
    assert all(r["status"] == "produccion" for r in cobranzas)
    assert all(r["url"].startswith("https://lookerstudio.google.com/") for r in cobranzas)


def test_internal_notes_are_not_exposed():
    data = client.get("/api/catalogo").json()
    assert all("note" not in r for r in data["reports"])


def test_catalog_only_publishes_production_dashboards(monkeypatch, tmp_path):
    import json
    from dataclasses import replace

    from app import catalog

    url = "https://lookerstudio.google.com/reporting/x"
    statuses = ["produccion", "Producción", "desarrollo", "por-iniciar", "otro", None]
    reports = [{"country": "co", "module": "cobranzas", "url": url, "status": s} for s in statuses]
    test_file = tmp_path / "catalog.json"
    test_file.write_text(json.dumps({"countries": [], "modules": [], "reports": reports}))
    monkeypatch.setattr(catalog, "settings", replace(catalog.settings, catalog_file=test_file))
    catalog.load_catalog.cache_clear()
    try:
        data = client.get("/api/catalogo").json()
    finally:
        catalog.load_catalog.cache_clear()
    assert [r["status"] for r in data["reports"]] == ["produccion", "produccion"]


def test_rejects_accounts_outside_the_company(monkeypatch):
    from dataclasses import replace

    from app import auth

    monkeypatch.setattr(
        auth, "settings", replace(auth.settings, dev_user_email="someone@gmail.com")
    )
    assert client.get("/api/me").status_code == 403


def test_cloud_run_without_iap_audience_rejects_everyone(monkeypatch):
    # Si el despliegue olvida IAP_AUDIENCE, no se puede entrar como el usuario de desarrollo.
    from dataclasses import replace

    from app import auth

    monkeypatch.setattr(
        auth, "settings", replace(auth.settings, iap_audience="", on_cloud_run=True)
    )
    assert client.get("/api/me").status_code == 503
    assert client.get("/api/catalogo").status_code == 503
    assert client.get("/api/health").status_code == 200


def test_cloud_run_with_iap_audience_requires_the_iap_token(monkeypatch):
    from dataclasses import replace

    from app import auth

    audience = "/projects/1/global/backendServices/2"
    monkeypatch.setattr(
        auth, "settings", replace(auth.settings, iap_audience=audience, on_cloud_run=True)
    )
    assert client.get("/api/me").status_code == 401
