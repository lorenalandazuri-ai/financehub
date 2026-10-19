project_id = "xertica-financehub-hml"

# TODO: confirmar el dominio con TI (João/Davy) y que apunten el DNS a la salida lb_ip.
domain = "financehub-hml.xertica.com"

# TODO: confirmar quién entra a hml (usuarios de Finanzas que prueban antes de prd).
access_members = [
  "group:financehub-usuarios@xertica.com",
]

# TODO: lo entrega Davy al conectar el repo con Cloud Build.
cloudbuild_repository = ""

# Como en prd: se despliega solo con aprobación de Lorena.
# TODO: confirmar su correo.
build_approvers = [
  "user:REEMPLAZAR-correo-de-lorena@xertica.com",
]
