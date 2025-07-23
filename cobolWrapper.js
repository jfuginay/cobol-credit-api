const { spawn } = require('child_process');
const fs = require('fs').promises;
const path = require('path');

class CobolWrapper {
  constructor() {
    this.cobolExecutable = './CREDITCARD';
    this.dataFile = 'CARDDATA.DAT';
    this.statementFile = 'STATEMENT.TXT';
  }

  /**
   * Execute COBOL program with specific inputs
   * @param {Array} inputs - Array of inputs to send to the COBOL program
   * @returns {Promise<string>} - Output from COBOL program
   */
  async executeCobol(inputs) {
    return new Promise((resolve, reject) => {
      const cobol = spawn(this.cobolExecutable);
      let output = '';
      let errorOutput = '';

      cobol.stdout.on('data', (data) => {
        output += data.toString();
      });

      cobol.stderr.on('data', (data) => {
        errorOutput += data.toString();
      });

      cobol.on('close', (code) => {
        if (code !== 0) {
          reject(new Error(`COBOL process exited with code ${code}: ${errorOutput}`));
        } else {
          resolve(output);
        }
      });

      cobol.on('error', (err) => {
        if (err.code === 'ENOENT') {
          reject(new Error('COBOL executable not found. Please compile CREDITCARD.cbl first.'));
        } else {
          reject(err);
        }
      });

      // Send inputs to COBOL program
      inputs.forEach((input, index) => {
        setTimeout(() => {
          cobol.stdin.write(input + '\n');
        }, index * 100); // Small delay between inputs
      });

      // Close stdin after all inputs
      setTimeout(() => {
        cobol.stdin.end();
      }, inputs.length * 100 + 100);
    });
  }

  /**
   * Validate a credit card number using COBOL program
   * @param {string} cardNumber - 16-digit card number
   * @returns {Promise<boolean>} - True if valid, false otherwise
   */
  async validateCard(cardNumber) {
    try {
      const inputs = ['1', cardNumber, '5']; // Menu option 1, card number, exit
      const output = await this.executeCobol(inputs);
      return output.includes('Card number is VALID');
    } catch (error) {
      throw new Error(`Failed to validate card: ${error.message}`);
    }
  }

  /**
   * Calculate interest for a credit card
   * @param {string} cardNumber - 16-digit card number
   * @returns {Promise<object>} - Interest calculation details
   */
  async calculateInterest(cardNumber) {
    try {
      const inputs = ['2', cardNumber, '5']; // Menu option 2, card number, exit
      const output = await this.executeCobol(inputs);
      
      // Parse output to extract interest details
      const balanceMatch = output.match(/Current Balance: \$([0-9,]+\.[0-9]+)/);
      const aprMatch = output.match(/APR: ([0-9]+\.[0-9]+)%/);
      const interestMatch = output.match(/Interest Charge: \$([0-9,]+\.[0-9]+)/);
      const newBalanceMatch = output.match(/New Balance: \$([0-9,]+\.[0-9]+)/);

      if (!balanceMatch || !aprMatch || !interestMatch || !newBalanceMatch) {
        if (output.includes('Card not found')) {
          throw new Error('Card not found in database');
        }
        throw new Error('Failed to parse interest calculation output');
      }

      return {
        currentBalance: parseFloat(balanceMatch[1].replace(/,/g, '')),
        apr: parseFloat(aprMatch[1]),
        interestCharge: parseFloat(interestMatch[1].replace(/,/g, '')),
        newBalance: parseFloat(newBalanceMatch[1].replace(/,/g, ''))
      };
    } catch (error) {
      throw new Error(`Failed to calculate interest: ${error.message}`);
    }
  }

  /**
   * Generate statement for a credit card
   * @param {string} cardNumber - 16-digit card number
   * @returns {Promise<string>} - Path to generated statement file
   */
  async generateStatement(cardNumber) {
    try {
      // Remove existing statement file if it exists
      try {
        await fs.unlink(this.statementFile);
      } catch (err) {
        // File doesn't exist, which is fine
      }

      const inputs = ['3', cardNumber, '5']; // Menu option 3, card number, exit
      const output = await this.executeCobol(inputs);
      
      if (output.includes('Card not found')) {
        throw new Error('Card not found in database');
      }

      if (!output.includes('Statement generated successfully!')) {
        throw new Error('Failed to generate statement');
      }

      // Read the generated statement
      const statement = await fs.readFile(this.statementFile, 'utf8');
      return statement;
    } catch (error) {
      throw new Error(`Failed to generate statement: ${error.message}`);
    }
  }

  /**
   * Get all cards from the database
   * @returns {Promise<Array>} - Array of card details
   */
  async getAllCards() {
    try {
      const inputs = ['4', '5']; // Menu option 4, exit
      const output = await this.executeCobol(inputs);
      
      // Parse output to extract card details
      const cardLines = output.split('\n').filter(line => line.includes('Card:'));
      const cards = cardLines.map(line => {
        const cardMatch = line.match(/Card: ([0-9]{4})-\*\*\*\*-\*\*\*\*-([0-9]{4})/);
        const nameMatch = line.match(/Name: ([^$]+)/);
        const balanceMatch = line.match(/Balance: \$([0-9,]+\.[0-9]+)/);
        
        if (cardMatch && nameMatch && balanceMatch) {
          return {
            maskedNumber: `${cardMatch[1]}-****-****-${cardMatch[2]}`,
            cardholderName: nameMatch[1].trim(),
            balance: parseFloat(balanceMatch[1].replace(/,/g, ''))
          };
        }
        return null;
      }).filter(card => card !== null);

      return cards;
    } catch (error) {
      throw new Error(`Failed to get all cards: ${error.message}`);
    }
  }

  /**
   * Check if COBOL executable exists
   * @returns {Promise<boolean>} - True if executable exists
   */
  async isCobolAvailable() {
    try {
      await fs.access(this.cobolExecutable, fs.constants.X_OK);
      return true;
    } catch (error) {
      return false;
    }
  }

  /**
   * Compile COBOL program if needed
   * @returns {Promise<void>}
   */
  async compileCobolIfNeeded() {
    const isAvailable = await this.isCobolAvailable();
    if (!isAvailable) {
      throw new Error('COBOL executable not found. Please compile CREDITCARD.cbl using: cobc -x CREDITCARD.cbl -o CREDITCARD');
    }
  }
}

module.exports = CobolWrapper;