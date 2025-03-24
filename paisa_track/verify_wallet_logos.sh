#!/bin/bash

# Directory containing wallet logos
WALLET_DIR="assets/wallets"

# List of expected wallet logos
WALLETS=(
  "esewa.png"
  "khalti.png"
  "imepay.png"
  "connectips.png"
  "fonepay.png"
  "prabhupay.png"
  "qpay.png"
  "ipay.png"
  "moco.png"
)

# Header
echo "===== Wallet Logo Status ====="
echo

# Check if wallet directory exists
if [ ! -d "$WALLET_DIR" ]; then
  echo "Error: '$WALLET_DIR' directory not found!"
  exit 1
fi

# Count of missing and found logos
MISSING=0
FOUND=0

# Check each wallet logo
for wallet in "${WALLETS[@]}"; do
  LOGO_PATH="$WALLET_DIR/$wallet"
  
  if [ -f "$LOGO_PATH" ]; then
    echo "✅ Found: $wallet"
    ((FOUND++))
  else
    echo "❌ Missing: $wallet"
    ((MISSING++))
  fi
done

# Summary
echo
echo "Summary: $FOUND found, $MISSING missing"

if [ $MISSING -eq 0 ]; then
  echo "All wallet logos are ready! 🎉"
else
  echo "Please download the missing logos and place them in the '$WALLET_DIR' directory."
fi 