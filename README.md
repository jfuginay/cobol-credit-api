# Credit Card Processing System

A true COBOL-based credit card processing system with a modern REST API wrapper. This project executes actual COBOL programs for credit card processing operations, bridging 50-year-old COBOL technology with modern REST APIs.

## 🚀 Quick Deploy Options

### Option 1: Deploy with Railway

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/template/github/jfuginay/cobol-credit-api)

Or manually:
1. Fork this repository to your GitHub account
2. Go to [Railway.app](https://railway.app/new)
3. Click "Deploy from GitHub repo"
4. Select your forked repository
5. Railway will auto-detect the Dockerfile and deploy!

### Option 2: Deploy with Render
[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy)

### Option 3: Local Deployment
Clone and run locally in minutes!

## Features

- **True COBOL Execution**: API actually executes compiled COBOL programs
- **Card Validation**: Luhn algorithm implemented in COBOL
- **Interest Calculation**: APR-based monthly interest calculated by COBOL
- **Statement Generation**: COBOL-generated statements in text format
- **REST API**: Express.js wrapper that interfaces with COBOL executables
- **Automatic Fallback**: JavaScript implementation when COBOL not available
- **Swagger Documentation**: Interactive API documentation
- **Security**: Rate limiting, CORS, Helmet protection

## Quick Start

### Local Development

1. Install GnuCOBOL (required for COBOL execution):
```bash
# macOS
brew install gnu-cobol

# Ubuntu/Debian
sudo apt-get install gnucobol

# RHEL/CentOS
sudo yum install gnucobol
```

2. Install Node.js dependencies:
```bash
npm install
```

3. Compile the COBOL program:
```bash
./setup-cobol.sh
# Or manually: cobc -x CREDITCARD.cbl -o CREDITCARD
```

4. Run the API server:
```bash
npm start
```

5. Access Swagger documentation:
```
http://localhost:3000/api-docs
```

The server will indicate whether it's using COBOL or JavaScript fallback on startup.

### Docker Deployment

```bash
docker-compose up -d
```

## API Endpoints

All endpoints will use COBOL execution when available, with automatic fallback to JavaScript:

- `POST /api/validate` - Validate credit card number using COBOL Luhn algorithm
- `POST /api/calculate-interest` - Calculate monthly interest via COBOL program
- `POST /api/generate-statement` - Generate account statement (text format uses COBOL)
- `GET /api/cards` - List all cards (masked) from COBOL data file

Each response includes a `validationMethod`, `calculationMethod`, `generationMethod`, or `retrievalMethod` field indicating whether COBOL or JavaScript was used.

## Testing with Postman

1. Import `postman-collection.json` into Postman
2. Set the `baseUrl` variable to your API endpoint
3. Run the collection tests

## Integration with Payment Processors

To integrate with real payment processors:

1. **Stripe Integration**:
   - Add Stripe SDK to package.json
   - Use Stripe's card tokenization
   - Forward validation to Stripe's API

2. **Square Integration**:
   - Add Square SDK
   - Use Square's payment endpoints
   - Handle webhooks for real-time updates

3. **PCI Compliance**:
   - Never store raw card numbers
   - Use tokenization for all card data
   - Implement proper encryption
   - Follow PCI-DSS standards

## Security Considerations

- Card numbers are masked in responses
- Rate limiting prevents abuse
- HTTPS required for production
- API key authentication recommended
- Never log sensitive card data

## Sample Test Cards

- 4532015112830366 (Valid VISA)
- 5425233430109903 (Valid MasterCard)
- 4111111111111111 (Valid VISA)

## Production Deployment

1. Set environment variables
2. Enable HTTPS/TLS
3. Configure API authentication
4. Set up monitoring and logging
5. Implement database backend
6. Add encryption for card data