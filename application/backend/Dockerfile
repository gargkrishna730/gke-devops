# hadolint ignore=DL3006
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies with npm install for reproducibility
# hadolint ignore=DL3060
RUN npm install --only=production && npm cache clean --force

# --- Multi-stage build: Security scanning stage ---
FROM builder AS security-scan

# Set shell with pipefail for error handling
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

RUN apk add --no-cache \
    curl=8.5.0-r0 \
    git=2.42.1-r0 \
    && curl -sSfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

COPY . .

# Run Trivy scan (optional - for CI/CD pipelines)
# RUN trivy fs --severity HIGH,CRITICAL .

# --- Final production stage ---
FROM node:18-alpine

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3001

# Create non-root user with explicit UID/GID
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Set working directory
WORKDIR /app

# Copy node_modules from builder stage
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules

# Copy application source code
COPY --chown=nodejs:nodejs . .

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3001/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})" || exit 1

# Start application
CMD ["node", "src/index.js"]
