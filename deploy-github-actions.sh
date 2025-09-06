#!/bin/bash

# GitHub Actions deployment script
# This script is optimized for automated deployment via GitHub Actions

set -e

# Configuration (set by GitHub Actions)
SERVER_USER="${EC2_USER:-ubuntu}"
SERVER_HOST="${EC2_HOST}"
SSH_KEY="${SSH_PRIVATE_KEY}"

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
    # Use environment variables set by GitHub Actions
    if [ -z "$SERVER_HOST" ] || [ -z "$SSH_KEY" ]; then
        print_error "Missing required environment variables: EC2_HOST, SSH_PRIVATE_KEY"
        exit 1
    fi
else
    print_error "This script is designed for GitHub Actions. Use deploy.sh for manual deployment."
    exit 1
fi

# Check if required files exist
check_files() {
    local required_files=("docker-compose.yml" "setup.sh" "backup.sh")
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            print_error "Required file not found: $file"
            exit 1
        fi
    done
}

# Test SSH connection
test_ssh() {
    print_status "Testing SSH connection..."
    if ! ssh -i ~/.ssh/id_rsa -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_HOST" "echo 'SSH connection successful'"; then
        print_error "SSH connection failed. Please check your credentials and server status."
        exit 1
    fi
}

# Deploy files to server
deploy_files() {
    print_status "Deploying files to server..."
    
    # Create deployment directory
    ssh -i ~/.ssh/id_rsa "$SERVER_USER@$SERVER_HOST" "mkdir -p ~/minecraft-server"
    
    # Copy files
    scp -i ~/.ssh/id_rsa docker-compose.yml "$SERVER_USER@$SERVER_HOST:~/minecraft-server/"
    scp -i ~/.ssh/id_rsa setup.sh "$SERVER_USER@$SERVER_HOST:~/minecraft-server/"
    scp -i ~/.ssh/id_rsa backup.sh "$SERVER_USER@$SERVER_HOST:~/minecraft-server/"
    
    # Make scripts executable
    ssh -i ~/.ssh/id_rsa "$SERVER_USER@$SERVER_HOST" "chmod +x ~/minecraft-server/*.sh"
}

# Install Docker on remote server
install_docker() {
    print_status "Installing Docker on remote server..."
    ssh -i ~/.ssh/id_rsa "$SERVER_USER@$SERVER_HOST" << 'EOF'
        # Update system
        sudo apt update
        sudo apt upgrade -y
        
        # Stop any existing Minecraft services
        echo "🛑 Stopping any existing Minecraft services..."
        sudo systemctl stop minecraft-server 2>/dev/null || true
        sudo systemctl disable minecraft-server 2>/dev/null || true
        
        # Kill any processes using port 25565
        sudo fuser -k 25565/tcp 2>/dev/null || true
        
        # Install Docker if not present
        if ! command -v docker &> /dev/null; then
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            sudo usermod -aG docker $USER
            rm get-docker.sh
        fi
        
        # Install Docker Compose if not present
        if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
            sudo apt install -y docker-compose-plugin
        fi
        
        echo "Docker installation completed"
EOF
}

# Setup firewall
setup_firewall() {
    print_status "Configuring firewall..."
    ssh -i ~/.ssh/id_rsa "$SERVER_USER@$SERVER_HOST" << 'EOF'
        sudo ufw --force enable
        sudo ufw allow 22/tcp
        sudo ufw allow 80/tcp
        sudo ufw allow 443/tcp
        sudo ufw allow 25565/tcp
        sudo ufw allow 25575/tcp
        sudo ufw allow 8443/tcp
        echo "Firewall configured"
EOF
}

# Start services
start_services() {
    print_status "Starting MineOS..."
    ssh -i ~/.ssh/id_rsa "$SERVER_USER@$SERVER_HOST" << 'EOF'
        cd ~/minecraft-server
        
        # Stop any existing Docker containers
        echo "🛑 Stopping any existing Docker containers..."
        if command -v docker-compose &> /dev/null; then
            docker-compose down 2>/dev/null || true
        else
            docker compose down 2>/dev/null || true
        fi
        
        # Remove any existing containers
        docker stop mineos 2>/dev/null || true
        docker rm mineos 2>/dev/null || true
        
        # Start services
        if command -v docker-compose &> /dev/null; then
            docker-compose up -d
        else
            docker compose up -d
        fi
        
        # Wait for services to start
        sleep 15
        
        # Check if services are running
        if docker ps | grep -q mineos; then
            echo "✅ MineOS is running!"
        else
            echo "❌ MineOS failed to start"
            docker compose logs
            exit 1
        fi
EOF
}

# Setup automated backups
setup_backups() {
    print_status "Setting up automated backups..."
    ssh -i ~/.ssh/id_rsa "$SERVER_USER@$SERVER_HOST" << 'EOF'
        # Create backup script in system location
        sudo cp ~/minecraft-server/backup.sh /usr/local/bin/minecraft-backup.sh
        sudo chmod +x /usr/local/bin/minecraft-backup.sh
        
        # Create cron job for daily backups at 3 AM
        (crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/minecraft-backup.sh >> /var/log/minecraft-backup.log 2>&1") | crontab -
        
        echo "Automated backups configured"
EOF
}

# Verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    ssh -i ~/.ssh/id_rsa "$SERVER_USER@$SERVER_HOST" << 'EOF'
        echo "🔍 Verifying deployment..."
        
        # Check if MineOS is running
        if docker ps | grep -q mineos; then
            echo "✅ MineOS is running"
        else
            echo "❌ MineOS is not running"
            exit 1
        fi
        
        # Check if web panel port is accessible
        if nc -z localhost 8443; then
            echo "✅ Web panel port 8443 is accessible"
        else
            echo "❌ Web panel port 8443 is not accessible"
            exit 1
        fi
        
        # Show service status
        echo "📊 Service status:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        # Show external IP
        echo "🌐 External IP: $(curl -s ifconfig.me)"
        
        echo "🎉 Deployment verification completed!"
EOF
}

# Main deployment function
deploy() {
    print_header "GitHub Actions Minecraft Server Deployment"
    
    check_files
    test_ssh
    install_docker
    deploy_files
    setup_firewall
    start_services
    setup_backups
    verify_deployment
    
    print_header "Deployment Complete! 🎉"
    echo ""
    echo "🌐 Access your Minecraft server management panel at:"
    echo "   https://$SERVER_HOST:8443"
    echo ""
    echo "🎮 Default login credentials:"
    echo "   Username: mc"
    echo "   Password: mc"
    echo ""
    echo "⚠️  IMPORTANT: Change the default password after first login!"
    echo ""
    echo "📋 Next steps:"
    echo "   1. Open https://$SERVER_HOST:8443 in your browser"
    echo "   2. Login with mc/mc"
    echo "   3. Change the admin password"
    echo "   4. Create your first Minecraft server"
    echo "   5. Upload your custom world through the web interface"
}

# Run deployment
deploy
