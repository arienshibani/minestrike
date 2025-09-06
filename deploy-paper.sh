#!/bin/bash

# Paper Minecraft Server Deployment Script
# Simplified deployment for EC2 instances

set -e

# Configuration
SERVER_USER="ubuntu"
SERVER_HOST="${EC2_HOST}"
SSH_KEY="${SSH_PRIVATE_KEY}"
PAPER_VERSION="1.20.4"
SERVER_DIR="/opt/minecraft"
SERVICE_NAME="minecraft-server"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Check if running in GitHub Actions
if [ -n "$GITHUB_ACTIONS" ]; then
    print_status "Running in GitHub Actions environment"
    if [ -z "$SERVER_HOST" ] || [ -z "$SSH_KEY" ]; then
        print_error "Missing required environment variables: EC2_HOST, SSH_PRIVATE_KEY"
        exit 1
    fi
else
    print_error "This script is designed for GitHub Actions deployment."
    exit 1
fi

# Test SSH connection
test_ssh() {
    print_status "Testing SSH connection..."
    if ! ssh -i ~/.ssh/id_rsa -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_HOST" "echo 'SSH connection successful'"; then
        print_error "SSH connection failed. Please check your credentials and server status."
        exit 1
    fi
}

# Stop existing server
stop_server() {
    print_status "Stopping existing Minecraft server..."
    ssh -i ~/.ssh/id_rsa "$SERVER_USER@$SERVER_HOST" << 'EOF'
        # Stop systemd service
        sudo systemctl stop minecraft-server 2>/dev/null || true
        
        # Kill any running Java processes (Minecraft servers)
        sudo pkill -f "java.*minecraft" 2>/dev/null || true
        sudo pkill -f "java.*paper" 2>/dev/null || true
        
        # Wait for processes to stop
        sleep 5
        
        echo "Server stopped"
EOF
}

# Install Java and dependencies
install_dependencies() {
    print_status "Installing Java and dependencies..."
    ssh -i ~/.ssh/id_rsa "$SERVER_USER@$SERVER_HOST" << 'EOF'
        # Update system
        sudo apt update
        
        # Install Java 17 (required for Paper 1.20.4)
        if ! java -version 2>&1 | grep -q "17\|18\|19\|20\|21\|22"; then
            echo "Installing Java 17..."
            sudo apt install -y openjdk-17-jdk
        fi
        
        # Install other dependencies
        sudo apt install -y curl wget unzip screen netcat-openbsd
        
        echo "Dependencies installed"
EOF
}

# Create server directory structure
setup_directories() {
    print_status "Setting up server directories..."
    ssh -i ~/.ssh/id_rsa "$SERVER_USER@$SERVER_HOST" << 'EOF'
        # Create server directory
        sudo mkdir -p /opt/minecraft
        sudo chown ubuntu:ubuntu /opt/minecraft
        
        # Create subdirectories
        mkdir -p /opt/minecraft/plugins
        mkdir -p /opt/minecraft/worlds
        mkdir -p /opt/minecraft/logs
        
        echo "Directories created"
EOF
}

# Download Paper server
download_paper() {
    print_status "Downloading Paper server..."
    ssh -i ~/.ssh/id_rsa "$SERVER_USER@$SERVER_HOST" << EOF
        cd /opt/minecraft
        
        # Get latest Paper build for version $PAPER_VERSION
        PAPER_BUILD=\$(curl -s "https://api.papermc.io/v2/projects/paper/versions/$PAPER_VERSION" | grep -o '"builds":\[[^]]*\]' | grep -o '[0-9]*' | tail -1)
        DOWNLOAD_URL="https://api.papermc.io/v2/projects/paper/versions/$PAPER_VERSION/builds/\$PAPER_BUILD/downloads/paper-$PAPER_VERSION-\$PAPER_BUILD.jar"
        
        echo "Downloading Paper from: \$DOWNLOAD_URL"
        curl -L -o server.jar "\$DOWNLOAD_URL"
        
        echo "Paper downloaded successfully"
EOF
}

# Deploy server configuration
deploy_config() {
    print_status "Deploying server configuration..."
    
    # Copy server.properties
    scp -i ~/.ssh/id_rsa server/server.properties "$SERVER_USER@$SERVER_HOST:/opt/minecraft/"
    
    # Copy plugins if they exist
    if [ -d "server/plugins" ] && [ "$(ls -A server/plugins)" ]; then
        scp -i ~/.ssh/id_rsa -r server/plugins/* "$SERVER_USER@$SERVER_HOST:/opt/minecraft/plugins/"
    fi
    
    # Copy worlds if they exist
    if [ -d "server/worlds" ] && [ "$(ls -A server/worlds)" ]; then
        scp -i ~/.ssh/id_rsa -r server/worlds/* "$SERVER_USER@$SERVER_HOST:/opt/minecraft/worlds/"
    fi
    
    # Copy any other config files
    if [ -d "server/config" ] && [ "$(ls -A server/config)" ]; then
        scp -i ~/.ssh/id_rsa -r server/config/* "$SERVER_USER@$SERVER_HOST:/opt/minecraft/"
    fi
}

# Create systemd service
create_service() {
    print_status "Creating systemd service..."
    ssh -i ~/.ssh/id_rsa "$SERVER_USER@$SERVER_HOST" << 'EOF'
        # Create systemd service file
        sudo tee /etc/systemd/system/minecraft-server.service > /dev/null << 'SERVICE_EOF'
[Unit]
Description=Minecraft Paper Server
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/minecraft
ExecStart=/usr/bin/java -Xms2G -Xmx4G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -jar server.jar nogui
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE_EOF

        # Reload systemd and enable service
        sudo systemctl daemon-reload
        sudo systemctl enable minecraft-server
        
        echo "Systemd service created"
EOF
}

# Configure firewall
setup_firewall() {
    print_status "Configuring firewall..."
    ssh -i ~/.ssh/id_rsa "$SERVER_USER@$SERVER_HOST" << 'EOF'
        sudo ufw --force enable
        sudo ufw allow 22/tcp
        sudo ufw allow 25565/tcp
        sudo ufw allow 25575/tcp
        echo "Firewall configured"
EOF
}

# Start server
start_server() {
    print_status "Starting Minecraft server..."
    ssh -i ~/.ssh/id_rsa "$SERVER_USER@$SERVER_HOST" << 'EOF'
        # Start the service
        sudo systemctl start minecraft-server
        
        # Wait for server to start
        sleep 15
        
        # Check if service is running
        if sudo systemctl is-active --quiet minecraft-server; then
            echo "✅ Minecraft server is running!"
        else
            echo "❌ Minecraft server failed to start"
            sudo systemctl status minecraft-server --no-pager
            exit 1
        fi
EOF
}

# Verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    ssh -i ~/.ssh/id_rsa "$SERVER_USER@$SERVER_HOST" << 'EOF'
        echo "🔍 Verifying deployment..."
        
        # Check if service is running
        if sudo systemctl is-active --quiet minecraft-server; then
            echo "✅ Minecraft server service is running"
        else
            echo "❌ Minecraft server service is not running"
            exit 1
        fi
        
        # Check if port is listening
        if nc -z localhost 25565; then
            echo "✅ Port 25565 is accessible"
        else
            echo "❌ Port 25565 is not accessible"
            exit 1
        fi
        
        # Show service status
        echo "📊 Service status:"
        sudo systemctl status minecraft-server --no-pager -l
        
        # Show external IP
        echo "🌐 External IP: $(curl -s ifconfig.me)"
        
        echo "🎉 Deployment verification completed!"
EOF
}

# Main deployment function
deploy() {
    print_header "Paper Minecraft Server Deployment"
    
    test_ssh
    stop_server
    install_dependencies
    setup_directories
    download_paper
    deploy_config
    create_service
    setup_firewall
    start_server
    verify_deployment
    
    print_header "Deployment Complete! 🎉"
    echo ""
    echo "🎮 Minecraft Server: $SERVER_HOST:25565"
    echo "🔧 Server Management:"
    echo "   Start: sudo systemctl start minecraft-server"
    echo "   Stop: sudo systemctl stop minecraft-server"
    echo "   Restart: sudo systemctl restart minecraft-server"
    echo "   Status: sudo systemctl status minecraft-server"
    echo "   Logs: sudo journalctl -u minecraft-server -f"
    echo ""
    echo "📁 Server Directory: /opt/minecraft"
    echo "🔧 Config Files: /opt/minecraft/server.properties"
    echo "🔌 Plugins: /opt/minecraft/plugins/"
    echo "🗺️ Worlds: /opt/minecraft/worlds/"
}

# Run deployment
deploy
