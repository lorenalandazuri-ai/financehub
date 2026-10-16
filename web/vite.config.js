import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// En local, Vite corre en :5173 y le pasa /api a FastAPI en :8080 (mismo origen, sin CORS).
export default defineConfig({
  plugins: [react()],
  // 127.0.0.1 y no localhost: Node 17+ resuelve localhost a ::1 y uvicorn escucha solo en IPv4.
  server: { proxy: { '/api': 'http://127.0.0.1:8080' } },
});
