#!/bin/bash

# Minecraft Server Troubleshooting Script
# Run this on your EC2 instance to diagnose connection issues

echo "🔍 Minecraft Server Troubleshooting"
echo "=================================="

# Check if service exists
echo "1. Checking systemd service..."
if systemctl list-unit-files | grep -q minecraft-server; then
    echo "✅ minecraft-server service exists"
else
    echo "❌ minecraft-server service not found"
    exit 1
fi

# Check service status
echo "2. Checking service status..."
if systemctl is-active --quiet minecraft-server; then
    echo "✅ minecraft-server is running"
else
    echo "❌ minecraft-server is not running"
    echo "Attempting to start..."
    sudo systemctl start minecraft-server
    sleep 5
    if systemctl is-active --quiet minecraft-server; then
        echo "✅ minecraft-server started successfully"
    else
        echo "❌ Failed to start minecraft-server"
        echo "Service status:"
        sudo systemctl status minecraft-server --no-pager
    fi
fi

# Check if port is listening
echo "3. Checking port 25565..."
if netstat -tlnp | grep -q ":25565 "; then
    echo "✅ Port 25565 is listening"
else
    echo "❌ Port 25565 is not listening"
fi

# Check Java installation
echo "4. Checking Java installation..."
if java -version 2>&1 | grep -q "17\|18\|19\|20\|21\|22"; then
    echo "✅ Java is installed"
    java -version
else
    echo "❌ Java not found or wrong version"
fi

# Check server directory
echo "5. Checking server directory..."
if [ -d "/opt/minecraft" ]; then
    echo "✅ Server directory exists"
    echo "Contents:"
    ls -la /opt/minecraft/
else
    echo "❌ Server directory not found"
fi

# Check EULA
echo "6. Checking EULA..."
if [ -f "/opt/minecraft/eula.txt" ]; then
    echo "✅ EULA file exists"
    if grep -q "eula=true" /opt/minecraft/eula.txt; then
        echo "✅ EULA is accepted"
    else
        echo "❌ EULA not accepted"
    fi
else
    echo "❌ EULA file not found"
fi

# Check firewall
echo "7. Checking firewall..."
if command -v ufw >/dev/null 2>&1; then
    echo "UFW status:"
    sudo ufw status
else
    echo "UFW not installed"
fi

# Check recent logs
echo "8. Recent service logs:"
sudo journalctl -u minecraft-server --no-pager -n 20

# Check external IP
echo "9. External IP:"
curl -s ifconfig.me
echo ""

echo "=================================="
echo "Troubleshooting complete!"
echo ""
echo "If the server is running but you still can't connect:"
echo "1. Check AWS Security Group allows port 25565"
echo "2. Verify you're using the correct IP address"
echo "3. Try connecting from the EC2 instance: telnet localhost 25565"
