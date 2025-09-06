#!/bin/bash

# Elytra Auto-Give Script
# This script ensures all players get an elytra when they join

echo "🎮 Setting up automatic elytra distribution..."

# Create the datapack directory structure
mkdir -p /opt/minecraft/server/world/datapacks/elytra_giver/data/elytra_giver/functions

# Copy datapack files (if they exist)
if [ -f "/opt/minecraft/server/world/datapacks/elytra_giver/pack.mcmeta" ]; then
    echo "✅ Elytra datapack found, enabling..."
    
    # Enable the datapack
    echo "datapack enable \"file/elytra_giver\"" | sudo -u minecraft tee -a /opt/minecraft/server/console_input.txt
    
    # Give elytra to all current players
    echo "give @a elytra 1" | sudo -u minecraft tee -a /opt/minecraft/server/console_input.txt
    echo "give @a firework_rocket 64" | sudo -u minecraft tee -a /opt/minecraft/server/console_input.txt
    
    echo "✅ Elytra auto-give setup complete!"
else
    echo "⚠️ Elytra datapack not found, skipping..."
fi
