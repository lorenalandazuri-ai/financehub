import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// En local, Vite corre en :5173 y le pasa /api a FastAPI en :8080 (mismo origen, sin CORS).
export default defineConfig({
  plugins: [react()],
  server: { proxy: { '/api': 'http://localhost:8080' } },
});
