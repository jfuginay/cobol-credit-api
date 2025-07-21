FROM node:18-alpine

# Install GnuCOBOL
RUN apk add --no-cache gnucobol gnucobol-dev build-base

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm ci --only=production

# Copy application files
COPY . .

# Compile COBOL program
RUN cobc -x CREDITCARD.cbl

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001
USER nodejs

EXPOSE 3000

CMD ["node", "server.js"]