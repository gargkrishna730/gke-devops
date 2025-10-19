# hadolint ignore=DL3006
FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./

# hadolint ignore=DL3060
RUN npm install

COPY . .

# Build React application
RUN npm run build

# --- Production stage with nginx ---
FROM nginx:1.24-alpine

# Set shell with pipefail for error handling
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

# Install curl for health checks with pinned version
RUN apk add --no-cache curl=8.5.0-r0

# Create non-root user
RUN addgroup -g 1001 -S nginx_user && \
    adduser -S nginx_user -u 1001

# Copy built app from builder
COPY --from=builder /app/build /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf

# Create necessary directories with proper permissions
RUN mkdir -p /var/log/nginx && \
    mkdir -p /var/cache/nginx && \
    mkdir -p /var/run/nginx && \
    mkdir -p /etc/nginx/conf.d && \
    chown -R nginx_user:nginx_user /var/log/nginx && \
    chown -R nginx_user:nginx_user /var/cache/nginx && \
    chown -R nginx_user:nginx_user /var/run/nginx && \
    chown -R nginx_user:nginx_user /etc/nginx/conf.d && \
    chown -R nginx_user:nginx_user /usr/share/nginx/html && \
    chmod -R 755 /var/log/nginx && \
    chmod -R 755 /var/cache/nginx && \
    chmod -R 755 /var/run/nginx

# Switch to non-root user
USER nginx_user

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
