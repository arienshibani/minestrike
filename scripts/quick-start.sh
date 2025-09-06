#!/bin/bash

# Quick Start Script for MineStrike Server
# This script provides an interactive menu for common tasks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_DIR="/opt/minecraft"

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

# Show menu
show_menu() {
    clear
    print_header "MineStrike Server Management"
    echo ""
    echo "1. Setup server (first time)"
    echo "2. Start server"
    echo "3. Stop server"
    echo "4. Restart server"
    echo "5. Check server status"
    echo "6. View server logs"
    echo "7. Test port accessibility"
    echo "8. Install mod"
    echo "9. Install custom map"
    echo "10. Manage maps"
    echo "11. Attach to server console"
    echo "12. Show server info"
    echo "0. Exit"
    echo ""
}

# Setup server
setup_server() {
    print_header "Setting Up Server"
    if [ -f "$PROJECT_DIR/server/server.jar" ]; then
        print_warning "Server appears to already be set up!"
        read -p "Do you want to re-run setup? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi

    print_status "Running setup script..."
    "$PROJECT_DIR/scripts/setup.sh"
    print_status "Setup complete!"
    read -p "Press Enter to continue..."
}

# Start server
start_server() {
    print_header "Starting Server"
    "$PROJECT_DIR/scripts/server.sh" start
    read -p "Press Enter to continue..."
}

# Stop server
stop_server() {
    print_header "Stopping Server"
    "$PROJECT_DIR/scripts/server.sh" stop
    read -p "Press Enter to continue..."
}

# Restart server
restart_server() {
    print_header "Restarting Server"
    "$PROJECT_DIR/scripts/server.sh" restart
    read -p "Press Enter to continue..."
}

# Check status
check_status() {
    print_header "Server Status"
    "$PROJECT_DIR/scripts/server.sh" status
    read -p "Press Enter to continue..."
}

# View logs
view_logs() {
    print_header "Server Logs"
    "$PROJECT_DIR/scripts/server.sh" logs
    read -p "Press Enter to continue..."
}

# Test port
test_port() {
    print_header "Testing Port Accessibility"
    "$PROJECT_DIR/scripts/test-port.sh"
    read -p "Press Enter to continue..."
}

# Install mod
install_mod() {
    print_header "Install Mod"
    echo "Enter mod URL or file path:"
    read -p "> " mod_path
    
    if [ -n "$mod_path" ]; then
        "$PROJECT_DIR/scripts/install-mod.sh" "$mod_path"
    else
        print_error "No mod path provided"
    fi
    
    read -p "Press Enter to continue..."
}

# Install custom map
install_custom_map() {
    print_header "Install Custom Map"
    echo "Enter the path to your map zip file:"
    read -p "> " map_path
    
    if [ -n "$map_path" ]; then
        "$PROJECT_DIR/scripts/install-map.sh" "$map_path"
    else
        print_error "No map path provided"
    fi
    
    read -p "Press Enter to continue..."
}

# Manage maps
manage_maps() {
    print_header "Map Management"
    echo "1. List maps and backups"
    echo "2. Create backup of current world"
    echo "3. Restore world from backup"
    echo "4. Show world information"
    echo "0. Back to main menu"
    echo ""
    read -p "Select option: " choice
    
    case $choice in
        1)
            "$PROJECT_DIR/scripts/manage-maps.sh" list
            ;;
        2)
            "$PROJECT_DIR/scripts/manage-maps.sh" backup
            ;;
        3)
            "$PROJECT_DIR/scripts/manage-maps.sh" restore
            ;;
        4)
            "$PROJECT_DIR/scripts/manage-maps.sh" info
            ;;
        0)
            return
            ;;
        *)
            print_error "Invalid option"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

# Attach to console
attach_console() {
    print_header "Attaching to Server Console"
    print_status "Use 'Ctrl+A, D' to detach from console"
    print_status "Press Enter to attach..."
    read
    
    if screen -list | grep -q "minecraft-server"; then
        screen -r minecraft-server
    else
        print_error "Server is not running!"
        read -p "Press Enter to continue..."
    fi
}

# Show server info
show_info() {
    print_header "Server Information"
    
    echo "Project Directory: $PROJECT_DIR"
    echo "Server Directory: $PROJECT_DIR/server"
    echo "Logs Directory: $PROJECT_DIR/logs"
    echo "Scripts Directory: $PROJECT_DIR/scripts"
    echo ""
    
    if [ -f "$PROJECT_DIR/server/server.jar" ]; then
        echo "✅ Server jar: Found"
    else
        echo "❌ Server jar: Not found"
    fi
    
    if [ -f "$PROJECT_DIR/server/server.properties" ]; then
        echo "✅ Server config: Found"
    else
        echo "❌ Server config: Not found"
    fi
    
    if [ -f "$PROJECT_DIR/server/eula.txt" ]; then
        echo "✅ EULA: Accepted"
    else
        echo "❌ EULA: Not accepted"
    fi
    
    echo ""
    echo "External IP: $(curl -s ifconfig.me 2>/dev/null || echo 'Unable to determine')"
    echo "Local IP: $(ifconfig | grep 'inet ' | grep -v '127.0.0.1' | head -1 | awk '{print $2}' || echo 'Unable to determine')"
    
    read -p "Press Enter to continue..."
}

# Main menu loop
main() {
    while true; do
        show_menu
        read -p "Select an option: " choice
        
        case $choice in
            1)
                setup_server
                ;;
            2)
                start_server
                ;;
            3)
                stop_server
                ;;
            4)
                restart_server
                ;;
            5)
                check_status
                ;;
            6)
                view_logs
                ;;
            7)
                test_port
                ;;
            8)
                install_mod
                ;;
            9)
                install_custom_map
                ;;
            10)
                manage_maps
                ;;
            11)
                attach_console
                ;;
            12)
                show_info
                ;;
            0)
                print_status "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please try again."
                sleep 2
                ;;
        esac
    done
}

# Run main function
main "$@"
