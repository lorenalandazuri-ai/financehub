# Balanceador HTTPS externo con IAP delante de los dos servicios.
# Enruta por ruta en el mismo dominio: /api/* a api-catalogo y todo lo demás al servicio web.

resource "google_compute_global_address" "lb" {
  project    = var.project_id
  name       = "financehub-lb-ip"
  depends_on = [google_project_service.apis]
}

# Los NEG apuntan al servicio por nombre (no por recurso) para evitar un ciclo:
# api-catalogo necesita el ID de su backend para verificar el JWT de IAP.
resource "google_compute_region_network_endpoint_group" "web" {
  project               = var.project_id
  name                  = "${local.web_service}-neg"
  region                = var.region
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = local.web_service
  }
  depends_on = [google_project_service.apis]
}

resource "google_compute_region_network_endpoint_group" "api" {
  project               = var.project_id
  name                  = "${local.api_service}-neg"
  region                = var.region
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = local.api_service
  }
  depends_on = [google_project_service.apis]
}

resource "google_compute_backend_service" "web" {
  project               = var.project_id
  name                  = "${local.web_service}-backend"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTPS"

  backend {
    group = google_compute_region_network_endpoint_group.web.id
  }

  iap {
    enabled = true
  }
}

resource "google_compute_backend_service" "api" {
  project               = var.project_id
  name                  = "${local.api_service}-backend"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTPS"

  backend {
    group = google_compute_region_network_endpoint_group.api.id
  }

  iap {
    enabled = true
  }
}

resource "google_compute_url_map" "https" {
  project         = var.project_id
  name            = "financehub-lb"
  default_service = google_compute_backend_service.web.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "portal"
  }

  path_matcher {
    name            = "portal"
    default_service = google_compute_backend_service.web.id
    path_rule {
      paths   = ["/api", "/api/*"]
      service = google_compute_backend_service.api.id
    }
  }
}

# Certificado administrado por Google. Se activa cuando el DNS del dominio apunta a la IP.
resource "google_compute_managed_ssl_certificate" "portal" {
  project = var.project_id
  name    = "financehub-cert"
  managed {
    domains = [var.domain]
  }
}

resource "google_compute_target_https_proxy" "portal" {
  project          = var.project_id
  name             = "financehub-https-proxy"
  url_map          = google_compute_url_map.https.id
  ssl_certificates = [google_compute_managed_ssl_certificate.portal.id]
}

resource "google_compute_global_forwarding_rule" "https" {
  project               = var.project_id
  name                  = "financehub-https"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address            = google_compute_global_address.lb.id
  port_range            = "443"
  target                = google_compute_target_https_proxy.portal.id
}

# http:// redirige a https://
resource "google_compute_url_map" "http_redirect" {
  project = var.project_id
  name    = "financehub-http-redirect"
  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }
}

resource "google_compute_target_http_proxy" "redirect" {
  project = var.project_id
  name    = "financehub-http-proxy"
  url_map = google_compute_url_map.http_redirect.id
}

resource "google_compute_global_forwarding_rule" "http" {
  project               = var.project_id
  name                  = "financehub-http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address            = google_compute_global_address.lb.id
  port_range            = "80"
  target                = google_compute_target_http_proxy.redirect.id
}

# ---------- Quién entra ----------
# Aplica a los dos backends del proyecto. La API además rechaza correos fuera de @xertica.com.
resource "google_iap_web_iam_member" "access" {
  for_each = toset(var.access_members)
  project  = var.project_id
  role     = "roles/iap.httpsResourceAccessor"
  member   = each.value
}
