#!/bin/bash

# Backup script for Minecraft servers managed by Crafty Controller
# This script creates automated backups of your Minecraft worlds

set -e

# Configuration
BACKUP_DIR="./backups"
RETENTION_DAYS=7
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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
mkdir -p "$BACKUP_DIR"

print_status "Starting backup process..."

# Check if MineOS is running
if ! docker ps | grep -q mineos; then
    print_error "MineOS is not running. Please start it first with: docker compose up -d"
    exit 1
fi

# Create backup of all server data
print_status "Creating backup: minecraft_backup_$TIMESTAMP.tar.gz"
docker exec mineos tar -czf /tmp/minecraft_backup_$TIMESTAMP.tar.gz -C /var/games/minecraft .
docker cp mineos:/tmp/minecraft_backup_$TIMESTAMP.tar.gz "$BACKUP_DIR/"
docker exec mineos rm /tmp/minecraft_backup_$TIMESTAMP.tar.gz

# Get backup size
BACKUP_SIZE=$(du -h "$BACKUP_DIR/minecraft_backup_$TIMESTAMP.tar.gz" | cut -f1)
print_status "Backup created successfully! Size: $BACKUP_SIZE"

# Clean up old backups
print_status "Cleaning up backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -name "minecraft_backup_*.tar.gz" -type f -mtime +$RETENTION_DAYS -delete

# List current backups
BACKUP_COUNT=$(find "$BACKUP_DIR" -name "minecraft_backup_*.tar.gz" -type f | wc -l)
print_status "Total backups: $BACKUP_COUNT"

print_status "Backup process completed!"
