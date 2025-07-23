#!/bin/bash

echo "Setting up COBOL integration..."

# Check if GnuCOBOL is installed
if ! command -v cobc &> /dev/null; then
    echo "GnuCOBOL is not installed."
    echo "To install on macOS: brew install gnu-cobol"
    echo "To install on Ubuntu/Debian: sudo apt-get install gnucobol"
    echo "To install on RHEL/CentOS: sudo yum install gnucobol"
    exit 1
fi

# Compile the COBOL program
echo "Compiling CREDITCARD.cbl..."
cobc -x CREDITCARD.cbl -o CREDITCARD

if [ $? -eq 0 ]; then
    echo "✓ COBOL program compiled successfully!"
    echo "The API will now use COBOL for processing."
else
    echo "✗ Failed to compile COBOL program"
    exit 1
fi

# Test the compiled program exists and is executable
if [ -x "./CREDITCARD" ]; then
    echo "✓ CREDITCARD executable is ready"
else
    echo "✗ CREDITCARD executable not found or not executable"
    exit 1
fi

echo ""
echo "Setup complete! Restart the server to use COBOL processing."