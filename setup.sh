#!/bin/bash

# Modern Minecraft Server Management Setup
# This script sets up Crafty Controller with Docker

set -e

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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root for security reasons"
   exit 1
fi

print_header "Minecraft Server Management Setup"
echo "This will set up Crafty Controller with Docker for easy server management"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first:"
    echo "  Ubuntu/Debian: curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh"
    echo "  macOS: brew install docker"
    echo "  Windows: Download Docker Desktop from docker.com"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create necessary directories
print_status "Creating directories..."
mkdir -p backups
mkdir -p maps
mkdir -p ssl

# Set proper permissions
print_status "Setting permissions..."
chmod 755 backups maps ssl

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found. Please ensure you're in the correct directory."
    exit 1
fi

# Start the services
print_status "Starting MCSManager..."
if command -v docker-compose &> /dev/null; then
    docker-compose up -d
else
    docker compose up -d
fi

# Wait for services to start
print_status "Waiting for services to start..."
sleep 15

# Check if services are running
if docker ps | grep -q mcsmanager; then
    print_status "✅ MCSManager is running!"
else
    print_error "❌ MCSManager failed to start. Check logs with: docker-compose logs"
    exit 1
fi

# Get the server IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")

print_header "Setup Complete! 🎉"
echo ""
echo "🌐 Access MCSManager at:"
echo "   Local: http://localhost:23333"
echo "   External: http://$SERVER_IP:23333"
echo ""
echo "🎮 Default login credentials:"
echo "   Username: admin"
echo "   Password: admin"
echo ""
echo "⚠️  IMPORTANT: Change the default password after first login!"
echo ""
echo "📋 Next steps:"
echo "   1. Open http://$SERVER_IP:23333 in your browser"
echo "   2. Login with admin/admin"
echo "   3. Change the admin password"
echo "   4. Create your first Minecraft server"
echo "   5. Upload your custom world (de_dust2) through the web interface"
echo ""
echo "🔧 Management commands:"
echo "   Start: docker-compose up -d"
echo "   Stop: docker-compose down"
echo "   Logs: docker-compose logs -f"
echo "   Restart: docker-compose restart"
echo ""
print_status "Setup completed successfully!"
