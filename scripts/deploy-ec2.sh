#!/bin/bash

# EC2 Deployment Script for Minecraft Server
# This script sets up a Minecraft server on Ubuntu EC2 instance

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration - UPDATE THESE VALUES
MINECRAFT_USER="minecraft"
MINECRAFT_HOME="/opt/minecraft"
SERVER_DIR="$MINECRAFT_HOME/server"
LOGS_DIR="$MINECRAFT_HOME/logs"
SCRIPTS_DIR="$MINECRAFT_HOME/scripts"
PAPER_VERSION="1.20.4"
PAPER_BUILD="latest"

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

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Update system packages
update_system() {
    print_header "Updating System Packages"
    
    apt update
    apt upgrade -y
    apt install -y curl wget screen netcat-openbsd unzip
    
    print_status "System packages updated"
}

# Install Java 17
install_java() {
    print_header "Installing Java 17"
    
    apt install -y openjdk-17-jdk
    
    # Verify installation
    java_version=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
    print_status "Java version installed: $java_version"
    
    if [ "$java_version" -lt 17 ]; then
        print_error "Java 17 installation failed"
        exit 1
    fi
}

# Create minecraft user
create_user() {
    print_header "Creating Minecraft User"
    
    if id "$MINECRAFT_USER" &>/dev/null; then
        print_warning "User $MINECRAFT_USER already exists"
    else
        useradd -r -s /bin/bash -d "$MINECRAFT_HOME" "$MINECRAFT_USER"
        print_status "Created user: $MINECRAFT_USER"
    fi
    
    # Create directories
    mkdir -p "$MINECRAFT_HOME"
    mkdir -p "$SERVER_DIR"
    mkdir -p "$LOGS_DIR"
    mkdir -p "$SCRIPTS_DIR"
    mkdir -p "$SERVER_DIR/mods"
    mkdir -p "$SERVER_DIR/plugins"
    mkdir -p "$SERVER_DIR/world"
    mkdir -p "$SERVER_DIR/config"
    
    # Set ownership
    chown -R "$MINECRAFT_USER:$MINECRAFT_USER" "$MINECRAFT_HOME"
    
    print_status "Created directory structure"
}

# Download Paper server
download_paper() {
    print_header "Downloading Paper Server"
    
    # Get latest build number
    if [ "$PAPER_BUILD" == "latest" ]; then
        PAPER_BUILD=$(curl -s "https://api.papermc.io/v2/projects/paper/versions/$PAPER_VERSION" | grep -o '"builds":\[[^]]*\]' | grep -o '[0-9]*' | tail -1)
    fi
    
    DOWNLOAD_URL="https://api.papermc.io/v2/projects/paper/versions/$PAPER_VERSION/builds/$PAPER_BUILD/downloads/paper-$PAPER_VERSION-$PAPER_BUILD.jar"
    
    print_status "Downloading Paper $PAPER_VERSION build $PAPER_BUILD..."
    
    cd "$SERVER_DIR"
    curl -L -o server.jar "$DOWNLOAD_URL"
    
    # Set ownership
    chown "$MINECRAFT_USER:$MINECRAFT_USER" server.jar
    
    print_status "Paper server downloaded successfully"
}

# Create server configuration
create_server_config() {
    print_header "Creating Server Configuration"
    
    # Create server.properties
    cat > "$SERVER_DIR/server.properties" << 'EOF'
# Minecraft server.properties
server-name=MineStrike Server
motd=\u00a76MineStrike Server \u00a7f- \u00a7eModded Minecraft Server
server-port=25565
query.port=25565
enable-query=true
enable-rcon=true
rcon.port=25575
rcon.password=changeme123

gamemode=survival
difficulty=normal
hardcore=false
pvp=true
allow-flight=false
allow-nether=true
level-name=world
level-seed=
level-type=minecraft\:normal
generate-structures=true

max-players=20
max-world-size=29999984
spawn-protection=16
view-distance=10
simulation-distance=10
player-idle-timeout=0
max-tick-time=60000

spawn-animals=true
spawn-monsters=true
spawn-npcs=true

online-mode=true
prevent-proxy-connections=false
network-compression-threshold=256
max-build-height=320

use-native-transport=true
enable-jmx-monitoring=false

log-ips=true
function-permission-level=2

enforce-whitelist=false
whitelist=false
enforce-secure-profile=true
EOF

    # Create eula.txt
    cat > "$SERVER_DIR/eula.txt" << 'EOF'
# Minecraft eula.txt
eula=true
EOF

    # Set ownership
    chown "$MINECRAFT_USER:$MINECRAFT_USER" "$SERVER_DIR/server.properties" "$SERVER_DIR/eula.txt"
    
    print_status "Server configuration created"
}

# Create management scripts
create_scripts() {
    print_header "Creating Management Scripts"
    
    # Create server management script
    cat > "$SCRIPTS_DIR/server.sh" << 'EOF'
#!/bin/bash

# Minecraft Server Management Script for EC2
SERVER_DIR="/opt/minecraft/server"
LOGS_DIR="/opt/minecraft/logs"
SCREEN_NAME="minecraft-server"
SERVER_JAR="server.jar"
JAVA_OPTS="-Xmx4G -Xms2G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

start_server() {
    print_status "Starting Minecraft server..."
    
    if screen -list | grep -q "$SCREEN_NAME"; then
        print_warning "Server is already running!"
        return 1
    fi
    
    cd "$SERVER_DIR"
    sudo -u minecraft screen -dmS "$SCREEN_NAME" java $JAVA_OPTS -jar "$SERVER_JAR" nogui
    
    sleep 3
    
    if screen -list | grep -q "$SCREEN_NAME"; then
        print_status "Server started successfully!"
        print_status "Use 'screen -r $SCREEN_NAME' to attach to the server console"
    else
        print_error "Failed to start server!"
        return 1
    fi
}

stop_server() {
    print_status "Stopping Minecraft server..."
    
    if ! screen -list | grep -q "$SCREEN_NAME"; then
        print_warning "Server is not running!"
        return 1
    fi
    
    screen -S "$SCREEN_NAME" -X stuff "stop$(printf \\r)"
    sleep 5
    
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

restart_server() {
    print_status "Restarting Minecraft server..."
    stop_server
    sleep 2
    start_server
}

status_server() {
    if screen -list | grep -q "$SCREEN_NAME"; then
        print_status "Server is running"
        print_status "Screen session: $SCREEN_NAME"
        print_status "Use 'screen -r $SCREEN_NAME' to attach to console"
    else
        print_status "Server is not running"
    fi
}

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
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
EOF

    # Create port test script
    cat > "$SCRIPTS_DIR/test-port.sh" << 'EOF'
#!/bin/bash

PORT=25565
HOST="localhost"

echo "Testing Minecraft server port $PORT on $HOST..."

if nc -z $HOST $PORT 2>/dev/null; then
    echo "✅ Port $PORT is open and accessible"
    timeout 5 nc $HOST $PORT < /dev/null 2>/dev/null && echo "✅ Server is responding" || echo "⚠️  Port is open but server may not be running"
else
    echo "❌ Port $PORT is not accessible"
    echo "Make sure the server is running and firewall allows the connection"
fi

echo ""
echo "External IP: $(curl -s ifconfig.me)"
echo "To test from another machine: nc -z $(curl -s ifconfig.me) $PORT"
EOF

    # Make scripts executable
    chmod +x "$SCRIPTS_DIR/server.sh"
    chmod +x "$SCRIPTS_DIR/test-port.sh"
    
    # Set ownership
    chown -R "$MINECRAFT_USER:$MINECRAFT_USER" "$SCRIPTS_DIR"
    
    print_status "Management scripts created"
}

# Setup systemd service
setup_systemd() {
    print_header "Setting Up Systemd Service"
    
    # Copy systemd service file
    cp /opt/minecraft/scripts/minecraft-server.service /etc/systemd/system/
    
    # Reload systemd
    systemctl daemon-reload
    
    # Enable service
    systemctl enable minecraft-server
    
    print_status "Systemd service configured"
    print_status "Use 'systemctl start minecraft-server' to start the service"
    print_status "Use 'systemctl status minecraft-server' to check status"
}

# Configure firewall
configure_firewall() {
    print_header "Configuring Firewall"
    
    # Enable UFW if not already enabled
    ufw --force enable
    
    # Allow SSH
    ufw allow 22/tcp
    
    # Allow Minecraft
    ufw allow 25565/tcp
    
    # Allow RCON (optional)
    ufw allow 25575/tcp
    
    print_status "Firewall configured"
    print_status "Allowed ports: 22 (SSH), 25565 (Minecraft), 25575 (RCON)"
}

# Main setup function
main() {
    print_header "EC2 Minecraft Server Setup"
    
    check_root
    update_system
    install_java
    create_user
    download_paper
    create_server_config
    create_scripts
    setup_systemd
    configure_firewall
    
    print_header "Setup Complete!"
    
    echo ""
    print_status "Server is ready! Next steps:"
    echo "1. Start the server: sudo systemctl start minecraft-server"
    echo "2. Check status: sudo systemctl status minecraft-server"
    echo "3. Test port: sudo -u minecraft /opt/minecraft/scripts/test-port.sh"
    echo "4. View logs: sudo journalctl -u minecraft-server -f"
    echo ""
    print_status "Server files: $SERVER_DIR"
    print_status "Logs: $LOGS_DIR"
    print_status "Scripts: $SCRIPTS_DIR"
    echo ""
    print_warning "Important:"
    echo "- Change RCON password in $SERVER_DIR/server.properties"
    echo "- Configure server settings as needed"
    echo "- The server will start automatically on reboot"
    echo ""
    print_status "External IP: $(curl -s ifconfig.me)"
}

# Run main function
main "$@"
