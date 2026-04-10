#!/bin/bash
set -e

echo "======================================"
echo "  ESP Hive Server - Setup Script"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Detect Raspberry Pi
echo "[1/8] Checking system..."
if grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Detected Raspberry Pi"
else
    echo -e "${YELLOW}⚠${NC} Not detected as Raspberry Pi. Continuing anyway..."
fi

# Check if running with sudo for apt
if [ "$EUID" -ne 0 ] && command -v sudo &> /dev/null; then
    SUDO="sudo"
else
    SUDO=""
fi

# Update system
echo "[2/8] Updating system packages..."
$SUDO apt-get update -qq
$SUDO apt-get upgrade -y -qq
echo -e "${GREEN}✓${NC} System updated"

# Install Python 3 and pip
echo "[3/8] Installing Python 3 and pip..."
$SUDO apt-get install -y -qq python3 python3-pip python3-venv
echo -e "${GREEN}✓${NC} Python installed"

# Create data directories
echo "[4/8] Creating data and log directories..."
mkdir -p data logs config
chmod 755 data logs config
echo -e "${GREEN}✓${NC} Directories created"

# Install Python requirements
echo "[5/8] Installing Python requirements..."
pip3 install -q -r requirements.txt
echo -e "${GREEN}✓${NC} Python packages installed"

# Create .env if needed
echo "[6/8] Setting up configuration..."
if [ ! -f .env ]; then
    cp .env.example .env
    echo -e "${GREEN}✓${NC} Created .env configuration"
    echo -e "    ${YELLOW}ℹ${NC} Edit .env to customize settings if needed"
else
    echo -e "${GREEN}✓${NC} .env already exists"
fi

# Install systemd service
echo "[7/8] Installing systemd service..."
if [ -n "$SUDO" ]; then
    $SUDO cp scripts/esp-hive.service /etc/systemd/system/
    $SUDO systemctl daemon-reload

    # Enable auto-start on boot
    $SUDO systemctl enable esp-hive

    echo -e "${GREEN}✓${NC} Systemd service installed & enabled for auto-start"
else
    echo -e "${RED}✗${NC} Requires sudo to install systemd service"
    exit 1
fi

# Verify service is enabled
echo "[8/8] Verifying auto-start configuration..."
if $SUDO systemctl is-enabled esp-hive &>/dev/null; then
    echo -e "${GREEN}✓${NC} Service will auto-start on boot"
else
    echo -e "${YELLOW}⚠${NC} Service enable status unclear, trying again..."
    $SUDO systemctl enable esp-hive
fi

echo ""
echo "======================================"
echo -e "  ${GREEN}Setup Complete!${NC}"
echo "======================================"
echo ""
echo "Next steps:"
echo ""
echo "1. Start the service NOW:"
echo "   sudo systemctl start esp-hive"
echo ""
echo "2. Verify it's running:"
echo "   sudo systemctl status esp-hive"
echo ""
echo "3. View logs:"
echo "   sudo journalctl -u esp-hive -f"
echo ""
echo "4. Access dashboard:"
echo "   http://raspberrypi.local:5000"
echo ""
echo "✓ Service will auto-start on every boot!"
echo ""
