#!/bin/bash

# Map Management Script for MineStrike
# Usage: ./manage-maps.sh {list|backup|restore|info}

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MAPS_DIR="/Users/ari/repos/minestrike/maps/custom"
SERVER_DIR="/Users/ari/repos/minestrike/server"
BACKUP_DIR="/Users/ari/repos/minestrike/maps/backups"

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

# List available maps
list_maps() {
    print_header "Available Maps"
    
    echo "Custom Maps:"
    if [ -d "$MAPS_DIR" ] && [ "$(ls -A "$MAPS_DIR" 2>/dev/null)" ]; then
        for map in "$MAPS_DIR"/*; do
            if [ -d "$map" ]; then
                local map_name=$(basename "$map")
                local map_size=$(du -sh "$map" | cut -f1)
                echo "  📁 $map_name ($map_size)"
            fi
        done
    else
        echo "  No custom maps found"
    fi
    
    echo ""
    echo "Current Active Map:"
    if [ -d "$SERVER_DIR/world" ]; then
        local current_size=$(du -sh "$SERVER_DIR/world" | cut -f1)
        echo "  🎮 world ($current_size)"
    else
        echo "  No active world"
    fi
    
    echo ""
    echo "Backups:"
    if [ -d "$BACKUP_DIR" ] && [ "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        for backup in "$BACKUP_DIR"/*; do
            if [ -d "$backup" ]; then
                local backup_name=$(basename "$backup")
                local backup_size=$(du -sh "$backup" | cut -f1)
                local backup_date=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$backup" 2>/dev/null || stat -c "%y" "$backup" 2>/dev/null | cut -d' ' -f1-2)
                echo "  💾 $backup_name ($backup_size) - $backup_date"
            fi
        done
    else
        echo "  No backups found"
    fi
}

# Create backup of current world
backup_world() {
    print_header "Creating World Backup"
    
    if [ ! -d "$SERVER_DIR/world" ]; then
        print_error "No active world to backup"
        exit 1
    fi
    
    mkdir -p "$BACKUP_DIR"
    local backup_name="world_backup_$(date +%Y%m%d_%H%M%S)"
    
    print_status "Creating backup: $backup_name"
    cp -r "$SERVER_DIR/world" "$BACKUP_DIR/$backup_name"
    
    local backup_size=$(du -sh "$BACKUP_DIR/$backup_name" | cut -f1)
    print_status "Backup created: $backup_name ($backup_size)"
}

# Restore world from backup
restore_world() {
    print_header "Restore World from Backup"
    
    if [ ! -d "$BACKUP_DIR" ] || [ ! "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        print_error "No backups available"
        exit 1
    fi
    
    echo "Available backups:"
    local i=1
    local backups=()
    for backup in "$BACKUP_DIR"/*; do
        if [ -d "$backup" ]; then
            local backup_name=$(basename "$backup")
            local backup_size=$(du -sh "$backup" | cut -f1)
            local backup_date=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$backup" 2>/dev/null || stat -c "%y" "$backup" 2>/dev/null | cut -d' ' -f1-2)
            echo "  $i) $backup_name ($backup_size) - $backup_date"
            backups+=("$backup")
            ((i++))
        fi
    done
    
    echo ""
    read -p "Select backup to restore (number): " selection
    
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -ge "$i" ]; then
        print_error "Invalid selection"
        exit 1
    fi
    
    local selected_backup="${backups[$((selection-1))]}"
    local backup_name=$(basename "$selected_backup")
    
    print_warning "This will replace the current world with: $backup_name"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Restore cancelled"
        exit 0
    fi
    
    # Stop server if running
    if ./scripts/server.sh status | grep -q "running"; then
        print_status "Stopping server..."
        ./scripts/server.sh stop
    fi
    
    # Remove current world
    rm -rf "$SERVER_DIR/world"
    
    # Restore backup
    cp -r "$selected_backup" "$SERVER_DIR/world"
    
    print_status "World restored: $backup_name"
    print_status "You can now start the server: ./scripts/server.sh start"
}

# Show map information
show_info() {
    print_header "Map Information"
    
    if [ -d "$SERVER_DIR/world" ]; then
        echo "Current Active World:"
        echo "  Path: $SERVER_DIR/world"
        echo "  Size: $(du -sh "$SERVER_DIR/world" | cut -f1)"
        echo "  Files: $(find "$SERVER_DIR/world" -type f | wc -l)"
        
        # Check for level.dat
        if [ -f "$SERVER_DIR/world/level.dat" ]; then
            echo "  ✅ Level data present"
        else
            echo "  ⚠️  Level data missing"
        fi
        
        # Check for region files
        if [ -d "$SERVER_DIR/world/region" ]; then
            local region_count=$(find "$SERVER_DIR/world/region" -name "*.mca" | wc -l)
            echo "  ✅ Region files: $region_count"
        else
            echo "  ⚠️  No region files found"
        fi
        
        # Check for player data
        if [ -d "$SERVER_DIR/world/playerdata" ]; then
            local player_count=$(find "$SERVER_DIR/world/playerdata" -name "*.dat" | wc -l)
            echo "  👥 Player data files: $player_count"
        fi
        
        # Check for structures
        if [ -d "$SERVER_DIR/world/generated" ]; then
            echo "  🏗️  Generated structures present"
        fi
        
    else
        echo "No active world found"
    fi
}

# Main function
main() {
    case "${1:-list}" in
        list)
            list_maps
            ;;
        backup)
            backup_world
            ;;
        restore)
            restore_world
            ;;
        info)
            show_info
            ;;
        *)
            echo "Usage: $0 {list|backup|restore|info}"
            echo ""
            echo "Commands:"
            echo "  list    - List available maps and backups"
            echo "  backup  - Create backup of current world"
            echo "  restore - Restore world from backup"
            echo "  info    - Show information about current world"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
