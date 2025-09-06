#!/bin/bash

# Comprehensive Minecraft Server Connection Debug Script
# Run this on your EC2 instance

echo "🔍 Minecraft Server Connection Debug"
echo "===================================="

# Get external IP
EXTERNAL_IP=$(curl -s ifconfig.me)
echo "External IP: $EXTERNAL_IP"

# 1. Check service status
echo ""
echo "1. Service Status:"
sudo systemctl status minecraft-server --no-pager

# 2. Check what's listening
echo ""
echo "2. Port 25565 Status:"
echo "netstat output:"
sudo netstat -tlnp | grep 25565 || echo "Port 25565 not found in netstat"
echo "ss output:"
sudo ss -tlnp | grep 25565 || echo "Port 25565 not found in ss"

# 3. Check server properties
echo ""
echo "3. Server Configuration:"
if [ -f "/opt/minecraft/server.properties" ]; then
    echo "server-port: $(grep 'server-port' /opt/minecraft/server.properties)"
    echo "server-ip: $(grep 'server-ip' /opt/minecraft/server.properties)"
    echo "online-mode: $(grep 'online-mode' /opt/minecraft/server.properties)"
else
    echo "❌ server.properties not found"
fi

# 4. Check recent logs
echo ""
echo "4. Recent Server Logs (last 20 lines):"
sudo journalctl -u minecraft-server --no-pager -n 20

# 5. Test local connection
echo ""
echo "5. Local Connection Test:"
if timeout 5 bash -c "</dev/tcp/localhost/25565" 2>/dev/null; then
    echo "✅ Local connection successful"
else
    echo "❌ Local connection failed"
fi

# 6. Check firewall
echo ""
echo "6. Firewall Status:"
if command -v ufw >/dev/null 2>&1; then
    sudo ufw status
    if sudo ufw status | grep -q "25565"; then
        echo "✅ Port 25565 allowed in UFW"
    else
        echo "❌ Port 25565 not allowed in UFW"
    fi
else
    echo "UFW not installed"
fi

# 7. Check iptables
echo ""
echo "7. iptables rules for port 25565:"
sudo iptables -L | grep 25565 || echo "No iptables rules for port 25565"

# 8. Test external connection
echo ""
echo "8. External Connection Test:"
if timeout 5 bash -c "</dev/tcp/$EXTERNAL_IP/25565" 2>/dev/null; then
    echo "✅ External connection successful"
else
    echo "❌ External connection failed"
fi

# 9. Check if server is fully loaded
echo ""
echo "9. Server Load Status:"
if sudo journalctl -u minecraft-server --no-pager | grep -q "Done"; then
    echo "✅ Server fully loaded"
else
    echo "❌ Server not fully loaded"
fi

# 10. Check for any Java errors
echo ""
echo "10. Java Process Status:"
ps aux | grep java | grep -v grep || echo "No Java processes found"

echo ""
echo "===================================="
echo "Debug complete!"
echo ""
echo "If external connection failed:"
echo "1. Check AWS Security Group allows port 25565 from 0.0.0.0/0"
echo "2. Check if server-ip is set to 127.0.0.1 in server.properties"
echo "3. Check if UFW firewall allows port 25565"
echo ""
echo "If local connection failed:"
echo "1. Check if server is fully loaded (look for 'Done' in logs)"
echo "2. Check server.properties configuration"
echo "3. Restart the minecraft-server service"
