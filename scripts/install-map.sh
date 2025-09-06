#!/bin/bash

# Custom Map Installation Script for MineStrike
# Usage: ./install-map.sh <map_zip_file> [map_name]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MAPS_DIR="/opt/minecraft/maps/custom"
SERVER_DIR="/opt/minecraft/server"
BACKUP_DIR="/opt/backups"

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

# Check if input is zip file or directory
check_input() {
    if [ -f "$1" ]; then
        if file "$1" | grep -q "Zip archive"; then
            print_status "Zip file detected: $1"
            return 0  # zip file
        else
            print_error "File is not a valid zip archive: $1"
            exit 1
        fi
    elif [ -d "$1" ]; then
        print_status "Directory detected: $1"
        return 1  # directory
    else
        print_error "Input not found: $1"
        exit 1
    fi
}

# Extract and analyze map structure
extract_map() {
    local input_path="$1"
    local map_name="$2"
    local temp_dir="/tmp/map_extract_$$"
    
    print_status "Processing map: $map_name"
    
    # Create temporary directory
    mkdir -p "$temp_dir"
    
    # Check if input is zip file or directory
    if check_input "$input_path"; then
        # It's a zip file
        print_status "Extracting zip file..."
        unzip -q "$input_path" -d "$temp_dir"
    else
        # It's a directory
        print_status "Copying directory..."
        cp -r "$input_path" "$temp_dir/"
    fi
    
    # Find the world directory
    local world_dir=""
    if [ -d "$temp_dir/world" ]; then
        world_dir="$temp_dir/world"
    elif [ -d "$temp_dir" ] && [ $(ls -1 "$temp_dir" | wc -l) -eq 1 ] && [ -d "$temp_dir"/* ]; then
        # Single directory in zip
        local single_dir=$(ls -1 "$temp_dir" | head -1)
        if [ -d "$temp_dir/$single_dir" ]; then
            world_dir="$temp_dir/$single_dir"
        fi
    elif [ -d "$temp_dir" ] && [ $(ls -1 "$temp_dir" | wc -l) -gt 1 ]; then
        # Multiple items, use the temp_dir itself
        world_dir="$temp_dir"
    fi
    
    if [ -z "$world_dir" ]; then
        print_error "Could not find world directory"
        print_status "Contents:"
        find "$temp_dir" -type d -maxdepth 2 | head -10
        rm -rf "$temp_dir"
        exit 1
    fi
    
    print_status "Found world directory: $world_dir"
    
    # Copy to maps directory
    local map_path="$MAPS_DIR/$map_name"
    cp -r "$world_dir" "$map_path"
    
    # Clean up
    rm -rf "$temp_dir"
    
    print_status "Map processed to: $map_path"
}

# Backup current world
backup_current_world() {
    if [ -d "$SERVER_DIR/world" ]; then
        print_status "Backing up current world..."
        
        mkdir -p "$BACKUP_DIR"
        local backup_name="world_backup_$(date +%Y%m%d_%H%M%S)"
        
        cp -r "$SERVER_DIR/world" "$BACKUP_DIR/$backup_name"
        print_status "Current world backed up to: $BACKUP_DIR/$backup_name"
    fi
}

# Install map as active world
install_map() {
    local map_name="$1"
    local map_path="$MAPS_DIR/$map_name"
    
    print_status "Installing map as active world: $map_name"
    
    # Remove current world if it exists
    if [ -d "$SERVER_DIR/world" ]; then
        rm -rf "$SERVER_DIR/world"
    fi
    
    # Copy map to server directory
    cp -r "$map_path" "$SERVER_DIR/world"
    
    print_status "Map installed successfully!"
}

# Update server properties for the map
update_server_properties() {
    local map_name="$1"
    
    print_status "Updating server properties..."
    
    # Update level-name in server.properties
    sed -i.bak "s/level-name=.*/level-name=$map_name/" "$SERVER_DIR/server.properties"
    
    print_status "Server properties updated"
}

# Show map information
show_map_info() {
    local map_name="$1"
    local map_path="$MAPS_DIR/$map_name"
    
    print_header "Map Information"
    
    echo "Map Name: $map_name"
    echo "Map Path: $map_path"
    echo "Server Path: $SERVER_DIR/world"
    
    if [ -d "$map_path" ]; then
        echo "Map Size: $(du -sh "$map_path" | cut -f1)"
        echo "Files: $(find "$map_path" -type f | wc -l)"
        
        # Check for common map files
        if [ -f "$map_path/level.dat" ]; then
            echo "✅ Level data found"
        else
            echo "⚠️  Level data not found"
        fi
        
        if [ -d "$map_path/region" ]; then
            echo "✅ Region files found"
        else
            echo "⚠️  Region files not found"
        fi
    fi
}

# Main function
main() {
    if [ $# -lt 1 ]; then
        echo "Usage: $0 <map_zip_file_or_folder> [map_name]"
        echo ""
        echo "Examples:"
        echo "  $0 de_dust2.zip de_dust2"
        echo "  $0 maps/de_dust2 de_dust2"
        echo "  $0 custom_map.zip my_custom_map"
        echo ""
        echo "You can provide either a zip file or an extracted folder."
        echo "If map_name is not provided, it will be derived from the input name."
        exit 1
    fi
    
    local input_path="$1"
    local map_name="${2:-$(basename "$input_path" .zip)}"
    
    # Clean map name (remove spaces, special chars)
    map_name=$(echo "$map_name" | sed 's/[^a-zA-Z0-9_-]/_/g')
    
    print_header "Installing Custom Map: $map_name"
    
    # Check input type and proceed accordingly
    if check_input "$input_path"; then
        # It's a zip file
        extract_map "$input_path" "$map_name"
    else
        # It's a directory
        extract_map "$input_path" "$map_name"
    fi
    backup_current_world
    install_map "$map_name"
    update_server_properties "$map_name"
    show_map_info "$map_name"
    
    print_header "Installation Complete!"
    
    echo ""
    print_status "Next steps:"
    echo "1. Restart the server: ./scripts/server.sh restart"
    echo "2. Connect to test the new map"
    echo "3. The map is now saved in your repository and will deploy to EC2"
    echo ""
    print_warning "Remember to commit your changes:"
    echo "git add maps/ server/world/"
    echo "git commit -m 'Add custom map: $map_name'"
    echo "git push"
}

# Run main function
main "$@"
