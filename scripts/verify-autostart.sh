#!/bin/bash
# Verify auto-start is configured correctly

echo "Checking ESP Hive auto-start configuration..."
echo ""

# Check if service is enabled
echo "1. Checking if service is enabled..."
if sudo systemctl is-enabled esp-hive &>/dev/null; then
    echo "   ✓ Service is enabled for auto-start"
else
    echo "   ✗ Service is NOT enabled for auto-start"
    echo "   Run: sudo systemctl enable esp-hive"
    exit 1
fi

echo ""
echo "2. Checking service file..."
if [ -f /etc/systemd/system/esp-hive.service ]; then
    echo "   ✓ Service file exists: /etc/systemd/system/esp-hive.service"
else
    echo "   ✗ Service file not found"
    exit 1
fi

echo ""
echo "3. Checking systemd configuration..."
if sudo systemctl status esp-hive &>/dev/null; then
    echo "   ✓ Service is currently running"
elif [ $? -eq 3 ]; then
    echo "   ℹ Service is not running (expected after setup)"
    echo "   Start with: sudo systemctl start esp-hive"
fi

echo ""
echo "4. What happens on boot:"
echo "   • Raspberry Pi powers on"
echo "   • System loads services"
echo "   • ESP Hive service auto-starts"
echo "   • Application runs on ports 5000 (web) and 5001 (TCP)"
echo "   • Service restarts automatically if it crashes"

echo ""
echo "✓ Auto-start is properly configured!"
echo ""
