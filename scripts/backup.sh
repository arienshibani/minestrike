#!/bin/bash

# Backup Script for MineStrike Server
# This script creates automated backups of the server

set -e

# Configuration
BACKUP_DIR="/opt/backups"
SERVER_DIR="/opt/minecraft/server"
RETENTION_DAYS=7
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

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

# Create backup directory if it doesn't exist
create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        sudo mkdir -p "$BACKUP_DIR"
        sudo chown minecraft:minecraft "$BACKUP_DIR"
        print_status "Created backup directory: $BACKUP_DIR"
    fi
}

# Create server backup
create_backup() {
    print_status "Creating server backup..."
    
    BACKUP_FILE="$BACKUP_DIR/server-backup-$TIMESTAMP.tar.gz"
    
    # Create backup
    sudo tar -czf "$BACKUP_FILE" \
        --exclude="$SERVER_DIR/logs" \
        --exclude="$SERVER_DIR/cache" \
        --exclude="$SERVER_DIR/libraries" \
        --exclude="$SERVER_DIR/versions" \
        -C /opt/minecraft server/
    
    # Set ownership
    sudo chown minecraft:minecraft "$BACKUP_FILE"
    
    print_status "Backup created: $BACKUP_FILE"
    
    # Show backup size
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    print_status "Backup size: $BACKUP_SIZE"
}

# Clean old backups
cleanup_old_backups() {
    print_status "Cleaning up old backups (older than $RETENTION_DAYS days)..."
    
    find "$BACKUP_DIR" -name "server-backup-*.tar.gz" -type f -mtime +$RETENTION_DAYS -delete
    
    print_status "Old backups cleaned up"
}

# List current backups
list_backups() {
    print_status "Current backups:"
    ls -lh "$BACKUP_DIR"/server-backup-*.tar.gz 2>/dev/null || print_warning "No backups found"
}

# Main function
main() {
    case "${1:-backup}" in
        backup)
            create_backup_dir
            create_backup
            cleanup_old_backups
            list_backups
            ;;
        list)
            list_backups
            ;;
        cleanup)
            cleanup_old_backups
            ;;
        *)
            echo "Usage: $0 {backup|list|cleanup}"
            echo ""
            echo "Commands:"
            echo "  backup  - Create a new backup (default)"
            echo "  list    - List existing backups"
            echo "  cleanup - Clean up old backups"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
