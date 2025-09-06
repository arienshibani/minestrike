#!/bin/bash

# Test Minecraft server port accessibility
PORT=25565
HOST="localhost"

echo "Testing Minecraft server port $PORT on $HOST..."

# Test if port is open
if nc -z $HOST $PORT 2>/dev/null; then
    echo "✅ Port $PORT is open and accessible"
    
    # Try to get server info (if server is running)
    echo "Attempting to get server info..."
    timeout 5 nc $HOST $PORT < /dev/null 2>/dev/null && echo "✅ Server is responding" || echo "⚠️  Port is open but server may not be running"
else
    echo "❌ Port $PORT is not accessible"
    echo "Make sure the server is running and firewall allows the connection"
fi

echo ""
echo "To test from another machine, use:"
echo "nc -z YOUR_SERVER_IP $PORT"
echo ""
echo "To test with telnet:"
echo "telnet $HOST $PORT"
