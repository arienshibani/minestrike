#!/bin/bash

# Simple deployment script for EC2 instances
# This replaces the complex GitHub Actions workflow with a simple, maintainable solution

set -e

# Configuration
SERVER_USER="ubuntu"
SERVER_HOST=""
SSH_KEY=""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# Check if required files exist
check_files() {
    local required_files=("docker-compose.yml" "setup.sh" "nginx.conf")
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            print_error "Required file not found: $file"
            exit 1
        fi
    done
}

# Get server details
get_server_info() {
    if [ -z "$SERVER_HOST" ]; then
        read -p "Enter EC2 server IP or hostname: " SERVER_HOST
    fi
    
    if [ -z "$SSH_KEY" ]; then
        read -p "Enter path to SSH private key: " SSH_KEY
    fi
    
    if [ ! -f "$SSH_KEY" ]; then
        print_error "SSH key file not found: $SSH_KEY"
        exit 1
    fi
}

# Test SSH connection
test_ssh() {
    print_status "Testing SSH connection..."
    if ! ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_HOST" "echo 'SSH connection successful'"; then
        print_error "SSH connection failed. Please check your credentials and server status."
        exit 1
    fi
}

# Install Docker on remote server
install_docker() {
    print_status "Installing Docker on remote server..."
    ssh -i "$SSH_KEY" "$SERVER_USER@$SERVER_HOST" << 'EOF'
        # Update system
        sudo apt update
        sudo apt upgrade -y
        
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

# Deploy files to server
deploy_files() {
    print_status "Deploying files to server..."
    
    # Create deployment directory
    ssh -i "$SSH_KEY" "$SERVER_USER@$SERVER_HOST" "mkdir -p ~/minecraft-server"
    
    # Copy files
    scp -i "$SSH_KEY" docker-compose.yml "$SERVER_USER@$SERVER_HOST:~/minecraft-server/"
    scp -i "$SSH_KEY" setup.sh "$SERVER_USER@$SERVER_HOST:~/minecraft-server/"
    scp -i "$SSH_KEY" nginx.conf "$SERVER_USER@$SERVER_HOST:~/minecraft-server/"
    scp -i "$SSH_KEY" backup.sh "$SERVER_USER@$SERVER_HOST:~/minecraft-server/"
    
    # Make scripts executable
    ssh -i "$SSH_KEY" "$SERVER_USER@$SERVER_HOST" "chmod +x ~/minecraft-server/*.sh"
}

# Setup firewall
setup_firewall() {
    print_status "Configuring firewall..."
    ssh -i "$SSH_KEY" "$SERVER_USER@$SERVER_HOST" << 'EOF'
        sudo ufw --force enable
        sudo ufw allow 22/tcp
        sudo ufw allow 80/tcp
        sudo ufw allow 443/tcp
        sudo ufw allow 25565/tcp
        sudo ufw allow 25575/tcp
        sudo ufw allow 8000/tcp
        echo "Firewall configured"
EOF
}

# Run setup on remote server
run_setup() {
    print_status "Running setup on remote server..."
    ssh -i "$SSH_KEY" "$SERVER_USER@$SERVER_HOST" << 'EOF'
        cd ~/minecraft-server
        ./setup.sh
EOF
}

# Setup automated backups
setup_backups() {
    print_status "Setting up automated backups..."
    ssh -i "$SSH_KEY" "$SERVER_USER@$SERVER_HOST" << 'EOF'
        # Create backup script in system location
        sudo cp ~/minecraft-server/backup.sh /usr/local/bin/minecraft-backup.sh
        sudo chmod +x /usr/local/bin/minecraft-backup.sh
        
        # Create cron job for daily backups at 3 AM
        (crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/minecraft-backup.sh >> /var/log/minecraft-backup.log 2>&1") | crontab -
        
        echo "Automated backups configured"
EOF
}

# Main deployment function
deploy() {
    print_header "Minecraft Server Deployment"
    
    check_files
    get_server_info
    test_ssh
    install_docker
    deploy_files
    setup_firewall
    run_setup
    setup_backups
    
    print_header "Deployment Complete! 🎉"
    echo ""
    echo "🌐 Access your Minecraft server management panel at:"
    echo "   http://$SERVER_HOST:8000"
    echo ""
    echo "🎮 Default login credentials:"
    echo "   Username: admin"
    echo "   Password: admin"
    echo ""
    echo "⚠️  IMPORTANT: Change the default password after first login!"
    echo ""
    echo "📋 Next steps:"
    echo "   1. Open http://$SERVER_HOST:8000 in your browser"
    echo "   2. Login with admin/admin"
    echo "   3. Change the admin password"
    echo "   4. Create your first Minecraft server"
    echo "   5. Upload your custom world through the web interface"
    echo ""
    echo "🔧 Server management:"
    echo "   SSH to server: ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST"
    echo "   View logs: ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST 'cd ~/minecraft-server && docker-compose logs -f'"
    echo "   Restart: ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST 'cd ~/minecraft-server && docker-compose restart'"
}

# Show usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --host HOST     EC2 server IP or hostname"
    echo "  -k, --key PATH      Path to SSH private key"
    echo "  -u, --user USER     SSH username (default: ubuntu)"
    echo "  --help              Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 --host 1.2.3.4 --key ~/.ssh/my-key.pem"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--host)
            SERVER_HOST="$2"
            shift 2
            ;;
        -k|--key)
            SSH_KEY="$2"
            shift 2
            ;;
        -u|--user)
            SERVER_USER="$2"
            shift 2
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Run deployment
deploy
