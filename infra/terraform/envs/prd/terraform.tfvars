project_id = "co-xertica-financehub-prd"

# TODO: confirmar el dominio con TI (João/Davy) y que apunten el DNS a la salida lb_ip.
domain = "financehub.xertica.com"

access_members = [
  "group:financehub-usuarios@xertica.com",
]

# TODO: lo entrega Davy al conectar el repo con Cloud Build.
cloudbuild_repository = ""

# En prd se despliega solo por Cloud Build con aprobación de Lorena.
# TODO: confirmar su correo.
build_approvers = [
  "user:REEMPLAZAR-correo-de-lorena@xertica.com",
]
