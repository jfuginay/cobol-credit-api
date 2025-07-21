# Credit Card Processing System

A COBOL-based credit card processing system with a modern REST API wrapper, complete with Swagger documentation for easy testing with Postman.

## Features

- **Card Validation**: Luhn algorithm implementation
- **Interest Calculation**: APR-based monthly interest
- **Statement Generation**: JSON/text format statements
- **REST API**: Express.js wrapper for COBOL functionality
- **Swagger Documentation**: Interactive API documentation
- **Security**: Rate limiting, CORS, Helmet protection

## Quick Start

### Local Development

1. Install dependencies:
```bash
npm install
```

2. Run the API server:
```bash
npm start
```

3. Access Swagger documentation:
```
http://localhost:3000/api-docs
```

### Docker Deployment

```bash
docker-compose up -d
```

## API Endpoints

- `POST /api/validate` - Validate credit card number
- `POST /api/calculate-interest` - Calculate monthly interest
- `POST /api/generate-statement` - Generate account statement
- `GET /api/cards` - List all cards (masked)

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