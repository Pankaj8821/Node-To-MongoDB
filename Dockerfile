# ---------- Build Stage ----------
FROM node:18-alpine AS builder
# Set working directory
WORKDIR /app
# Copy package files
COPY package*.json ./
# Install all dependencies (including dev) for build
RUN npm install
# Copy app source
COPY . .

# ---------- Production Stage ----------
FROM node:18-alpine
# Set working directory
WORKDIR /app
# Copy only production node_modules and built app
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app ./
# Drop privileges: create and use a non-root user
RUN addgroup -S nodejs && adduser -S nodejs -G nodejs
USER nodejs
# Expose app port
EXPOSE 3000
# Add HEALTHCHECK
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1
# Start application
CMD ["npm", "start"]


