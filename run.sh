#!/bin/bash
# Quick start script for development
# Run with: ./run.sh

echo "ESP Hive Server - Starting..."
echo ""

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "[ERROR] Python 3 is not installed"
    echo "Install with: sudo apt-get install python3 python3-pip"
    exit 1
fi

# Create directories if they don't exist
mkdir -p data logs

# Check if requirements are installed
echo "[CHECK] Python dependencies..."
python3 -c "import flask" 2>/dev/null || {
    echo "[INSTALL] Installing requirements..."
    pip3 install -q -r requirements.txt
}

# Run the application
echo "[START] Launching Flask + TCP server..."
echo ""
cd "$(dirname "$0")"
python3 app/app.py
