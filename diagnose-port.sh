#!/bin/bash

# Minecraft Server Port Diagnosis Script
# Run this on your EC2 instance to diagnose port 25565 issues

echo "🔍 Minecraft Server Port Diagnosis"
echo "=================================="

# Check if server is running
echo "1. Checking if minecraft-server service is running..."
if systemctl is-active --quiet minecraft-server; then
    echo "✅ minecraft-server service is running"
else
    echo "❌ minecraft-server service is not running"
    exit 1
fi

# Check what ports Java is listening on
echo "2. Checking what ports Java is listening on..."
JAVA_PORTS=$(sudo netstat -tlnp | grep java)
if [ -n "$JAVA_PORTS" ]; then
    echo "✅ Java processes are listening on:"
    echo "$JAVA_PORTS"
else
    echo "❌ No Java processes are listening on any ports"
fi

# Check specifically for port 25565
echo "3. Checking port 25565 specifically..."
if netstat -tlnp | grep -q ":25565 "; then
    echo "✅ Port 25565 is listening"
    netstat -tlnp | grep 25565
else
    echo "❌ Port 25565 is not listening"
fi

# Check server.properties
echo "4. Checking server.properties configuration..."
if [ -f "/opt/minecraft/server.properties" ]; then
    echo "✅ server.properties exists"
    echo "Server port setting:"
    grep "server-port" /opt/minecraft/server.properties || echo "server-port not found"
    echo "Server IP setting:"
    grep "server-ip" /opt/minecraft/server.properties || echo "server-ip not set (defaults to all interfaces)"
else
    echo "❌ server.properties not found"
fi

# Check firewall status
echo "5. Checking firewall status..."
if command -v ufw >/dev/null 2>&1; then
    echo "UFW status:"
    sudo ufw status
    if sudo ufw status | grep -q "25565"; then
        echo "✅ Port 25565 is allowed in UFW"
    else
        echo "❌ Port 25565 is not allowed in UFW"
        echo "Run: sudo ufw allow 25565/tcp"
    fi
else
    echo "UFW not installed"
fi

# Test local connection
echo "6. Testing local connection to port 25565..."
if timeout 5 bash -c "</dev/tcp/localhost/25565" 2>/dev/null; then
    echo "✅ Local connection to port 25565 successful"
else
    echo "❌ Local connection to port 25565 failed"
fi

# Check recent server logs
echo "7. Recent server logs (last 20 lines):"
sudo journalctl -u minecraft-server --no-pager -n 20

# Check external IP
echo "8. External IP address:"
EXTERNAL_IP=$(curl -s ifconfig.me)
echo "External IP: $EXTERNAL_IP"

# Check if port is accessible externally
echo "9. Testing external port accessibility..."
if command -v nc >/dev/null 2>&1; then
    if timeout 5 nc -z $EXTERNAL_IP 25565 2>/dev/null; then
        echo "✅ Port 25565 is accessible externally"
    else
        echo "❌ Port 25565 is not accessible externally"
        echo "This is likely an AWS Security Group issue"
    fi
else
    echo "netcat not available for external test"
fi

echo "=================================="
echo "Diagnosis complete!"
echo ""
echo "If port 25565 is not accessible externally:"
echo "1. Check AWS Security Group allows port 25565 from 0.0.0.0/0"
echo "2. Check if UFW firewall allows port 25565"
echo "3. Verify server.properties has correct settings"
echo ""
echo "If port 25565 is not listening at all:"
echo "1. Check server logs for binding errors"
echo "2. Verify server.properties has server-port=25565"
echo "3. Restart the minecraft-server service"
