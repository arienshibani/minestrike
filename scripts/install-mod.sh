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
MODS_DIR="/Users/ari/repos/minestrike/server/mods"

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
