# api-catalogo (FastAPI). Se construye desde la raíz del repo: docker build -f api/Dockerfile .
FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PORT=8080
WORKDIR /app
COPY api/requirements.txt api/requirements.txt
RUN pip install --no-cache-dir -r api/requirements.txt
COPY api/app api/app
COPY catalog catalog
RUN useradd --uid 10001 --no-create-home app
USER app
WORKDIR /app/api
# Cloud Run pasa el puerto en $PORT.
CMD exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT} --proxy-headers --forwarded-allow-ips='*'
