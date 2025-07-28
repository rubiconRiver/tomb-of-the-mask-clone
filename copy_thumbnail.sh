#!/bin/bash

# Create a basic thumbnail for level 001
# This simulates what the level editor would generate

echo "Creating thumbnail for level 001..."

# Get the user data directory for Godot
USER_DIR="$HOME/Library/Application Support/Godot/app_userdata/2dgametest"

# Create the directory if it doesn't exist
mkdir -p "$USER_DIR"

# For now, we'll create a placeholder file that indicates a thumbnail should be generated
# The actual thumbnail will be created when the level is opened in the level editor

echo "Level 001 thumbnail placeholder" > "$USER_DIR/001_thumbnail.txt"

echo "Placeholder created at: $USER_DIR/001_thumbnail.txt"
echo "To generate the actual thumbnail:"
echo "1. Open the level editor"
echo "2. Load levels/001.json" 
echo "3. Use Save As to save it as '001' in Main Levels"
echo "4. This will generate the thumbnail automatically"