#!/usr/bin/env bash
# Carga los tableros de catalog.json a la tabla de BigQuery que crea Terraform.
# Uso: ./catalog/load_to_bigquery.sh xertica-financehub-dev
set -euo pipefail
PROJECT="${1:?Falta el proyecto}"
DIR="$(cd "$(dirname "$0")" && pwd)"
python3 -c 'import json,sys; [print(json.dumps(r, ensure_ascii=False)) for r in json.load(open(sys.argv[1]))["reports"]]' \
  "$DIR/catalog.json" > /tmp/financehub_reports.jsonl
bq load --project_id="$PROJECT" --replace --source_format=NEWLINE_DELIMITED_JSON \
  "$PROJECT:financehub.reports" /tmp/financehub_reports.jsonl "$DIR/reports_schema.json"
echo "Cargados $(wc -l < /tmp/financehub_reports.jsonl) tableros en $PROJECT:financehub.reports"
