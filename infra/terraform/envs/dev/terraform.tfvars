project_id = "co-xertica-financehub-dev"

# TODO: confirmar el dominio con TI (João/Davy) y que apunten el DNS a la salida lb_ip.
domain = "financehub-dev.xertica.com"

access_members = [
  "group:financehub-usuarios@xertica.com",
]

# TODO: lo entrega Davy al conectar el repo con Cloud Build.
cloudbuild_repository = ""
