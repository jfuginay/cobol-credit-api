const express = require('express');
const { exec } = require('child_process');
const fs = require('fs').promises;
const path = require('path');
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

// Swagger configuration
const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Credit Card Processing API',
      version: '1.0.0',
      description: 'REST API for credit card validation, interest calculation, and statement generation',
      contact: {
        name: 'API Support',
        email: 'support@creditcardapi.com'
      }
    },
    servers: [
      {
        url: 'http://localhost:3000',
        description: 'Development server'
      },
      {
        url: 'https://api.creditcardprocessor.com',
        description: 'Production server'
      }
    ],
    components: {
      securitySchemes: {
        apiKey: {
          type: 'apiKey',
          in: 'header',
          name: 'X-API-Key'
        }
      },
      schemas: {
        CardValidation: {
          type: 'object',
          required: ['cardNumber'],
          properties: {
            cardNumber: {
              type: 'string',
              pattern: '^[0-9]{16}$',
              example: '4532015112830366'
            }
          }
        },
        ValidationResponse: {
          type: 'object',
          properties: {
            valid: {
              type: 'boolean',
              example: true
            },
            cardNumber: {
              type: 'string',
              example: '4532-****-****-0366'
            },
            cardType: {
              type: 'string',
              example: 'VISA'
            }
          }
        },
        InterestCalculation: {
          type: 'object',
          required: ['cardNumber'],
          properties: {
            cardNumber: {
              type: 'string',
              pattern: '^[0-9]{16}$',
              example: '4532015112830366'
            },
            customBalance: {
              type: 'number',
              example: 2500.00,
              description: 'Optional custom balance to calculate interest for'
            }
          }
        },
        InterestResponse: {
          type: 'object',
          properties: {
            currentBalance: {
              type: 'number',
              example: 2500.00
            },
            apr: {
              type: 'number',
              example: 18.99
            },
            monthlyRate: {
              type: 'number',
              example: 1.58
            },
            interestCharge: {
              type: 'number',
              example: 39.58
            },
            newBalance: {
              type: 'number',
              example: 2539.58
            }
          }
        },
        StatementRequest: {
          type: 'object',
          required: ['cardNumber'],
          properties: {
            cardNumber: {
              type: 'string',
              pattern: '^[0-9]{16}$',
              example: '4532015112830366'
            },
            format: {
              type: 'string',
              enum: ['text', 'json', 'pdf'],
              default: 'json',
              example: 'json'
            }
          }
        },
        Error: {
          type: 'object',
          properties: {
            error: {
              type: 'string',
              example: 'Invalid card number'
            },
            code: {
              type: 'string',
              example: 'INVALID_CARD'
            }
          }
        }
      }
    }
  },
  apis: ['./server.js']
};

const specs = swaggerJsdoc(swaggerOptions);
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs));

// Helper function to validate card number using Luhn algorithm
function validateLuhn(cardNumber) {
  if (!/^\d{16}$/.test(cardNumber)) return false;
  
  let sum = 0;
  let isEven = false;
  
  for (let i = cardNumber.length - 1; i >= 0; i--) {
    let digit = parseInt(cardNumber.charAt(i), 10);
    
    if (isEven) {
      digit *= 2;
      if (digit > 9) {
        digit -= 9;
      }
    }
    
    sum += digit;
    isEven = !isEven;
  }
  
  return (sum % 10) === 0;
}

// Helper function to detect card type
function getCardType(cardNumber) {
  const firstDigit = cardNumber.charAt(0);
  const firstTwo = cardNumber.substring(0, 2);
  
  if (firstDigit === '4') return 'VISA';
  if (firstTwo >= '51' && firstTwo <= '55') return 'MASTERCARD';
  if (firstTwo === '34' || firstTwo === '37') return 'AMEX';
  if (firstTwo === '60' || firstTwo === '65') return 'DISCOVER';
  return 'UNKNOWN';
}

// Helper function to mask card number
function maskCardNumber(cardNumber) {
  return `${cardNumber.substring(0, 4)}-****-****-${cardNumber.substring(12)}`;
}

/**
 * @swagger
 * /api/validate:
 *   post:
 *     summary: Validate a credit card number
 *     tags: [Card Validation]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/CardValidation'
 *     responses:
 *       200:
 *         description: Validation result
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ValidationResponse'
 *       400:
 *         description: Bad request
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
app.post('/api/validate', async (req, res) => {
  try {
    const { cardNumber } = req.body;
    
    if (!cardNumber || !/^\d{16}$/.test(cardNumber)) {
      return res.status(400).json({ 
        error: 'Invalid card number format', 
        code: 'INVALID_FORMAT' 
      });
    }
    
    const isValid = validateLuhn(cardNumber);
    const cardType = getCardType(cardNumber);
    
    res.json({
      valid: isValid,
      cardNumber: maskCardNumber(cardNumber),
      cardType: cardType
    });
  } catch (error) {
    res.status(500).json({ 
      error: 'Internal server error', 
      code: 'SERVER_ERROR' 
    });
  }
});

/**
 * @swagger
 * /api/calculate-interest:
 *   post:
 *     summary: Calculate interest for a credit card
 *     tags: [Interest Calculation]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/InterestCalculation'
 *     responses:
 *       200:
 *         description: Interest calculation result
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/InterestResponse'
 *       404:
 *         description: Card not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
app.post('/api/calculate-interest', async (req, res) => {
  try {
    const { cardNumber, customBalance } = req.body;
    
    if (!cardNumber || !/^\d{16}$/.test(cardNumber)) {
      return res.status(400).json({ 
        error: 'Invalid card number format', 
        code: 'INVALID_FORMAT' 
      });
    }
    
    // Read card data
    const cardData = await fs.readFile('CARDDATA.DAT', 'utf8');
    const lines = cardData.split('\n');
    let cardFound = false;
    let balance, apr, creditLimit, cardholderName;
    
    for (const line of lines) {
      if (line.startsWith(cardNumber)) {
        cardFound = true;
        // Parse fixed-width COBOL format
        const lineCardNumber = line.substring(0, 16);
        cardholderName = line.substring(16, 46).trim();
        balance = parseFloat(line.substring(46, 55)) / 100;
        creditLimit = parseFloat(line.substring(55, 64)) / 100;
        apr = parseFloat(line.substring(64, 69)) / 100;
        break;
      }
    }
    
    if (!cardFound) {
      return res.status(404).json({ 
        error: 'Card not found', 
        code: 'CARD_NOT_FOUND' 
      });
    }
    
    // Use custom balance if provided
    if (customBalance !== undefined) {
      balance = customBalance;
    }
    
    const monthlyRate = apr / 12;
    const interestCharge = balance * (monthlyRate / 100);
    const newBalance = balance + interestCharge;
    
    res.json({
      currentBalance: balance,
      apr: apr,
      monthlyRate: parseFloat((monthlyRate).toFixed(2)),
      interestCharge: parseFloat(interestCharge.toFixed(2)),
      newBalance: parseFloat(newBalance.toFixed(2))
    });
  } catch (error) {
    res.status(500).json({ 
      error: 'Internal server error', 
      code: 'SERVER_ERROR' 
    });
  }
});

/**
 * @swagger
 * /api/generate-statement:
 *   post:
 *     summary: Generate a credit card statement
 *     tags: [Statement Generation]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/StatementRequest'
 *     responses:
 *       200:
 *         description: Statement generated successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 statementDate:
 *                   type: string
 *                   example: '2025-07-21'
 *                 cardNumber:
 *                   type: string
 *                   example: '4532-****-****-0366'
 *                 cardholderName:
 *                   type: string
 *                   example: 'John Smith'
 *                 currentBalance:
 *                   type: number
 *                   example: 2500.00
 *                 creditLimit:
 *                   type: number
 *                   example: 5000.00
 *                 availableCredit:
 *                   type: number
 *                   example: 2500.00
 *                 apr:
 *                   type: number
 *                   example: 18.99
 *                 minimumPayment:
 *                   type: number
 *                   example: 75.00
 *                 dueDate:
 *                   type: string
 *                   example: '2025-08-15'
 *       404:
 *         description: Card not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
app.post('/api/generate-statement', async (req, res) => {
  try {
    const { cardNumber, format = 'json' } = req.body;
    
    if (!cardNumber || !/^\d{16}$/.test(cardNumber)) {
      return res.status(400).json({ 
        error: 'Invalid card number format', 
        code: 'INVALID_FORMAT' 
      });
    }
    
    // Read card data
    const cardData = await fs.readFile('CARDDATA.DAT', 'utf8');
    const lines = cardData.split('\n');
    let cardFound = false;
    let balance, apr, creditLimit, cardholderName;
    
    for (const line of lines) {
      if (line.startsWith(cardNumber)) {
        cardFound = true;
        cardholderName = line.substring(16, 46).trim();
        balance = parseFloat(line.substring(46, 55)) / 100;
        creditLimit = parseFloat(line.substring(55, 64)) / 100;
        apr = parseFloat(line.substring(64, 69)) / 100;
        break;
      }
    }
    
    if (!cardFound) {
      return res.status(404).json({ 
        error: 'Card not found', 
        code: 'CARD_NOT_FOUND' 
      });
    }
    
    const today = new Date();
    const dueDate = new Date(today);
    dueDate.setDate(dueDate.getDate() + 25);
    
    const minimumPayment = Math.max(25, balance * 0.03);
    const availableCredit = creditLimit - balance;
    
    const statement = {
      statementDate: today.toISOString().split('T')[0],
      cardNumber: maskCardNumber(cardNumber),
      cardholderName: cardholderName,
      currentBalance: balance,
      creditLimit: creditLimit,
      availableCredit: availableCredit,
      apr: apr,
      minimumPayment: parseFloat(minimumPayment.toFixed(2)),
      dueDate: dueDate.toISOString().split('T')[0]
    };
    
    res.json(statement);
  } catch (error) {
    res.status(500).json({ 
      error: 'Internal server error', 
      code: 'SERVER_ERROR' 
    });
  }
});

/**
 * @swagger
 * /api/cards:
 *   get:
 *     summary: Get all credit cards (masked)
 *     tags: [Card Management]
 *     responses:
 *       200:
 *         description: List of all cards
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   cardNumber:
 *                     type: string
 *                     example: '4532-****-****-0366'
 *                   cardholderName:
 *                     type: string
 *                     example: 'John Smith'
 *                   balance:
 *                     type: number
 *                     example: 2500.00
 *                   creditLimit:
 *                     type: number
 *                     example: 5000.00
 */
app.get('/api/cards', async (req, res) => {
  try {
    const cardData = await fs.readFile('CARDDATA.DAT', 'utf8');
    const lines = cardData.split('\n').filter(line => line.trim());
    
    const cards = lines.map(line => {
      const cardNumber = line.substring(0, 16);
      const cardholderName = line.substring(16, 46).trim();
      const balance = parseFloat(line.substring(46, 55)) / 100;
      const creditLimit = parseFloat(line.substring(55, 64)) / 100;
      
      return {
        cardNumber: maskCardNumber(cardNumber),
        cardholderName: cardholderName,
        balance: balance,
        creditLimit: creditLimit
      };
    });
    
    res.json(cards);
  } catch (error) {
    res.status(500).json({ 
      error: 'Internal server error', 
      code: 'SERVER_ERROR' 
    });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Credit Card Processing API',
    version: '1.0.0',
    documentation: '/api-docs'
  });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Swagger documentation available at http://localhost:${PORT}/api-docs`);
});