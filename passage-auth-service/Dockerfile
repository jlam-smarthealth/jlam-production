# JLAM Passage Authentication Service
# Lightweight Node.js service for biometric authentication

FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy source code
COPY index.js ./
COPY .env.example ./

FROM node:18-alpine AS production

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S passageauth -u 1001

# Set working directory
WORKDIR /app

# Copy built application
COPY --from=builder --chown=passageauth:nodejs /app .

# Install security updates
RUN apk --no-cache upgrade

# Switch to non-root user
USER passageauth

# Expose port
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://127.0.0.1:3001/health', res => res.statusCode === 200 ? process.exit(0) : process.exit(1)).on('error', () => process.exit(1))"

# Environment variables
ENV NODE_ENV=production
ENV PORT=3001

# Labels for container metadata
LABEL \
    org.opencontainers.image.title="JLAM Passage Auth Service" \
    org.opencontainers.image.description="Biometric authentication service using Passage by 1Password" \
    org.opencontainers.image.version="1.0.0" \
    org.opencontainers.image.vendor="Stichting Je Leefstijl Als Medicijn" \
    org.opencontainers.image.author="JLAM Development Team" \
    jlam.service.name="passage-auth" \
    jlam.service.type="authentication" \
    jlam.service.tier="security" \
    jlam.environment="development"

# Start the service
CMD ["node", "index.js"]