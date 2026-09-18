FROM node:20-alpine AS build
WORKDIR /app
COPY backend_bloqueo_vehicular/package*.json ./
RUN npm install --omit=dev

FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/node_modules ./node_modules
COPY backend_bloqueo_vehicular/ ./
EXPOSE 8080
CMD ["node", "server.js"]