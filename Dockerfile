# Una sola imagen: la etapa 1 compila React, la etapa 2 es FastAPI sirviendo la API y el build.

FROM node:22-alpine AS web
WORKDIR /web
COPY web/package.json web/package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY web/ ./
RUN npm run build

FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PORT=8080 STATIC_DIR=/app/web/dist
WORKDIR /app
COPY api/requirements.txt api/requirements.txt
RUN pip install --no-cache-dir -r api/requirements.txt
COPY api/app api/app
COPY catalog catalog
COPY --from=web /web/dist web/dist
RUN useradd --uid 10001 --no-create-home app
USER app
WORKDIR /app/api
# Cloud Run pasa el puerto en $PORT.
CMD exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT} --proxy-headers --forwarded-allow-ips='*'
