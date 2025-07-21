FROM ubuntu:22.04

# Install Node.js and GnuCOBOL
RUN apt-get update && apt-get install -y \
    curl \
    gnucobol \
    build-essential \
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
RUN cobc -x CREDITCARD.cbl

# Create non-root user
RUN groupadd -g 1001 nodejs && \
    useradd -r -u 1001 -g nodejs nodejs
USER nodejs

EXPOSE 3000

CMD ["node", "server.js"]