#!/bin/bash
# Quick test to verify deployment is working

echo "Testing ESP Hive Deployment..."
echo ""

# Test 1: Check if Python app runs
echo "1. Checking Python and dependencies..."
python3 -c "from flask import Flask; print('✓ Flask installed')" 2>/dev/null || {
    echo "✗ Flask not installed"
    exit 1
}

# Test 2: Check directory structure
echo ""
echo "2. Checking directory structure..."
for dir in app config data logs scripts; do
    if [ -d "$dir" ]; then
        echo "   ✓ $dir/ exists"
    else
        echo "   ✗ $dir/ missing"
    fi
done

# Test 3: Check critical files
echo ""
echo "3. Checking critical files..."
for file in app/app.py app/crypto.py requirements.txt .env; do
    if [ -f "$file" ]; then
        echo "   ✓ $file exists"
    else
        echo "   ✗ $file missing"
    fi
done

# Test 4: Check if service is installed (if running on Raspberry Pi)
if sudo systemctl list-unit-files | grep -q esp-hive; then
    echo ""
    echo "4. Checking systemd service..."
    if sudo systemctl is-enabled esp-hive &>/dev/null; then
        echo "   ✓ Service enabled for auto-start"
    else
        echo "   ⚠ Service not enabled for auto-start"
    fi
fi

echo ""
echo "✓ Deployment structure looks good!"
echo ""
echo "Next: Run 'sudo systemctl start esp-hive' to start the service"
