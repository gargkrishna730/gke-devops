# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Production stage
FROM nginx:1.24-alpine
SHELL ["/bin/ash", "-o", "pipefail", "-c"]
RUN apk add --no-cache curl=8.5.0-r0 gettext=0.21.1-r1

# Create non-root user
RUN addgroup -g 1001 -S nginx_user && \
    adduser -S nginx_user -u 1001

# Copy built app
COPY --from=builder /app/build /usr/share/nginx/html

# Copy nginx config
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf

# Create directories with proper permissions
RUN mkdir -p /var/log/nginx /var/cache/nginx /var/run/nginx && \
    chown -R nginx_user:nginx_user /var/log/nginx /var/cache/nginx /var/run/nginx /usr/share/nginx/html && \
    chmod -R 755 /var/log/nginx /var/cache/nginx /var/run/nginx

# Copy entrypoint script
COPY entrypoint.sh /app-entrypoint.sh
RUN chmod +x /app-entrypoint.sh

# Switch to non-root user
USER nginx_user

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/ || exit 1

ENTRYPOINT ["/app-entrypoint.sh"]

