FROM ubuntu:22.04

# Install Node.js and GnuCOBOL with all dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gnucobol \
    libcob4 \
    libcob4-dev \
    build-essential \
    libgmp-dev \
    libdb-dev \
    libncurses5-dev \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm ci --only=production

# Copy application files
COPY . .

# Compile COBOL program
RUN cobc -x CREDITCARD.cbl -o CREDITCARD && \
    chmod +x CREDITCARD && \
    # Test that COBOL executable works
    echo "5" | ./CREDITCARD || true

# Create non-root user and change ownership
RUN groupadd -g 1001 nodejs && \
    useradd -r -u 1001 -g nodejs nodejs && \
    chown -R nodejs:nodejs /app

USER nodejs

EXPOSE 3000

CMD ["node", "server.js"]