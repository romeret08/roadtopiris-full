# Multi-stage build para Road to Piris
FROM node:18-alpine AS builder

WORKDIR /app

# Copiar package.json desde roadtopiris-web
COPY roadtopiris-web/package*.json ./
RUN npm ci --only=production

# Copiar código fuente de roadtopiris-web
COPY roadtopiris-web/ .

# Construir la aplicación
RUN npm run build

# Etapa de producción
FROM node:18-alpine AS production

WORKDIR /app

# Instalar PM2 globalmente
RUN npm install -g pm2

# Crear directorio de logs
RUN mkdir -p /app/logs

# Copiar desde builder
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/build ./build
COPY --from=builder /app/public ./public
COPY --from=builder /app/node_modules ./node_modules

# Copiar archivos de configuración
COPY ecosystem.config.js ./

# Crear usuario no root para seguridad
RUN addgroup -g 1001 -S nodejs
RUN adduser -S roadtopiris -u 1001
RUN chown -R roadtopiris:nodejs /app
USER roadtopiris

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/api/health || exit 1

# Usar PM2 para mejor manejo en producción
CMD ["pm2-runtime", "start", "ecosystem.config.js"]
