#!/bin/bash

# Minecraft Server Setup Script for Local Development
# This script sets up a Minecraft server with mods support

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="/opt/minecraft"
SERVER_DIR="$PROJECT_DIR/server"
SCRIPTS_DIR="$PROJECT_DIR/scripts"
LOGS_DIR="$PROJECT_DIR/logs"
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

# Check if running on macOS or Linux
check_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        print_status "Detected macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        print_status "Detected Linux"
    else
        print_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
}

# Check Java installation
check_java() {
    print_header "Checking Java Installation"
    
    if command -v java &> /dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
        print_status "Java version: $JAVA_VERSION"
        
        if [ "$JAVA_VERSION" -lt 17 ]; then
            print_error "Java 17 or higher is required. Current version: $JAVA_VERSION"
            print_status "Please install Java 17 or higher:"
            if [ "$OS" == "macos" ]; then
                print_status "brew install openjdk@17"
            else
                print_status "sudo apt update && sudo apt install openjdk-17-jdk"
            fi
            exit 1
        fi
    else
        print_error "Java is not installed!"
        print_status "Please install Java 17 or higher:"
        if [ "$OS" == "macos" ]; then
            print_status "brew install openjdk@17"
        else
            print_status "sudo apt update && sudo apt install openjdk-17-jdk"
        fi
        exit 1
    fi
}

# Check required tools
check_tools() {
    print_header "Checking Required Tools"
    
    # Check for curl/wget
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        print_error "curl or wget is required but not installed"
        exit 1
    fi
    
    # Check for screen
    if ! command -v screen &> /dev/null; then
        print_warning "Screen is not installed. Installing..."
        if [ "$OS" == "macos" ]; then
            if command -v brew &> /dev/null; then
                brew install screen
            else
                print_error "Homebrew not found. Please install screen manually: brew install screen"
                exit 1
            fi
        else
            sudo apt update && sudo apt install -y screen
        fi
    else
        print_status "Screen is already installed"
    fi
    
    # Check for netcat (for port testing)
    if ! command -v nc &> /dev/null; then
        print_warning "netcat is not installed. Installing..."
        if [ "$OS" == "macos" ]; then
            if command -v brew &> /dev/null; then
                brew install netcat
            else
                print_warning "Homebrew not found. netcat will be installed as part of macOS"
            fi
        else
            sudo apt update && sudo apt install -y netcat
        fi
    else
        print_status "netcat is already installed"
    fi
}

# Download Paper server
download_paper() {
    print_header "Downloading Paper Server"
    
    if [ -f "$SERVER_DIR/server.jar" ]; then
        print_warning "Server jar already exists. Skipping download."
        return
    fi
    
    print_status "Downloading Paper $PAPER_VERSION..."
    
    # Get latest build number
    if [ "$PAPER_BUILD" == "latest" ]; then
        if command -v curl &> /dev/null; then
            PAPER_BUILD=$(curl -s "https://api.papermc.io/v2/projects/paper/versions/$PAPER_VERSION" | grep -o '"builds":\[[^]]*\]' | grep -o '[0-9]*' | tail -1)
        else
            PAPER_BUILD=$(wget -qO- "https://api.papermc.io/v2/projects/paper/versions/$PAPER_VERSION" | grep -o '"builds":\[[^]]*\]' | grep -o '[0-9]*' | tail -1)
        fi
    fi
    
    DOWNLOAD_URL="https://api.papermc.io/v2/projects/paper/versions/$PAPER_VERSION/builds/$PAPER_BUILD/downloads/paper-$PAPER_VERSION-$PAPER_BUILD.jar"
    
    print_status "Downloading from: $DOWNLOAD_URL"
    
    cd "$SERVER_DIR"
    if command -v curl &> /dev/null; then
        curl -L -o server.jar "$DOWNLOAD_URL"
    else
        wget -O server.jar "$DOWNLOAD_URL"
    fi
    
    if [ -f "server.jar" ]; then
        print_status "Paper server downloaded successfully!"
    else
        print_error "Failed to download Paper server"
        exit 1
    fi
}

# Create necessary directories and files
setup_directories() {
    print_header "Setting Up Directories"
    
    # Create directories
    mkdir -p "$SERVER_DIR/mods"
    mkdir -p "$SERVER_DIR/plugins"
    mkdir -p "$SERVER_DIR/world"
    mkdir -p "$SERVER_DIR/config"
    mkdir -p "$LOGS_DIR"
    
    print_status "Created directory structure"
}

# Create startup script
create_startup_script() {
    print_header "Creating Startup Script"
    
    cat > "$SCRIPTS_DIR/start-server.sh" << 'EOF'
#!/bin/bash
# Quick start script for Minecraft server

cd /opt/minecraft
./scripts/server.sh start

echo "Server started! Use './scripts/server.sh status' to check status"
echo "Use './scripts/server.sh logs' to view logs"
echo "Use 'screen -r minecraft-server' to attach to console"
EOF
    
    chmod +x "$SCRIPTS_DIR/start-server.sh"
    print_status "Created startup script"
}

# Create port test script
create_port_test_script() {
    print_header "Creating Port Test Script"
    
    cat > "$SCRIPTS_DIR/test-port.sh" << 'EOF'
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
EOF
    
    chmod +x "$SCRIPTS_DIR/test-port.sh"
    print_status "Created port test script"
}

# Create mod installation script
create_mod_script() {
    print_header "Creating Mod Management Script"
    
    cat > "$SCRIPTS_DIR/install-mod.sh" << 'EOF'
#!/bin/bash

# Mod installation script for Minecraft server
# Usage: ./install-mod.sh <mod_url_or_path>

if [ $# -eq 0 ]; then
    echo "Usage: $0 <mod_url_or_path>"
    echo "Example: $0 https://example.com/mod.jar"
    echo "Example: $0 /path/to/mod.jar"
    exit 1
fi

MOD_SOURCE="$1"
MODS_DIR="/opt/minecraft/server/mods"

echo "Installing mod from: $MOD_SOURCE"

# Check if it's a URL or local file
if [[ $MOD_SOURCE == http* ]]; then
    # Download mod
    MOD_NAME=$(basename "$MOD_SOURCE")
    echo "Downloading mod: $MOD_NAME"
    
    if command -v curl &> /dev/null; then
        curl -L -o "$MODS_DIR/$MOD_NAME" "$MOD_SOURCE"
    else
        wget -O "$MODS_DIR/$MOD_NAME" "$MOD_SOURCE"
    fi
    
    if [ -f "$MODS_DIR/$MOD_NAME" ]; then
        echo "✅ Mod downloaded successfully: $MOD_NAME"
    else
        echo "❌ Failed to download mod"
        exit 1
    fi
else
    # Copy local file
    if [ -f "$MOD_SOURCE" ]; then
        MOD_NAME=$(basename "$MOD_SOURCE")
        cp "$MOD_SOURCE" "$MODS_DIR/$MOD_NAME"
        echo "✅ Mod copied successfully: $MOD_NAME"
    else
        echo "❌ Mod file not found: $MOD_SOURCE"
        exit 1
    fi
fi

echo ""
echo "⚠️  Remember to restart the server for the mod to take effect:"
echo "./scripts/server.sh restart"
EOF
    
    chmod +x "$SCRIPTS_DIR/install-mod.sh"
    print_status "Created mod installation script"
}

# Main setup function
main() {
    print_header "Minecraft Server Setup for Local Development"
    
    check_os
    check_java
    check_tools
    setup_directories
    download_paper
    create_startup_script
    create_port_test_script
    create_mod_script
    
    print_header "Setup Complete!"
    
    echo ""
    print_status "Next steps:"
    echo "1. Start the server: ./scripts/server.sh start"
    echo "2. Test the port: ./scripts/test-port.sh"
    echo "3. Attach to console: screen -r minecraft-server"
    echo "4. Install mods: ./scripts/install-mod.sh <mod_url>"
    echo ""
    print_status "Server files are located in: $SERVER_DIR"
    print_status "Logs are located in: $LOGS_DIR"
    print_status "Scripts are located in: $SCRIPTS_DIR"
    echo ""
    print_warning "Don't forget to:"
    echo "- Change the RCON password in server.properties"
    echo "- Configure your server settings"
    echo "- Add your first mods to test the setup"
}

# Run main function
main "$@"
