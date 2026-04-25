# syntax=docker/dockerfile:1

# ---- Build stage ---------------------------------------------------------
FROM node:20-alpine AS build

WORKDIR /app

# Install dependencies first for better layer caching.
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund

# Copy the rest of the source and produce a production bundle.
COPY . .

# VITE_API_BASE_URL is baked at build time, so we expose it as a build arg.
# In docker-compose we leave it empty so the SPA hits the same origin and
# nginx proxies /api/* to the Rails service.
ARG VITE_API_BASE_URL=""
ENV VITE_API_BASE_URL=${VITE_API_BASE_URL}

RUN npm run build

# ---- Runtime stage -------------------------------------------------------
FROM nginx:1.27-alpine AS runtime

# Replace the default nginx config with our SPA-aware one.
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the production bundle from the build stage.
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

# nginx:alpine ships with a sane default CMD; keep it.
