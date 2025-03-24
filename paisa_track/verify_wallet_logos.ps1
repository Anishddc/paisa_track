# PowerShell script to verify wallet logos

# Directory containing wallet logos
$WALLET_DIR = "assets/wallets"

# List of expected wallet logos
$WALLETS = @(
    "esewa.png",
    "khalti.png",
    "imepay.png",
    "connectips.png",
    "fonepay.png",
    "prabhupay.png",
    "qpay.png",
    "ipay.png",
    "moco.png"
)

# Header
Write-Host "===== Wallet Logo Status ====="
Write-Host ""

# Check if wallet directory exists
if (-not (Test-Path -Path $WALLET_DIR)) {
    Write-Host "Error: '$WALLET_DIR' directory not found!"
    exit 1
}

# Count of missing and found logos
$MISSING = 0
$FOUND = 0

# Check each wallet logo
foreach ($wallet in $WALLETS) {
    $LOGO_PATH = Join-Path -Path $WALLET_DIR -ChildPath $wallet
    
    if (Test-Path -Path $LOGO_PATH) {
        Write-Host "Found: $wallet"
        $FOUND++
    } else {
        Write-Host "Missing: $wallet"
        $MISSING++
    }
}

# Summary
Write-Host ""
Write-Host "Summary: $FOUND found, $MISSING missing"

if ($MISSING -eq 0) {
    Write-Host "All wallet logos are ready!"
} else {
    Write-Host "Please download the missing logos and place them in the '$WALLET_DIR' directory."
} 