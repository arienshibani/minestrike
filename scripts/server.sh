#!/bin/bash

# Minecraft Server Management Script
# Usage: ./server.sh {start|stop|restart|status|logs}

SERVER_DIR="/opt/minecraft/server"
LOGS_DIR="/opt/minecraft/logs"
SCREEN_NAME="minecraft-server"
SERVER_JAR="server.jar"
JAVA_OPTS="-Xmx4G -Xms2G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if server jar exists
check_server_jar() {
    if [ ! -f "$SERVER_DIR/$SERVER_JAR" ]; then
        print_error "Server jar not found at $SERVER_DIR/$SERVER_JAR"
        print_status "Please download Paper/Spigot server jar and rename it to $SERVER_JAR"
        print_status "You can download Paper from: https://papermc.io/downloads/paper"
        exit 1
    fi
}

# Check if screen is installed
check_screen() {
    if ! command -v screen &> /dev/null; then
        print_error "Screen is not installed. Please install it:"
        print_status "Ubuntu/Debian: sudo apt install screen"
        print_status "macOS: brew install screen"
        exit 1
    fi
}

# Start the server
start_server() {
    print_status "Starting Minecraft server..."
    
    check_server_jar
    check_screen
    
    # Check if server is already running
    if screen -list | grep -q "$SCREEN_NAME"; then
        print_warning "Server is already running!"
        return 1
    fi
    
    # Create logs directory if it doesn't exist
    mkdir -p "$LOGS_DIR"
    
    # Start server in screen session
    cd "$SERVER_DIR"
    screen -dmS "$SCREEN_NAME" java $JAVA_OPTS -jar "$SERVER_JAR" nogui
    
    # Wait a moment for server to start
    sleep 3
    
    if screen -list | grep -q "$SCREEN_NAME"; then
        print_status "Server started successfully!"
        print_status "Use 'screen -r $SCREEN_NAME' to attach to the server console"
        print_status "Use 'Ctrl+A, D' to detach from the console"
    else
        print_error "Failed to start server!"
        return 1
    fi
}

# Stop the server
stop_server() {
    print_status "Stopping Minecraft server..."
    
    if ! screen -list | grep -q "$SCREEN_NAME"; then
        print_warning "Server is not running!"
        return 1
    fi
    
    # Send stop command to server
    screen -S "$SCREEN_NAME" -X stuff "stop$(printf \\r)"
    
    # Wait for server to stop gracefully
    sleep 5
    
    # Force kill if still running
    if screen -list | grep -q "$SCREEN_NAME"; then
        print_warning "Server didn't stop gracefully, force killing..."
        screen -S "$SCREEN_NAME" -X quit
        sleep 2
    fi
    
    if ! screen -list | grep -q "$SCREEN_NAME"; then
        print_status "Server stopped successfully!"
    else
        print_error "Failed to stop server!"
        return 1
    fi
}

# Restart the server
restart_server() {
    print_status "Restarting Minecraft server..."
    stop_server
    sleep 2
    start_server
}

# Check server status
status_server() {
    if screen -list | grep -q "$SCREEN_NAME"; then
        print_status "Server is running"
        print_status "Screen session: $SCREEN_NAME"
        print_status "Use 'screen -r $SCREEN_NAME' to attach to console"
    else
        print_status "Server is not running"
    fi
}

# Show server logs
show_logs() {
    if [ -f "$SERVER_DIR/logs/latest.log" ]; then
        print_status "Showing latest server logs (last 50 lines):"
        echo "----------------------------------------"
        tail -n 50 "$SERVER_DIR/logs/latest.log"
    else
        print_warning "No log file found at $SERVER_DIR/logs/latest.log"
    fi
}

# Main script logic
case "$1" in
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    restart)
        restart_server
        ;;
    status)
        status_server
        ;;
    logs)
        show_logs
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs}"
        echo ""
        echo "Commands:"
        echo "  start   - Start the Minecraft server"
        echo "  stop    - Stop the Minecraft server"
        echo "  restart - Restart the Minecraft server"
        echo "  status  - Check if server is running"
        echo "  logs    - Show latest server logs"
        exit 1
        ;;
esac
